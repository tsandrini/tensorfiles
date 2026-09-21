#!/usr/bin/env bash

# retrowine -- disc imaging + per-game Wine prefixes for 2000s-era Windows games
#
# Per-disc flow: new -> dump -> install -> (set EXE) -> run -> mark
#
# The backup is image + recipe, under $RETROWINE_ROOT (the backup drive):
#
#   <slug>/game.conf   launcher config, sourced as bash
#   <slug>/media/      disc images + ddrescue maps + checksums
#
# Everything regenerable stays local, under $RETROWINE_STATE, so that testing
# a game only ever reads from the backup drive:
#
#   <slug>/prefix/     win32 WINEPREFIX, sandboxed from $HOME
#   <slug>/logs/       wine output of every install/run

set -euo pipefail

readonly ROOT="${RETROWINE_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/retrowine}"
readonly STATE="${RETROWINE_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/retrowine}"

# Prints the first physical optical drive. NOTE: cdemu's virtual drives are
# /dev/srN too and take sr0 whenever the daemon is up before the drive is plugged.
detect_drive() {
	local dev
	for dev in /dev/sr[0-9]*; do
		if [[ -b $dev && $(udevadm info -q property -n "$dev") != *ID_VENDOR=CDEmu* ]]; then
			echo "$dev"
			return 0
		fi
	done
	echo /dev/sr0
}

DEVICE="${RETROWINE_DEVICE:-$(detect_drive)}"
readonly DEVICE
readonly STATUSES="untested works partial broken"
# Image descriptors a game's media/ may hold; everything but iso needs cdemu
readonly -a IMAGE_EXTS=(iso cue mds ccd nrg toc)

# Set by need_game
SLUG="" GAME_DIR=""
# Set by attach_image / attach_physical
DISC_DEV="" DISC_MNT=""

die() {
	echo "retrowine: $*" >&2
	exit 1
}

info() {
	echo ":: $*" >&2
}

usage() {
	cat <<-EOF
		Usage: retrowine <command> [args]

		  new <slug> [title]            scaffold a game directory
		  dump <slug> [name]            image the disc in $DEVICE into media/<name>.iso; resumable
		  dump <slug> [name] --finalize accept an incomplete image as-is (checksum + info, no reading)
		  install <slug> [opts] [exe [args]]  run the disc's installer (default: setup.exe / autorun);
		                                args go to the installer, e.g. /VERYSILENT /SP- /LANG=cz
		  exes <slug>                   list shortcuts + executables the installer left behind
		  shortcuts <slug>              numbered Start Menu shortcuts, for run --shortcut
		  run <slug> [opts] [-- args]   launch EXE from game.conf
		  disc <slug> [opts] [image]    (re)map D:, e.g. for "insert disc 2" prompts
		  exec <slug> <cmd...>          run a command inside the game's Wine env (winecfg, winetricks, ...)
		  mark <slug> <status> [notes]  record the verdict: ${STATUSES// / | }
		  kill <slug>                   kill everything running in the prefix
		  umount <slug>                 unmount + detach the game's images
		  reset <slug>                  delete the prefix + logs (keeps images and game.conf)
		  rm <slug> [--force]           delete the game entirely; --force if it has images
		  list                          overview of all games
		  info <slug>                   everything about one game, incl. the notes

		install/run/disc opts:
		  --disc         map D: to the physical disc instead of the dumped image
		  --attach <a>   auto | loop | cdemu (overrides ATTACH from game.conf)
		  --exe <path>   run: start this Windows path instead of EXE (compilations)
		  --shortcut <s> run: start a Start Menu shortcut, by number or part of its
		                 name (see: retrowine shortcuts <slug>)
		  --res <WxH>    override RES from game.conf
		  --file <path>  install: run a loose installer from the host instead of a
		                 disc (downloaded editions); extra args go to the installer
		  --mode <m>     gamescope | desktop | native | headless (run: overrides MODE;
		                 install: defaults to desktop)

		Environment:
		  RETROWINE_ROOT    images + game configs, i.e. the backup drive (current: $ROOT)
		  RETROWINE_STATE   prefixes + logs, local and regenerable (current: $STATE)
		  RETROWINE_DEVICE  optical drive (current: $DEVICE)
	EOF
}

# Creates the default root on first use. An explicitly set root that is
# missing is an unmounted drive, not a fresh setup -- dies instead.
ensure_root() {
	[[ -d $ROOT ]] && return 0
	[[ -z ${RETROWINE_ROOT:-} ]] || die "RETROWINE_ROOT=$ROOT does not exist -- is the drive mounted?"
	mkdir -p "$ROOT"
}

# Resolves <slug> into SLUG/GAME_DIR and loads its config over the defaults.
# Dies on an invalid or unknown slug.
need_game() {
	[[ ${1:-} =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "invalid or missing slug: '${1:-}'"
	SLUG=$1
	GAME_DIR="$ROOT/$SLUG"
	[[ -f $GAME_DIR/game.conf ]] || die "unknown game '$SLUG' (create it with: retrowine new $SLUG)"
	load_conf
}

load_conf() {
	TITLE="" EXE="" ARGS="" IMAGE="" WINVER="winxp" RES="1024x768" MODE="gamescope"
	FULLSCREEN="0" GAMESCOPE_ARGS="" AFFINITY="" TRICKS="" STATUS="untested" NOTES=""
	ATTACH="auto" LOCALE="" AUDIO_DRIVER=""
	# shellcheck source=/dev/null
	source "$GAME_DIR/game.conf"
}

# SIGKILLs everything started from this prefix. A dead compositor leaves
# winedevice.exe spinning without a wineserver, out of `wineserver -k`'s reach.
kill_prefix() {
	local p
	wineserver -k 2>/dev/null || true
	for p in /proc/[0-9]*; do
		if [[ ${p#/proc/} != "$$" ]] && grep -qzsxF "WINEPREFIX=$WINEPREFIX" "$p/environ"; then
			kill -9 "${p#/proc/}" 2>/dev/null || true
		fi
	done
}

wine_env() {
	export WINEPREFIX="$STATE/$SLUG/prefix" WINEARCH=win32
	export WINEDEBUG="${WINEDEBUG:-fixme-all}"
	# NOTE: wine derives the ANSI codepage from the unix locale
	if [[ -n $LOCALE ]]; then
		export LC_ALL="$LOCALE"
	fi
	# NOTE: keeps installers from writing .desktop/mime entries into $HOME
	export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winemenubuilder.exe=d"
}

# Creates the prefix on first use: win32, $WINVER personality, user dirs
# detached from $HOME, D: typed as CD-ROM, $TRICKS applied.
ensure_prefix() {
	wine_env
	if [[ -f $WINEPREFIX/system.reg ]]; then
		apply_audio_driver
		return 0
	fi

	info "creating win32 prefix ($WINVER)"
	# NOTE: D: must exist before the first boot, else mountmgr hands it to the
	# first removable volume it sees. With dosdevices/ present wine skips its
	# own c:/z: setup, hence those too.
	mkdir -p "$WINEPREFIX/dosdevices" "$WINEPREFIX/drive_c"
	ln -sfn ../drive_c "$WINEPREFIX/dosdevices/c:"
	ln -sfn / "$WINEPREFIX/dosdevices/z:"
	ln -sfn "$GAME_DIR/media" "$WINEPREFIX/dosdevices/d:"
	# NOTE: mscoree/mshtml only disabled here, to skip the mono/gecko download prompts
	WINEDLLOVERRIDES="$WINEDLLOVERRIDES;mscoree=;mshtml=" WINEDEBUG=-all wineboot -i
	wineserver -w
	WINEDEBUG=-all wine winecfg -v "$WINVER"
	WINEDEBUG=-all wine reg add 'HKLM\Software\Wine\Drives' /v 'd:' /d cdrom /f >/dev/null

	# Wine symlinks Documents & co. into $HOME; saves must stay inside the prefix
	# NOTE: nested too -- AppData/.../Templates points at $HOME itself, which
	# lets any recursive C: scan (installer "searching for ...") walk all of it
	local d
	while IFS= read -r -d '' d; do
		rm "$d"
		mkdir "$d"
	done < <(find "$WINEPREFIX/drive_c/users" -type l -lname '/*' -print0)

	if [[ -n $TRICKS ]]; then
		local -a verbs
		read -ra verbs <<<"$TRICKS"
		info "winetricks: ${verbs[*]}"
		winetricks -q "${verbs[@]}"
	fi
	wineserver -w
	apply_audio_driver
}

# Wine reads its audio driver from the registry only. Applied lazily, so that
# changing AUDIO_DRIVER later also reaches an existing prefix.
apply_audio_driver() {
	[[ -n $AUDIO_DRIVER ]] || return 0
	if ! grep -qsF "\"Audio\"=\"$AUDIO_DRIVER\"" "$WINEPREFIX/user.reg"; then
		info "audio driver -> $AUDIO_DRIVER"
		WINEDEBUG=-all wine reg add 'HKCU\Software\Wine\Drivers' /v Audio /d "$AUDIO_DRIVER" /f >/dev/null
		wineserver -w
	fi
}

# Prints the game's disc images (see IMAGE_EXTS), one path per line.
# NOTE: no compgen -G here, writeShellApplication's bash lacks progcomp
list_images() {
	local ext f
	shopt -s nullglob nocaseglob
	for ext in "${IMAGE_EXTS[@]}"; do
		for f in "$GAME_DIR"/media/*."$ext"; do
			echo "$f"
		done
	done
	shopt -u nullglob nocaseglob
}

# Prints the image to use: [explicit arg] > IMAGE from game.conf > the only
# image in media/. Dies when the choice is ambiguous or nothing is there.
resolve_image() {
	local want=${1:-$IMAGE}
	if [[ -n $want ]]; then
		[[ -f $GAME_DIR/media/$want ]] || die "no such image: media/$want"
		echo "$GAME_DIR/media/$want"
		return 0
	fi
	local -a imgs
	mapfile -t imgs < <(list_images)
	case ${#imgs[@]} in
	0) die "no image in media/ yet (retrowine dump $SLUG), or pass --disc" ;;
	1) echo "${imgs[0]}" ;;
	*) die "several images in media/, set IMAGE in game.conf or name one" ;;
	esac
}

# Presents an image to Wine and sets DISC_DEV/DISC_MNT. Backend: --attach >
# ATTACH from game.conf; "auto" loop-mounts plain ISOs and hands everything a
# loop device can't express (multi-track, subchannel) to cdemu.
attach_image() {
	local img=$1 backend=${ATTACH_OVERRIDE:-$ATTACH}
	if [[ $backend == auto ]]; then
		if [[ ${img,,} == *.iso ]]; then
			backend=loop
		else
			backend=cdemu
		fi
	fi
	case $backend in
	loop) attach_loop "$img" ;;
	cdemu) attach_cdemu "$img" ;;
	*) die "unknown attach backend '$backend' (auto | loop | cdemu)" ;;
	esac
}

# Prints the cdemu device number that has <image> loaded, if any.
cdemu_slot_of() {
	cdemu status | awk -v img="$1" '
		NR > 2 { f = $0; sub(/^[0-9]+[ \t]+[A-Za-z]+[ \t]+/, "", f); if (f == img) { print $1; exit } }'
}

# Loads an image into a cdemu virtual drive (a real /dev/srN: TOC, audio
# tracks, raw reads) and sets DISC_DEV/DISC_MNT. Reuses a loaded drive, grows
# the drive pool when all are taken. The daemon is D-Bus activated.
attach_cdemu() {
	local img=$1 slot
	[[ -c /dev/vhba_ctl ]] || die "cdemu needs the vhba kernel module (tensorfiles.programs.retrowine.cdemu)"
	slot=$(cdemu_slot_of "$img")
	if [[ -z $slot ]]; then
		if ! cdemu load any "$img" 2>/dev/null; then
			cdemu add-device >/dev/null
			cdemu load any "$img"
		fi
		slot=$(cdemu_slot_of "$img")
		[[ -n $slot ]] || die "cdemu did not load $img"
	fi
	DISC_DEV=$(cdemu device-mapping | awk -v slot="$slot" 'NR > 2 && $1 == slot { print $2 }')
	[[ -b $DISC_DEV ]] || die "cdemu device $slot has no block device yet"
	wait_for_fs "$DISC_DEV"
	mount_disc_dev
}

# cdemu raises a media-change event which the kernel only notices by polling
# (~2 s) -- `udevadm settle` returns long before. Waits for the filesystem.
wait_for_fs() {
	local dev=$1 i
	for ((i = 0; i < 40; i++)); do
		if [[ -n $(lsblk -no FSTYPE "$dev" 2>/dev/null) ]]; then
			return 0
		fi
		sleep 0.5
	done
	die "no filesystem showed up on $dev within 20 s"
}

# Loop-mounts an image read-only through udisks (no root needed) and sets
# DISC_DEV/DISC_MNT. Reuses an existing loop device / mount.
attach_loop() {
	local img=$1
	DISC_DEV=$(losetup -nO NAME -j "$img" | head -n1)
	if [[ -z $DISC_DEV ]]; then
		DISC_DEV=$(udisksctl loop-setup -r -f "$img" | sed -nE 's|.* as (/dev/loop[0-9]+)\.?$|\1|p')
		[[ -n $DISC_DEV ]] || die "udisks loop-setup failed for $img"
		udevadm settle
	fi
	mount_disc_dev
}

# Uses the physical disc in $DEVICE, mounting it if needed.
attach_physical() {
	DISC_DEV=$DEVICE
	[[ -b $DISC_DEV ]] || die "$DISC_DEV is not a block device"
	mount_disc_dev
}

mount_disc_dev() {
	# NOTE: findmnt exits 1 when the device isn't mounted
	DISC_MNT=$(findmnt -no TARGET -S "$DISC_DEV" | head -n1 || true)
	if [[ -z $DISC_MNT ]]; then
		udisksctl mount -b "$DISC_DEV" >/dev/null
		DISC_MNT=$(findmnt -no TARGET -S "$DISC_DEV" | head -n1 || true)
	fi
	[[ -n $DISC_MNT ]] || die "could not mount $DISC_DEV"
}

# Points D: at DISC_MNT and D:'s raw device at DISC_DEV (volume label/serial).
map_drive() {
	ln -sfn "$DISC_MNT" "$WINEPREFIX/dosdevices/d:"
	ln -sfn "$DISC_DEV" "$WINEPREFIX/dosdevices/d::"
	info "D: -> $DISC_MNT ($DISC_DEV)"
}

# Runs a Windows program through the chosen display mode and waits until the
# whole prefix is idle, logging into logs/. Args: <mode> <log-tag> <exe> [args...]
launch() {
	local mode=$1 tag=$2
	shift 2
	local -a cmd=() extra=()
	local log w h rc=0
	w=${RES%x*} h=${RES#*x}

	case $mode in
	gamescope)
		read -ra extra <<<"$GAMESCOPE_ARGS"
		cmd+=(gamescope -w "$w" -h "$h")
		if [[ $FULLSCREEN == 1 ]]; then
			cmd+=(-f)
		fi
		cmd+=("${extra[@]}" --)
		;;
	headless)
		# NOTE: no window anywhere; the inner Xwayland (:1, :2, ...) can still be
		# screenshotted -- for unattended smoke tests
		cmd+=(gamescope --backend headless -w "$w" -h "$h" --)
		;;
	desktop | native) ;;
	*) die "unknown mode '$mode' (gamescope | desktop | native | headless)" ;;
	esac
	# NOTE: installers hand off to a detached engine and exit early; the session
	# (and with it gamescope) must outlive the first process
	# shellcheck disable=SC2016
	cmd+=(bash -c '"$@"; rc=$?; wineserver -w; exit $rc' retrowine-session)
	if [[ -n $AFFINITY ]]; then
		cmd+=(taskset -c "$AFFINITY")
	fi
	cmd+=(wine)
	if [[ $mode == desktop ]]; then
		cmd+=(explorer "/desktop=$SLUG,$RES")
	fi
	cmd+=("$@")

	mkdir -p "$STATE/$SLUG/logs"
	log="$STATE/$SLUG/logs/$(date +%Y%m%d-%H%M%S)-$tag.log"
	info "mode=$mode res=$RES log=$log"
	"${cmd[@]}" >"$log" 2>&1 || rc=$?
	if [[ $rc -ne 0 ]]; then
		info "session exited with status $rc, see $log"
		if [[ $mode == gamescope && $rc -eq 134 ]]; then
			info "gamescope aborted -- retry with --mode desktop, or set MODE='desktop' in game.conf"
		fi
	fi
	kill_prefix
}

cmd_new() {
	[[ ${1:-} =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "invalid or missing slug: '${1:-}'"
	local dir="$ROOT/$1" title=${2:-$1}
	[[ -e $dir/game.conf ]] && die "'$1' already exists"
	mkdir -p "$dir/media"
	cat >"$dir/game.conf" <<-EOF
		# retrowine game config -- sourced as bash
		TITLE=$(printf %q "$title")
		# Windows path of the game executable; set after install (retrowine exes $1)
		EXE=''
		ARGS=''
		# Image in media/ mapped as D: (default: the only image there)
		IMAGE=''
		# How the image reaches wine: auto | loop | cdemu. auto = loop mount for
		# ISOs, cdemu (virtual /dev/srN) for cue/mds/ccd/nrg/toc. Force cdemu
		# for games whose disc check wants a real drive (TOC, raw reads).
		ATTACH='auto'
		WINVER='winxp'
		# Wine audio driver: '' (wine's default, pulse) | alsa | pulse. Only alsa
		# has MIDI output -- a program that plays MIDI (autorun menus, 90s-style
		# music) hangs without it. Needs a 32-bit ALSA->PipeWire/Pulse bridge.
		AUDIO_DRIVER=''
		# Unix locale wine runs under; it decides the ANSI codepage. Non-unicode
		# Czech games need 'cs_CZ.UTF-8' (CP1250), else "č" shows up as "è".
		LOCALE=''
		# Resolution of the virtual monitor the game sees
		RES='1024x768'
		# How "retrowine run" displays the game (installers always use desktop):
		#   gamescope  nested compositor, scales RES up to its window with correct aspect
		#   desktop    unscaled wine virtual desktop of size RES; the robust fallback
		#   native     plain windows on the host
		MODE='gamescope'
		# 1 = start gamescope fullscreen (-f); 0 = leave it to the compositor's bind
		FULLSCREEN='0'
		GAMESCOPE_ARGS=''
		# CPU list for taskset, e.g. '0' for games that break on multi-core CPUs
		AFFINITY=''
		# winetricks verbs applied when the prefix is created, e.g. 'd3dx9 dxvk'
		TRICKS=''
		# ${STATUSES// / | }
		STATUS='untested'
		NOTES=''
	EOF
	info "created $dir"
}

cmd_dump() {
	need_game "${1:-}"
	shift
	local -A p=()
	local k v name="" img map finalize=0 a
	for a in "$@"; do
		if [[ $a == --finalize ]]; then
			finalize=1
		else
			name=$a
		fi
	done
	while IFS='=' read -r k v; do
		p[$k]=$v
	done < <(udevadm info -q property -n "$DEVICE")

	[[ ${p[ID_CDROM_MEDIA]:-} == 1 ]] || die "no disc in $DEVICE"
	# TODO: bin/cue path (redumper) for mixed-mode + copy-protected CDs
	if [[ ${p[ID_CDROM_MEDIA_TRACK_COUNT_AUDIO]:-0} -gt 0 ]]; then
		die "disc has ${p[ID_CDROM_MEDIA_TRACK_COUNT_AUDIO]} audio track(s); an ISO would silently drop them"
	fi

	name=${name:-${p[ID_FS_LABEL]:-disc}}
	img="$GAME_DIR/media/$name.iso"
	map="$img.map"
	if [[ -e $img && ! -e $map ]]; then
		die "media/$name.iso exists without a ddrescue map, refusing to touch it"
	fi

	if [[ $finalize == 1 ]]; then
		[[ -e $map ]] || die "nothing to finalize: no media/$name.iso.map"
		info "finalizing media/$name.iso as-is, no reading"
	elif [[ -e $map ]] && ddrescuelog -D "$map"; then
		info "media/$name.iso is already complete"
	else
		info "imaging $DEVICE (${p[ID_FS_LABEL]:-unlabeled}) -> media/$name.iso"
		# Two passes per the ddrescue manual: fast sweep, then direct-access retries.
		# NOTE: -K bounds the skip; the default grows to 1% of the disc, which jumps
		# clean over a marginal zone and makes it look dead
		ddrescue -n -b 2048 -K 65536,1048576 "$DEVICE" "$img" "$map"
		if ! ddrescuelog -D "$map"; then
			info "unreadable areas left, retrying with direct access"
			ddrescue -d -r 1 -b 2048 -K 65536,1048576 "$DEVICE" "$img" "$map"
		fi
	fi

	(cd "$GAME_DIR/media" && sha256sum "$name.iso" >"$name.iso.sha256")
	{
		echo "dumped=$(date -Iseconds)"
		echo "drive=${p[ID_MODEL]:-unknown}"
		echo "label=${p[ID_FS_LABEL]:-}"
		echo "media=$([[ ${p[ID_CDROM_MEDIA_DVD]:-} == 1 ]] && echo dvd || echo cd)"
		echo "bytes=$(stat -c %s "$img")"
		echo "unrecovered_sectors=$(ddrescuelog -b 2048 -l '?*/-' "$map" | wc -l)"
	} >"$img.info"
	cat "$img.info" >&2

	if ddrescuelog -D "$map"; then
		info "clean read, every sector recovered"
	else
		# NOTE: CDs written track-at-once end in 2 unreadable run-out sectors; harmless
		info "INCOMPLETE: re-run to retry (ddrescue resumes; another drive can fill the gaps)"
		info "if the gaps turn out not to matter, note why in game.conf and keep the image"
		[[ $finalize == 1 ]] || return 1
	fi
}

# Parses the shared install/run options into USE_DISC / MODE_OVERRIDE /
# ATTACH_OVERRIDE / EXE_OVERRIDE / SHORTCUT / RES_OVERRIDE / FILE; leaves the
# remaining args in REST.
parse_launch_opts() {
	USE_DISC=0 MODE_OVERRIDE="" ATTACH_OVERRIDE="" EXE_OVERRIDE="" SHORTCUT="" RES_OVERRIDE="" FILE="" REST=()
	while [[ $# -gt 0 ]]; do
		case $1 in
		--disc) USE_DISC=1 ;;
		--mode)
			MODE_OVERRIDE=${2:-}
			shift
			;;
		--attach)
			ATTACH_OVERRIDE=${2:-}
			shift
			;;
		--exe)
			EXE_OVERRIDE=${2:-}
			shift
			;;
		--shortcut)
			SHORTCUT=${2:-}
			shift
			;;
		--res)
			RES_OVERRIDE=${2:-}
			shift
			;;
		--file)
			FILE=${2:-}
			shift
			;;
		--)
			shift
			REST+=("$@")
			break
			;;
		*) REST+=("$1") ;;
		esac
		shift
	done
}

cmd_install() {
	need_game "${1:-}"
	shift
	parse_launch_opts "$@"
	ensure_prefix

	if [[ -n $FILE ]]; then
		local file
		file=$(realpath -e -- "$FILE") || die "no such installer: $FILE"
		info "installer: $file"
		cd "$(dirname "$file")"
		launch "${MODE_OVERRIDE:-desktop}" install "$file" "${REST[@]}"
		info "done -- find the game exe with: retrowine exes $SLUG"
		return 0
	fi

	if [[ $USE_DISC == 1 ]]; then
		attach_physical
	else
		attach_image "$(resolve_image)"
	fi
	map_drive

	local exe=${REST[0]:-}
	if [[ -z $exe ]]; then
		exe=$(find "$DISC_MNT" -maxdepth 1 -iname 'setup.exe' -printf '%f\n' -quit)
	fi
	if [[ -z $exe ]]; then
		exe=$(find "$DISC_MNT" -maxdepth 1 -iname 'autorun.inf' -exec cat {} + |
			tr -d '\r' | sed -nE 's/^open\s*=\s*([^ ]+).*/\1/ip' | head -n1)
	fi
	[[ -n $exe ]] || die "no setup.exe / autorun target on the disc, name the installer explicitly"

	info "installer: D:\\$exe"
	cd "$DISC_MNT"
	# NOTE: installers churn cursors, which kills gamescope under niri; they don't need scaling anyway
	launch "${MODE_OVERRIDE:-desktop}" install "D:\\$exe" "${REST[@]:1}"
	info "done -- find the game exe with: retrowine exes $SLUG"
}

cmd_exes() {
	need_game "${1:-}"
	wine_env
	local c="$WINEPREFIX/drive_c"
	[[ -d $c ]] || die "no prefix yet"
	echo "# shortcuts"
	find "$c/users" "$c/ProgramData" -iname '*.lnk' -printf '%P\n' 2>/dev/null | sort
	echo "# executables"
	find "$c" -path "$c/windows" -prune -o -iname '*.exe' -printf 'C:\\%P\n' | tr '/' '\134' | sort
}

# Prints the prefix's Start Menu shortcuts without uninstallers, one unix path
# per line; `shortcuts` and `run --shortcut` number them in this order.
list_shortcuts() {
	local c="$WINEPREFIX/drive_c"
	find "$c/users" "$c/ProgramData" -ipath '*/Start Menu/*' -iname '*.lnk' 2>/dev/null |
		grep -viE '/[^/]*(unins|odinstal|uninstal)[^/]*$' | sort || true
}

# Prints the shortcut selected by a number or a case-insensitive part of its
# name. Dies when nothing or more than one shortcut matches.
resolve_shortcut() {
	local want=$1 l
	local -a all=() hits=()
	mapfile -t all < <(list_shortcuts)
	if [[ $want =~ ^[0-9]+$ ]]; then
		[[ $want -ge 1 && $want -le ${#all[@]} ]] || die "no shortcut #$want (retrowine shortcuts $SLUG)"
		echo "${all[want - 1]}"
		return 0
	fi
	for l in "${all[@]}"; do
		if [[ $(basename "${l,,}") == *"${want,,}"* ]]; then
			hits+=("$l")
		fi
	done
	case ${#hits[@]} in
	0) die "no shortcut matches '$want' (retrowine shortcuts $SLUG)" ;;
	1) echo "${hits[0]}" ;;
	*) die "'$want' matches ${#hits[@]} shortcuts, be more specific or use the number" ;;
	esac
}

cmd_shortcuts() {
	need_game "${1:-}"
	wine_env
	local l n=0
	while IFS= read -r l; do
		n=$((n + 1))
		printf '%3d  %s\n' "$n" "$(basename "$l" .lnk)"
	done < <(list_shortcuts)
	[[ $n -gt 0 ]] || info "no shortcuts in the prefix yet"
}

cmd_run() {
	need_game "${1:-}"
	shift
	parse_launch_opts "$@"
	EXE=${EXE_OVERRIDE:-$EXE}
	RES=${RES_OVERRIDE:-$RES}
	[[ -n $EXE || -n $SHORTCUT ]] || die "EXE is not set in $GAME_DIR/game.conf (see: retrowine exes $SLUG)"
	ensure_prefix

	if [[ $USE_DISC == 1 ]]; then
		attach_physical
		map_drive
	elif [[ -n $IMAGE || -n $(list_images) ]]; then
		attach_image "$(resolve_image)"
		map_drive
	fi

	if [[ -n $SHORTCUT ]]; then
		local lnk
		lnk=$(resolve_shortcut "$SHORTCUT")
		info "shortcut: $(basename "$lnk" .lnk)"
		# NOTE: `start` honours the shortcut's own working directory and arguments
		launch "${MODE_OVERRIDE:-$MODE}" run start /wait /unix "$lnk"
		return 0
	fi

	local unix_exe
	local -a args
	read -ra args <<<"$ARGS"
	unix_exe=$(WINEDEBUG=-all wine winepath -u "$EXE" | tr -d '\r')
	[[ -f $unix_exe ]] || die "EXE not found: $EXE"
	# NOTE: games of this era resolve their data relative to the cwd
	cd "$(dirname "$unix_exe")"
	launch "${MODE_OVERRIDE:-$MODE}" run "$EXE" "${args[@]}" "${REST[@]}"
}

cmd_disc() {
	need_game "${1:-}"
	shift
	parse_launch_opts "$@"
	ensure_prefix
	if [[ $USE_DISC == 1 ]]; then
		attach_physical
	else
		attach_image "$(resolve_image "${REST[0]:-}")"
	fi
	map_drive
}

cmd_exec() {
	need_game "${1:-}"
	shift
	[[ $# -gt 0 ]] || die "exec needs a command"
	ensure_prefix
	"$@"
}

cmd_mark() {
	need_game "${1:-}"
	local status=${2:-} conf="$GAME_DIR/game.conf"
	[[ " $STATUSES " == *" $status "* ]] || die "status must be one of: $STATUSES"
	shift 2
	grep -vE '^(STATUS|NOTES)=' "$conf" >"$conf.tmp"
	printf 'STATUS=%q\nNOTES=%q\n' "$status" "$*" >>"$conf.tmp"
	mv "$conf.tmp" "$conf"
	info "$SLUG: $status"
}

cmd_kill() {
	need_game "${1:-}"
	wine_env
	kill_prefix
}

cmd_umount() {
	need_game "${1:-}"
	local img dev slot
	while IFS= read -r img; do
		dev=$(losetup -nO NAME -j "$img" | head -n1)
		if [[ -n $dev ]]; then
			if findmnt -S "$dev" >/dev/null; then
				udisksctl unmount -b "$dev" >/dev/null
			fi
			udisksctl loop-delete -b "$dev"
			info "detached $(basename "$img") ($dev)"
		fi
		# NOTE: only ask cdemu when it can be running, the CLI would D-Bus-start it
		if [[ -c /dev/vhba_ctl ]]; then
			slot=$(cdemu_slot_of "$img")
			if [[ -n $slot ]]; then
				dev=$(cdemu device-mapping | awk -v slot="$slot" 'NR > 2 && $1 == slot { print $2 }')
				if [[ -n $dev ]] && findmnt -S "$dev" >/dev/null; then
					udisksctl unmount -b "$dev" >/dev/null
				fi
				cdemu unload "$slot"
				info "unloaded $(basename "$img") (cdemu $slot, $dev)"
			fi
		fi
	done < <(list_images)
}

cmd_reset() {
	need_game "${1:-}"
	wine_env
	kill_prefix
	rm -rf -- "${STATE:?}/$SLUG"
	info "$SLUG: prefix + logs deleted"
}

cmd_rm() {
	need_game "${1:-}"
	local n
	n=$(list_images | wc -l)
	if [[ $n -gt 0 && ${2:-} != --force ]]; then
		die "$SLUG has $n disc image(s) -- pass --force to delete the backup too"
	fi
	cmd_umount "$SLUG"
	cmd_reset "$SLUG"
	rm -rf -- "${ROOT:?}/$SLUG"
	info "$SLUG: deleted"
}

# Prints "<recovered-pct> <missing-sectors>" for an image from the ddrescue
# summary `dump` leaves in <image>.info; nothing when there is none.
image_stats() {
	local img=$1 bytes bad
	[[ -f $img.info ]] || return 0
	bytes=$(sed -n 's/^bytes=//p' "$img.info")
	bad=$(sed -n 's/^unrecovered_sectors=//p;s/^bad_sectors=//p' "$img.info" | head -n1)
	awk -v b="${bad:-0}" -v t="${bytes:-0}" 'BEGIN { if (t > 0) printf "%.1f %d\n", 100 - b * 2048 * 100 / t, b }'
}

# Prints how complete the game's dump is: "-" without an image, "?" without
# dump info, "clean", or the recovered percentage of the worst image.
dump_quality() {
	local img pct bad worst="-"
	while IFS= read -r img; do
		pct="" bad=""
		read -r pct bad < <(image_stats "$img") || true
		if [[ -z $pct ]]; then
			if [[ $worst == "-" ]]; then worst="?"; fi
		elif [[ $bad -gt 0 ]]; then
			worst="$pct%"
		elif [[ $worst == "-" || $worst == "?" ]]; then
			worst=clean
		fi
	done < <(list_images)
	echo "$worst"
}

# Wraps a status in its colour when stdout is a terminal.
paint_status() {
	local c=""
	if [[ -t 1 ]]; then
		case $1 in
		works) c=32 ;;
		partial) c=33 ;;
		broken) c=31 ;;
		*) c=2 ;;
		esac
		printf '\033[%sm%-9s\033[0m' "$c" "$1"
	else
		printf '%-9s' "$1"
	fi
}

# Prints one table row of `list`. Args: <game.conf> <slug-column-width>
list_row() {
	GAME_DIR=$(dirname "$1")
	SLUG=$(basename "$GAME_DIR")
	load_conf
	printf "%-${2}s  " "$SLUG"
	paint_status "$STATUS"
	printf "  %-6s  %-6s  %s\n" "$(dump_quality)" \
		"$([[ -f $STATE/$SLUG/prefix/system.reg ]] && echo yes || echo no)" "$TITLE"
}

cmd_list() {
	local conf w=4 name
	shopt -s nullglob
	for conf in "$ROOT"/*/game.conf; do
		name=$(basename "$(dirname "$conf")")
		if [[ ${#name} -gt $w ]]; then w=${#name}; fi
	done
	printf "%-${w}s  %-9s  %-6s  %-6s  %s\n" SLUG STATUS DUMP PREFIX TITLE
	for conf in "$ROOT"/*/game.conf; do
		# NOTE: subshell, load_conf overwrites the config globals per game
		(list_row "$conf" "$w")
	done
	shopt -u nullglob
	echo
	echo "details + notes: retrowine info <slug>"
}

cmd_info() {
	need_game "${1:-}"
	local img cols pct bad q
	cols=$(tput cols 2>/dev/null || echo 100)
	if [[ $cols -gt 110 ]]; then cols=110; fi
	printf '%s\n' "$TITLE"
	printf '  %-9s ' status
	paint_status "$STATUS"
	printf '\n'
	printf '  %-9s %s\n' exe "${EXE:-(not set)}${ARGS:+ $ARGS}"
	printf '  %-9s %s\n' display "mode=$MODE res=$RES${FULLSCREEN:+ fullscreen=$FULLSCREEN}${GAMESCOPE_ARGS:+ gamescope_args=$GAMESCOPE_ARGS}"
	printf '  %-9s %s\n' wine "winver=$WINVER locale=${LOCALE:-(system)} audio=${AUDIO_DRIVER:-(default)} attach=$ATTACH${AFFINITY:+ affinity=$AFFINITY}${TRICKS:+ tricks=$TRICKS}"
	printf '  %-9s %s\n' dir "$GAME_DIR"
	while IFS= read -r img; do
		pct="" bad=""
		read -r pct bad < <(image_stats "$img") || true
		if [[ -z $pct ]]; then
			q="no dump info"
		elif [[ $bad -gt 0 ]]; then
			q="$pct% recovered, $bad sectors missing"
		else
			q="clean read"
		fi
		printf '  %-9s %s (%s, %s)\n' image "$(basename "$img")" "$(du -h "$img" | cut -f1)" "$q"
	done < <(list_images)
	if [[ -f $STATE/$SLUG/prefix/system.reg ]]; then
		printf '  %-9s %s (%s)\n' prefix "$STATE/$SLUG/prefix" "$(du -sh "$STATE/$SLUG/prefix" | cut -f1)"
	else
		printf '  %-9s %s\n' prefix "(none yet)"
	fi
	if [[ -f $GAME_DIR/notes.md ]]; then
		printf '  %-9s %s\n' "more" "$GAME_DIR/notes.md"
	fi
	if [[ -n $NOTES ]]; then
		printf '\n'
		echo "$NOTES" | fold -s -w "$((cols - 2))" | sed 's/^/  /'
	fi
}

main() {
	local sub=${1:-help}
	shift || true
	case $sub in
	new | dump | install | exes | shortcuts | run | disc | exec | mark | kill | umount | reset | rm | list | info)
		ensure_root
		"cmd_$sub" "$@"
		;;
	help | -h | --help) usage ;;
	*)
		usage >&2
		die "unknown command '$sub'"
		;;
	esac
}

main "$@"

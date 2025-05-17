# tensorfiles

[![flake check](https://github.com/tsandrini/tensorfiles/actions/workflows/flake-check.yml/badge.svg)](https://github.com/tsandrini/flake-parts-builder/actions/workflows/flake-check.yml)
[![FlakeHub](https://github.com/tsandrini/tensorfiles/actions/workflows/flakehub-publish.yml/badge.svg)](https://github.com/tsandrini/flake-parts-builder/actions/workflows/flakehub-publish.yml)
[![flake.lock update](https://github.com/tsandrini/tensorfiles/actions/workflows/update-flake-lock.yml/badge.svg)](https://github.com/tsandrini/flake-parts-builder/actions/workflows/update-flake-lock.yml)

## Table of Contents

1. [About](1-about)
1. [Design choices](2-design-choices)
1. [Software](3-software)
   1. [Academics](31-academics)
   1. [Secrets](32-secrets)
1. [Installation](4-installation)
1. [Troubleshooting](5-troubleshooting)
   1. [`Write error: disk full;` during `nixos-install`](write-error-disk-full-during-nixos-install)
1. [Impurities](6-impurities)
   1. [Currently known impurities](61-currently-known-impurities)
   1. [Notes](62-notes)
1. [Resources](7-resources)
1. [Credits & Special thanks](8-credits-special-thanks)
   1. [Major help](81-major-help)
   1. [Additional help](82-additional-help)

## 1. About ❄️

**tensorfiles** represent a set of _fully covariant_, that is invariant to the
chosen coordinate system (**they work on every machine**), fundamental
laws of computing (**how to build my fancy flashy terminals**) ☁️

![img](flake-parts/pkgs/docs/docs/assets/images/showcase_3.png)
![img](flake-parts/pkgs/docs/docs/assets/images/showcase_1.png)

Some of the machines/packages present in this repository are also prebuilt
in the following binary cache

```nix
  nixConfig = {
    extra-substituters = [
      "https://tsandrini.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tsandrini.cachix.org-1:t0AzIUglIqwiY+vz/WRWXrOkDZN8TwY3gk+n+UDt4gw="
    ];
  };
```

The project is also hosted on [FlakeHub](https://flakehub.com/flake/tsandrini/tensorfiles/).

## 2. Design choices ⚙️

- This projects is generated via and uses
  [flake-parts-builder](https://github.com/tsandrini/flake-parts-builder)
  which makes it super easy to share modularity between different projects.
- Modules are disabled by default. Why you might ask? 🤓 ... Setting
  `myModule.enable = true;` can be done from multiple places, moreover we can
  even assign priorities to these expressions (by utilising `lib.mkOverride`),
  however, we can import a given module once and only once ... additional imports
  will yield errors. This behaviour makes it hard to reason about the dependencies
  of individual modules, which is why I opted for the behaviour --
  import everything and enable only the parts that you need.
- Use **profiles** to define and share common configurations packs. Profiles
  typically don't create and add any new functionality but instead preconfigure
  stuff.
- Isolate home manager functionality in such a way so it can be used in non
  NixOS environments 👥
- I prefer to only use `inputs` and `system` variables instead of the more
  convenient `inputs'` and `self'` of flake-parts due to the code being easier
  to copy and transfer to older non flake-parts codebases.

## 3. Software 🖥️

I have a bunch of machines running some nix or directly NixOS with a variety
of setups. To discern between them but still use the same base I use nixos/hm
modules and their appropriate profiles.

### 3.1. Academia 👩🏽‍💼

1. [org-roam](https://www.orgroam.com/): This is the heart of everything that I
   do, TODOs, daily journals, scratchpads, notetaking and personal research wiki.
   The internal wiki is interlinked with zotero entries as well as anki cards.
   - TODOs: [org-agenda](https://orgmode.org/manual/Agenda-Views.html)
   - visualization: [org-roam-ui](https://github.com/org-roam/org-roam-ui)
   - anki connection: [org-anki-editor](https://github.com/louietan/anki-editor)
     ![img](flake-parts/pkgs/docs/docs/assets/images/showcase_org_roam_ui.png)
1. [zotero](https://www.zotero.org/): This is my backend for all of my
   bibliography as well as the individual `.pdf` files. As of now I keep them up
   to date between machines using [syncthing](https://syncthing.net/), but
   I’ll probably set up a personal cloud when I’ll have spare time.
1. [anki](https://apps.ankiweb.net/): Since I have the memory of worm I try to
   keep my long-term memory of different subjects fresh using flashcards. I sync
   the cards using ankis official cloud.

### 3.2. Secrets 🔑

For my day to day passwords I use a locally synced
[keepassxc](https://keepassxc.org/) encrypted database and for the NixOS based
secrets I use [agenix](https://github.com/ryantm/agenix). I also try to avoid
using any globally available pubkeys and rather tend to use machine specific
ones instead (for obvious reasons).

_Note_: plz no pwn xd, if you see any vulnerabilities **please, send me a
mail** at [security@tsandrini.sh](mailto:security@tsandrini.sh)

## 4. Installation 💾

TODO

## 5. Troubleshooting 😵‍💫

### `Write error: disk full;` during `nixos-install`

If you get any error of this kind during the installation of this flake
you have most likely run out of `$TMPDIR` space. This is usually due
to `$TMPDIR` being set up as a RAM based tmpfs and thus not having enough
RAM for nix store cache during installation.

The most clean & general solution to this would be to create a minimal
based installation and then run a `nixos-rebuild` (and I still might do that)
but that kind of defeats the purpose of what I am aiming for which would be
to run `nixos-install`, a single command, and end up with a fully prepared
system.

Considering that a quick workaround is to navigate `$TMPDIR` to a different
folder (this might slow the installation process if you redirect it to a
spinning disk tmp filesystem, however, assuming you have a decent bandwidth
is’s still just by minutes)

```bash
mkdir -p /mnt/tmp
USER=$USER TMPDIR="/mnt/tmp" nixos-install --root /mnt --flake .#$HOST
```

A different solution in case you have more spare RAM would be to remount
tmpfs, for example

```bash
mount -o remount,size=15G /tmp
```

## 6. Impurities 💩

I heavily dislike using the `--impure` flag, which is unfortunately required
in certain use cases, and I go really out of my way to patch stuff and
avoid using it.

### 6.1 Currently known impurities

- **none**! 🚀🚀

### 6.2 Notes

- [shadow-nix](https://github.com/NicolasGuilloux/shadow-nix) and all its
  forks rely on impure imports of hashes, so I am maintaining my own fork
  [tsandrini/shadow-nix](https://github.com/tsandrini/shadow-nix)
- I was previously using [devenv](https://devenv.sh/), however, it still doesn't
  work really well in a pure mode, so switched to a simple devshell instead.

## 7. Resources 📚

The whole nix ecosystem is in its foundations a revolutionary piece of
software and once you get the hang of it you feel like you’ve really
conquered the art of computer wizardry, however, it’s so different from
everything that is the current status quo of compsci and thus needs
appropriate extensive documentation/tutorials/etc… which is, however,
currently not the case.

Due to this exact reason I’m leaving here a list of resources/flakes that
helped me to (somewhat) learn the ways of nix (TODO: maybe write more?
manual.org?)

- [Nix Pills: obligatory pills](https://nixos.org/guides/nix-pills/)
- [NixOS search: this should be your homepage really](https://search.nixos.org/options)
- [Home-Manager opts search: the same search but for home-manager, secondary
  homepage tbh](https://mipmip.github.io/home-manager-option-search/)
- [hlissner/dotfiles: great resource for learning how to appropriately modularize code](https://github.com/hlissner/dotfiles)
- [notusknot/dotfiles-nix: a more straightforward config but with all the needed
  parts, great introduction to flakes, home-manager](https://github.com/notusknot/dotfiles-nix)
- [Nix Cookbook: custom scripts, package wrapper scripts](https://nixos.wiki/wiki/Nix_Cookbook)
- [balsoft/nixos-config: more modularized but not overly complicated config](https://github.com/balsoft/nixos-config)
- [A really nice blogpost/tutorial on encrypted nixos opt-in system using btrfs](https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html)
- [Github code search: thanks to how the nix lang works the code search should be of a huge help, included an example](https://github.com/search?q=pkgs.writeShellScriptBin+language%3ANix&type=code&l=Nix)
- [This is where flake-parts finally clicked for me, huge thanks to viperml~~](https://github.com/viperML/dotfiles)
- [dc-tec/nixvim awesome nixvim config that got me started](https://github.com/dc-tec/nixvim/)

## 8. Credits & Special thanks

To reiterate the previous [Resources](7-resources) section, here are also some
explicit shoutouts & thanks to the people from whom I have at some point in time
taken some piece of code or have been inspired from. Huge thanks ❤️

### 8.1 Major help

These are people that are engrained in the nix community and whose work I/we
use on a daily basis. I hope they will happily continue to be a part of the
nix community and I thank them for all of their contributions.

[edolstra](https://github.com/edolstra)
-- [grahamc](https://github.com/grahamc)
-- [domenkozar](https://github.com/domenkozar)
-- [Mic92](https://github.com/Mic92)
-- [hlissner](https://github.com/hlissner)
-- [viperML](https://github.com/viperML)
-- [roberth](https://github.com/roberth)
-- [fufexan](https://github.com/fufexan)
-- [NobbZ](https://github.com/NobbZ)

### 8.2 Additional help

Additional help with certain specific areas, inspiration or code snippets.

[balsoft](https://github.com/balsoft)
-- [dc-tec](https://github.com/dc-tec)
-- [notusknot](https://github.com/notusknot/)

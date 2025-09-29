# ===============================
# USB Backup Script (to usb1)
# - Produces: <identity>-<YYYY-MM-DD>_<HH-MM>.backup and .rsc
# - Writes to: usb1/<your backupDir>
# ===============================

:log info "Starting configuration backup to USB drive..."

# ---- Config ----
:local backupRoot "usb1"
:local backupDir ($backupRoot . "/backups")   ;# change "backups" if you like

# ---- Preconditions ----
:if ([:len [/file find where name=$backupRoot]] = 0) do={
    :log error ("USB root '" . $backupRoot . "' not found")
    :error "USB drive not found"
}

# ---- Identity & Timestamp ----
:local identity [/system identity get name]
:local dateStr [/system clock get date]     ;# assumes ISO like 2025-09-15
:local timeStr [/system clock get time]     ;# HH:MM:SS
:local timeClean ([:pick $timeStr 0 2] . "-" . [:pick $timeStr 3 5])
:local timestamp ($dateStr . "_" . $timeClean)

# ---- Base path (no extension; RouterOS appends .backup/.rsc) ----
:local basePath ($backupDir . "/" . $identity . "-" . $timestamp)

# ---- Binary backup (.backup) ----
/system backup save name=$basePath dont-encrypt=yes
:log info ("Binary backup saved to: " . $basePath . ".backup")

# ---- Configuration export (.rsc) ----
/export file=$basePath
:log info ("Configuration export saved to: " . $basePath . ".rsc")

:log info "USB backup script finished."

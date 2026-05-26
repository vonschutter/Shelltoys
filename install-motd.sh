#!/usr/bin/env bash
set -euo pipefail

PROGRAM_NAME="custom-motd"
GENERATOR="/usr/local/bin/${PROGRAM_NAME}"
PROFILE_HOOK="/etc/profile.d/${PROGRAM_NAME}.sh"
UPDATE_MOTD_HOOK="/etc/update-motd.d/99-${PROGRAM_NAME}"
STATIC_MOTD="/etc/motd"
BACKUP_ROOT="/var/backups/${PROGRAM_NAME}"

usage() {
  cat <<'USAGE'
Usage:
  sudo ./install-motd.sh install
  sudo ./install-motd.sh uninstall
  ./install-motd.sh print

Installs a terminal login MOTD for the major Linux distro families:
  Ubuntu, Debian, Fedora/RHEL-family, Arch-family

The installer also works on openSUSE/SLES-style systems by using the
generic profile hook and /etc/motd fallback.
USAGE
}

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Run this command with sudo/root: $*" >&2
    exit 1
  fi
}

detect_os_id() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s\n' "${ID:-unknown}"
  else
    printf '%s\n' "unknown"
  fi
}

detect_os_family() {
  local os_id
  os_id="$(detect_os_id)"

  case "$os_id" in
    ubuntu|debian)
      printf '%s\n' "debian"
      ;;
    fedora|rhel|centos|rocky|almalinux|ol)
      printf '%s\n' "redhat"
      ;;
    arch|manjaro|endeavouros|garuda)
      printf '%s\n' "arch"
      ;;
    opensuse*|sles)
      printf '%s\n' "suse"
      ;;
    *)
      printf '%s\n' "generic"
      ;;
  esac
}

backup_file() {
  local path="$1"

  [ -e "$path" ] || return 0
  mkdir -p "$BACKUP_ROOT"
  cp -a "$path" "${BACKUP_ROOT}/$(basename "$path").$(date +%Y%m%d%H%M%S)"
}

install_generator() {
  cat > "$GENERATOR" <<'MOTD_GENERATOR'
#!/usr/bin/env bash
set -euo pipefail

color() {
  local code="$1"
  shift

  if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    printf '\033[%sm%s\033[0m' "$code" "$*"
  else
    printf '%s' "$*"
  fi
}

read_os_name() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s\n' "${PRETTY_NAME:-Linux}"
  else
    printf '%s\n' "Linux"
  fi
}

first_ip() {
  hostname -I 2>/dev/null | awk '{print $1}'
}

load_average() {
  awk '{print $1 ", " $2 ", " $3}' /proc/loadavg 2>/dev/null || printf 'unknown'
}

memory_line() {
  if command -v free >/dev/null 2>&1; then
    free -h | awk '/^Mem:/ {print $3 " used / " $2 " total"}'
  else
    printf 'unknown'
  fi
}

disk_line() {
  df -h / 2>/dev/null | awk 'NR == 2 {print $3 " used / " $2 " total (" $5 ")"}'
}

uptime_line() {
  uptime -p 2>/dev/null | sed 's/^up //' || printf 'unknown'
}

last_login_line() {
  if command -v lastlog >/dev/null 2>&1; then
    lastlog -u "${USER:-$(id -un)}" 2>/dev/null | awk 'NR == 2 {$1=""; sub(/^ +/, ""); print}'
  fi
}

host="$(hostname -f 2>/dev/null || hostname)"
os_name="$(read_os_name)"
kernel="$(uname -r)"
ip_addr="$(first_ip)"
last_login="$(last_login_line || true)"

printf '\n'
color '1;36' "Welcome to ${host}"
printf '\n'
printf '%s\n' "----------------------------------------"
printf '%-12s %s\n' "OS:" "$os_name"
printf '%-12s %s\n' "Kernel:" "$kernel"
printf '%-12s %s\n' "Uptime:" "$(uptime_line)"
printf '%-12s %s\n' "Load:" "$(load_average)"
printf '%-12s %s\n' "Memory:" "$(memory_line)"
printf '%-12s %s\n' "Disk /:" "$(disk_line)"
[ -n "${ip_addr:-}" ] && printf '%-12s %s\n' "IP:" "$ip_addr"
[ -n "${last_login:-}" ] && printf '%-12s %s\n' "Last login:" "$last_login"
printf '%s\n\n' "----------------------------------------"
MOTD_GENERATOR

  chmod 0755 "$GENERATOR"
}

install_update_motd_hook() {
  mkdir -p "$(dirname "$UPDATE_MOTD_HOOK")"
  cat > "$UPDATE_MOTD_HOOK" <<EOF
#!/bin/sh
exec "$GENERATOR"
EOF
  chmod 0755 "$UPDATE_MOTD_HOOK"
}

install_profile_hook() {
cat > "$PROFILE_HOOK" <<EOF
# Installed by $0.
# Show the MOTD once for interactive terminal login shells.
case "\$-" in
  *i*) ;;
  *)
    return 0 2>/dev/null || exit 0
    ;;
esac

if [ ! -t 1 ]; then
  return 0 2>/dev/null || exit 0
fi

if [ "\${CUSTOM_MOTD_SHOWN:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

export CUSTOM_MOTD_SHOWN=1

[ -x "$GENERATOR" ] && "$GENERATOR"
EOF
  chmod 0644 "$PROFILE_HOOK"
}

install_static_motd() {
  backup_file "$STATIC_MOTD"
  cat > "$STATIC_MOTD" <<EOF
This system uses a dynamic login MOTD.
Run: $GENERATOR
EOF
  chmod 0644 "$STATIC_MOTD"
}

install_motd() {
  local family
  family="$(detect_os_family)"

  need_root install
  install_generator

  case "$family" in
    debian)
      install_update_motd_hook
      ;;
    redhat|arch|suse|generic)
      install_profile_hook
      install_static_motd
      ;;
  esac

  echo "Installed ${PROGRAM_NAME} for ${family} systems."
  echo "Preview with: ${GENERATOR}"
}

uninstall_motd() {
  need_root uninstall

  rm -f "$UPDATE_MOTD_HOOK" "$PROFILE_HOOK" "$GENERATOR"
  echo "Removed ${PROGRAM_NAME} hooks and generator."
  echo "If /etc/motd was replaced, backups are in: ${BACKUP_ROOT}"
}

case "${1:-}" in
  install)
    install_motd
    ;;
  uninstall)
    uninstall_motd
    ;;
  print)
    if [ -x "$GENERATOR" ]; then
      "$GENERATOR"
    else
      echo "Not installed yet. Run: sudo $0 install" >&2
      exit 1
    fi
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

#!/usr/bin/env bash
# Install/repair dependencies for the YT Music sidebar tab (YtMusic / InnerTube).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IN_TERMINAL="${1:-}"

# Relaunch in a terminal if not already.
if [[ -z "$IN_TERMINAL" && ! -t 0 ]]; then
  for term in kitty alacritty foot konsole wezterm gnome-terminal xfce4-terminal terminator; do
    if command -v "$term" >/dev/null 2>&1; then
      case "$term" in
        kitty)
          exec "$term" --hold -e bash "$SCRIPT_DIR/ytmusic-install-deps.sh" --in-terminal ;;
        gnome-terminal)
          exec "$term" -- bash "$SCRIPT_DIR/ytmusic-install-deps.sh" --in-terminal ;;
        *)
          exec "$term" -e bash "$SCRIPT_DIR/ytmusic-install-deps.sh" --in-terminal ;;
      esac
    fi
  done
  printf 'No terminal emulator found.\n' >&2
  exit 1
fi

printf '=== YT Music dependency installer ===\n'

# Detect distro
DIST_ID="unknown"
DIST_FAMILY="unknown"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DIST_ID="${ID:-$DIST_ID}"
  if [[ -n "${ID_LIKE:-}" ]]; then
    DIST_FAMILY="$ID_LIKE"
  else
    DIST_FAMILY="$DIST_ID"
  fi
fi

run_cmd() {
  printf '\n$ %s\n' "$*"
  "$@"
}

need_sudo() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1; then
    return 0
  fi
  printf 'sudo no encontrado. Ejecuta como root.\n' >&2
  exit 1
}

# Arch/Artix family
is_arch=0
case "$DIST_ID" in
  arch|artix|manjaro|endeavouros|cachyos|garuda|rebornos|arco|hyperbola)
    is_arch=1
    ;;
esac
case "$DIST_FAMILY" in
  arch|artix|manjaro)
    is_arch=1
    ;;
esac

if [[ $is_arch -eq 1 ]]; then
  printf 'Distro detected: %s (Arch family)\n' "$DIST_ID"
  need_sudo
  PKGS=(yt-dlp mpv socat deno python-ytmusicapi ffmpeg mpv-mpris)
  if command -v pacman >/dev/null 2>&1; then
    run_cmd sudo pacman -S --needed --noconfirm "${PKGS[@]}"
  elif command -v paru >/dev/null 2>&1; then
    run_cmd paru -S --needed --noconfirm "${PKGS[@]}"
  elif command -v yay >/dev/null 2>&1; then
    run_cmd yay -S --needed --noconfirm "${PKGS[@]}"
  else
    printf 'pacman/paru/yay no encontrado.\n' >&2
    exit 1
  fi
  printf '\n=== Install complete ===\n'
  read -rp $'\nPulsa Enter para salir...'
  exit 0
fi

printf 'Distribución no reconocida (%s, family %s)\n' "$DIST_ID" "$DIST_FAMILY"
printf 'Instala manualmente: yt-dlp, mpv, socat, deno, python-ytmusicapi, ffmpeg\n'
read -rp $'\nPulsa Enter para salir...'
exit 0

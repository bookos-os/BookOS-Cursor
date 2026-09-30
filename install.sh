#!/bin/bash
# Compila (si hace falta) e instala el tema de cursores BookOS.
# Por defecto instala en ~/.local/share/icons (no requiere sudo); con
# --system instala en /usr/share/icons para todos los usuarios.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIANTS=(Light Dark)
SCOPE="user"
SET_DEFAULT=""

usage() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --system          Install system-wide to /usr/share/icons (requires sudo)
  --variant NAME     Install only "Light" or "Dark" (default: both)
  --set-default NAME Set the given variant as the active cursor theme
                      (via gsettings, if available)
  -h, --help         Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --system) SCOPE="system"; shift ;;
        --variant)
            [ $# -ge 2 ] || { echo "Missing value for --variant" >&2; exit 1; }
            VARIANTS=("$2"); shift 2 ;;
        --set-default)
            [ $# -ge 2 ] || { echo "Missing value for --set-default" >&2; exit 1; }
            SET_DEFAULT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [ "$SCOPE" = "system" ]; then
    DEST_BASE="/usr/share/icons"
    [ "$(id -u)" -eq 0 ] || { echo "System-wide install requires sudo/root." >&2; exit 1; }
else
    DEST_BASE="$HOME/.local/share/icons"
fi

command -v rsvg-convert >/dev/null || { echo "Missing dependency: rsvg-convert" >&2; exit 1; }
command -v xcursorgen >/dev/null || { echo "Missing dependency: xcursorgen" >&2; exit 1; }

mkdir -p "$DEST_BASE"

for VARIANT in "${VARIANTS[@]}"; do
    [ -d "$ROOT/$VARIANT" ] || { echo "Unknown variant: $VARIANT" >&2; exit 1; }

    echo "==> Building $VARIANT theme..."
    "$ROOT/scripts/build-cursors.sh" "$VARIANT"

    DEST="$DEST_BASE/BookOS-$VARIANT"
    echo "==> Installing to $DEST"
    rm -rf "$DEST"
    mkdir -p "$DEST/cursors"
    cp -r "$ROOT/build/$VARIANT/cursors/." "$DEST/cursors/"
    cp "$ROOT/build/$VARIANT/index.theme" "$DEST/index.theme"

    echo "==> $VARIANT theme installed at $DEST"
done

if [ -n "$SET_DEFAULT" ]; then
    THEME_NAME="BookOS-$SET_DEFAULT"
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME"
        echo "==> Active cursor theme set to $THEME_NAME"
    else
        echo "gsettings not found; set the cursor theme manually to $THEME_NAME" >&2
    fi
fi

echo "Done. You may need to log out and back in for the change to take full effect."

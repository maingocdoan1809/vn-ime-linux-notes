#!/bin/sh
# Đặt Bamboo sang chế độ ForwardKeyEvent I (không gạch chân) và nạp lại IBus.
set -eu
dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
mkdir -p "$HOME/.config/ibus-bamboo"
if [ -f "$HOME/.config/ibus-bamboo/ibus-bamboo.config.json" ]; then
  cp "$HOME/.config/ibus-bamboo/ibus-bamboo.config.json" \
     "$HOME/.config/ibus-bamboo/ibus-bamboo.config.json.bak"
fi
cp "$dir/config/ibus-bamboo.config.json" "$HOME/.config/ibus-bamboo/ibus-bamboo.config.json"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]"
ibus restart
sleep 2
ibus engine Bamboo
ibus engine

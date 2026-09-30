#!/usr/bin/env bash
# 把本目录（fonts/）里存档的字体装到 Rime 候选窗字体链要读的位置。
# 迁移新机器时跑一次即可：bash fonts/install_fonts.sh
# 用法: install_fonts.sh [目标目录]     默认 ~/Library/Fonts
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
dst="${1:-$HOME/Library/Fonts}"

cd "$src"
echo "校验 SHA256SUMS："
shasum -a 256 -c SHA256SUMS

mkdir -p "$dst"
cp -v ./*.ttf "$dst/"

echo
echo "已装到 $dst"
echo "接着：fc-cache -f 刷新缓存、重启鼠须管；字体链写在 squirrel.custom.yaml 的 style/font_face"

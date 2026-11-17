#!/bin/bash
# ============================================================
# install_fonts.sh — 把本目录的字体装到鼠须管候选窗字体链要读的位置
# ============================================================
# 字体链写在 squirrel.custom.yaml：
#   style/font_face: "LXGW WenKai, HanaMinB, Plangothic P1, Plangothic P2"
# 缺一层就看不到 CJK Ext B（U+20000）以上的字，落 LastResort.otf 显示成方块。
#
# 用法:
#   bash fonts/install_fonts.sh                  # 装到 ~/Library/Fonts（同版本则跳过）
#   bash fonts/install_fonts.sh --dry-run        # 只打印要做什么
#   bash fonts/install_fonts.sh --force          # 已装也重拷
#   bash fonts/install_fonts.sh --dest /tmp/f    # 指定目标目录（试装）
# 装完重启鼠须管（或菜单「重新部署」）。
# ============================================================
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/Library/Fonts"
DEST_GIVEN=0
DRY_RUN=0
FORCE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --dest)    DEST="${2:-}"; DEST_GIVEN=1; shift ;;
    --dest=*)  DEST="${1#--dest=}"; DEST_GIVEN=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *)         echo "未知参数: $1（-h 看用法）" >&2; exit 2 ;;
  esac
  shift
done

[ -n "$DEST" ] || { echo "[错误] --dest 需要目录参数" >&2; exit 2; }
[ -f "$SRC/SHA256SUMS" ] || { echo "[错误] 缺校验文件: $SRC/SHA256SUMS" >&2; exit 1; }

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "[dry-run] $*"; else "$@"; fi }

echo "== 1/4 校验存档（${SRC}）=="
(cd "$SRC" && shasum -a 256 -c SHA256SUMS)

# 文件名 | 字体族名（族名是 squirrel.custom.yaml 里写的那个；写错会被鼠须管静默跳过）
FONTS="LXGWWenKai-Regular.ttf|LXGW WenKai
HanaMinB.ttf|HanaMinB
PlangothicP1-Regular.ttf|Plangothic P1
PlangothicP2-Regular.ttf|Plangothic P2"

echo
echo "== 2/4 安装到 $DEST =="
run mkdir -p "$DEST"
while IFS='|' read -r file family; do
  [ -n "$file" ] || continue
  [ "$DRY_RUN" -eq 1 ] || [ -f "$SRC/$file" ] || { echo "[错误] 缺文件: $SRC/$file" >&2; exit 1; }
  if [ "$FORCE" -eq 0 ] && [ -f "$DEST/$file" ] && cmp -s "$SRC/$file" "$DEST/$file"; then
    echo "[跳过] ${family}（已是同一版本）"
  else
    run cp -f "$SRC/$file" "$DEST/$file"
    echo "[安装] $family  ← $file"
  fi
done <<< "$FONTS"

echo
echo "== 3/4 刷新字体缓存 =="
if [ "$DRY_RUN" -eq 0 ] && command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$DEST" >/dev/null 2>&1 || true
  echo "fc-cache -f $DEST"
else
  echo "（无 fc-cache 或 dry-run，跳过；鼠须管走 CoreText，不刷也生效）"
fi

echo
echo "== 4/4 验证 =="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] 跳过验证"
  exit 0
fi

while IFS='|' read -r file family; do
  [ -n "$family" ] || continue
  if [ -f "$DEST/$file" ]; then
    echo "[ok] $file 已就位"
  else
    echo "[失败] $file 不在 $DEST" >&2
  fi
done <<< "$FONTS"

if command -v fc-list >/dev/null 2>&1; then
  # Ext B（U+20000）应只剩字体链里的那几个，没装的机器上只有 .LastResort
  echo "覆盖 U+20000 的字体族："
  fc-list ':charset=20000' family | sed 's/^/  /'
fi

echo
echo "接着：重启鼠须管（或菜单里「重新部署」），再打笔画反引号 h/s/p/n/z 验生僻字是否出字。"
if [ "$DEST_GIVEN" -eq 1 ]; then
  echo "注意：这次装到 ${DEST}，不是默认的 $HOME/Library/Fonts，鼠须管读不到那里。"
fi
exit 0

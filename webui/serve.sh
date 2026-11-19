#!/usr/bin/env bash
#

# 用法：  ./serve.sh [端口]
# 说明：  这个脚本只服务 WebUI 静态文件；语音合成仍由 tts-server 提供。
set -euo pipefail

PORT="${1:-5173}"
HOST="0.0.0.0"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$DIR"

echo "WebUI 已就绪：http://${HOST}:${PORT}/"
echo "也可以直接用浏览器打开：file://${DIR}/index.html"
echo "（请先启动 tts-server，默认地址 http://127.0.0.1:8080）"
echo

exec python3 -m http.server "$PORT" --bind "$HOST"

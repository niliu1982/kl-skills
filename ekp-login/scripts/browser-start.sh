#!/bin/bash
# ============================================================
# EKP 浏览器环境启动脚本
# ------------------------------------------------------------
# 解决的关键问题：
#   EKP 投产详情页(prodStatus)通过 window.open 弹窗打开。
#   headless Chromium 默认拦截弹窗 → window.open 返回 null →
#   投产页打开报"操作失败！很抱歉，操作失败！"。
#   必须加 --disable-popup-blocking 启动浏览器。
#
# 适用场景：
#   - agent-browser 自动启动失败时（root 沙箱缺 --no-sandbox，
#     报 "Auto-launch failed: CDP command timed out"）
#   - 任何需要 EKP 弹窗能力的沙箱环境
#
# 用法：
#   bash browser-start.sh            # 默认端口 9222
#   EKP_CDP_PORT=9333 bash browser-start.sh   # 指定端口
# ============================================================
set -e

PORT="${EKP_CDP_PORT:-9222}"

echo "==> EKP 浏览器环境启动 (port=$PORT)"

# 1. 清理旧实例（避免端口冲突）
pkill -f "chromium.*remote-debugging-port=$PORT" 2>/dev/null || true
sleep 1

# 2. 启动 Chromium
#    关键参数：
#      --no-sandbox          root 环境必需
#      --disable-popup-blocking   EKP 弹窗（prodStatus）必需
#      --disable-dev-shm-usage    小内存容器必需
nohup chromium --headless --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --disable-software-rasterizer --disable-popup-blocking \
  --remote-debugging-port=$PORT about:blank \
  > /tmp/ekp-chromium.log 2>&1 &

# 3. 等待 CDP 就绪（最多 20 秒）
READY=0
for i in $(seq 1 20); do
  if curl -s --max-time 2 "http://127.0.0.1:$PORT/json/version" > /dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" != "1" ]; then
  echo "✗ CDP 未就绪，请检查 /tmp/ekp-chromium.log" >&2
  exit 1
fi
echo "✓ CDP 就绪 (port=$PORT)"

# 4. 连接 agent-browser
agent-browser connect "$PORT"

echo "✓ 浏览器环境就绪（--disable-popup-blocking 已启用）"
echo "  后续：agent-browser open 'https://ekp.king-long.com.cn/sys/portal/page.jsp'"
echo "  登录凭据读取：~/.config/ekp/username 和 ~/.config/ekp/password"

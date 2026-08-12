#!/bin/bash
# LocalMind UI 测试运行器
# 规避 Xcode 26.5 模拟器 backboardd 崩溃导致 xcodebuild 挂死的已知 bug。
# 详见 docs/superpowers/specs/2026-08-13-xcode26-ui-test-hang-diagnosis.md
#
# 用法:
#   ./run-uitests.sh              # 跑完整 UI 套件（iOS 26.4 模拟器）
#   ./run-uitests.sh <用例名>     # 只跑指定用例
#   ./run-uitests.sh --list       # 列出全部用例
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$(dirname "$0")"

# iOS 26.4 设备（规避 26.5 backboardd 崩溃）
DEVICE_ID="090FADD8-5127-407F-9638-30C134BD3BA5"

# 先构建，避免测试阶段长编译干扰
xcodegen generate >/dev/null
xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath build build-for-testing 2>&1 | tail -1

if [ "${1:-}" = "--list" ]; then
  echo "可用 UI 测试用例:"
  grep -oE "func test[A-Za-z0-9]+" UITests/LocalMindUITests.swift | sed 's/func //'
  exit 0
fi

ONLY=""
if [ -n "${1:-}" ]; then
  ONLY="-only-testing:LocalMindUITests/LocalMindUITests/$1"
fi

# 用 timeout 包裹防止无限挂死（8 分钟上限）
# 注意: macOS 无 GNU timeout，用后台 + 轮询实现
(
  xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    -derivedDataPath build test-without-building $ONLY 2>&1 \
    | grep -E "Test Case.*LocalMindUITests.*(passed|failed)|Test Suite 'LocalMindUITests' (passed|failed)"
) &
PID=$!

for i in $(seq 1 96); do
  if ! kill -0 "$PID" 2>/dev/null; then
    wait "$PID"
    exit $?
  fi
  sleep 5
done

echo "TIMEOUT: UI 测试超过 8 分钟，已终止（可能触发 backboardd 崩溃）" >&2
kill "$PID" 2>/dev/null
exit 124

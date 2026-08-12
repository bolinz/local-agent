# Xcode 26 UI 测试挂起问题诊断与规避

- 日期：2026-08-13
- 影响：`xcodebuild test` 运行完整 UI 测试套件时无限挂起（数小时无响应）

## 症状

- 完整 `xcodebuild test` 跑 `LocalMindUITests` 套件时卡死，无超时机制导致挂起数小时
- 每个 UI 用例单独用 `-only-testing` 跑都能通过（40-50 秒）
- 简化 settings 用例后单独跑通过，但完整套件仍挂起

## 根因（已定位）

**iOS 26.5 模拟器运行时的 `backboardd` 反复崩溃。**

证据：
1. `~/Library/Logs/DiagnosticReports/backboardd-*.ips` 崩溃报告 **25 次**，时间戳与每次 UI 测试运行精确对应
2. 崩溃类型 `SIGTRAP`（`EXC_BREAKPOINT`，信号码 5）—— backboardd 断言失败
3. 崩溃点：`SimFramebuffer.__SFBConnectionConnect` —— **模拟器帧缓冲渲染子系统**
4. 该崩溃是 CoreSimulator 系统级 bug，与 App 代码、测试代码完全无关

**机制**：`backboardd` 是模拟器的 UI 事件路由进程（点击/滑动/hit-test 全依赖它）。
- 单用例：崩溃一次 → 模拟器自动恢复 → 用例恰好完成
- 完整套件：连续 5 个用例，backboardd 反复崩溃 → UI 事件路由失效 → XCUITest runner 死锁 → `xcodebuild` 无限等待（默认无测试超时）

## 解决方案

### 规避（已验证有效）：使用 iOS 26.4 运行时跑 UI 测试

```bash
xcodebuild -project LocalMind.xcodeproj -scheme LocalMind \
  -destination 'platform=iOS Simulator,id=<26.4设备UDID>' \
  -derivedDataPath build test
```

26.4 设备 UDID（`xcrun simctl list devices available` 查）：
- iPhone 17 Pro: `090FADD8-5127-407F-9638-30C134BD3BA5`

**验证结果**：iOS 26.4 上完整套件 5 个用例全部通过，backboardd 零新增崩溃。

注意：destination 的 OS 值必须精确（`26.4.1` 而非 `26.4`），否则 xcodebuild 匹配不到设备。

### 其他缓解措施（未全部验证）

- 每个用例加 `-only-testing` 单独跑（已用，可工作但慢）
- 给 xcodebuild 外层加 `timeout` 命令防挂死
- 官方修复需等 Apple 更新 Xcode/CoreSimulator（这是模拟器系统 bug）

## 相关已知问题

- Apple 社区：Xcode 26 Simulator crashes（Appium/UI 测试在 Xcode 26 上不稳定）
- CircleCI：Tests Hanging on Xcode 26
- Xcode 26 模拟器有多项已知回归（ReportCrash CPU bug、LLDB attach 挂起等）

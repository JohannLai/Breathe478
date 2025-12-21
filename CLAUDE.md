# Breathe 478 - 项目架构文档

## 项目概述

Apple Watch 独立应用，实现 4-7-8 呼吸法练习，带 HRV 追踪和科学统计功能。

## 技术栈

- **平台**: watchOS 11.0+
- **语言**: Swift 5.9+
- **框架**: SwiftUI, SwiftData, HealthKit, Charts
- **架构**: MVVM
- **构建工具**: XcodeGen

## 4-7-8 呼吸法规则

| 阶段 | 时长 | 动画 | 颜色 |
|------|------|------|------|
| 吸气 (Inhale) | 4 秒 | 花瓣展开 | 青色 `rgb(89, 201, 194)` |
| 屏气 (Hold) | 7 秒 | 保持展开 | 绿色 `rgb(79, 181, 150)` |
| 呼气 (Exhale) | 8 秒 | 花瓣收缩 | 蓝色 `rgb(100, 209, 255)` |

默认 4 个循环，总时长约 76 秒。

---

## 项目结构

```
Breathe478/
├── project.yml                    # XcodeGen 配置
├── CLAUDE.md                      # 本文档
├── README.md                      # 使用说明
└── Breathe478 Watch App/
    ├── Breathe478App.swift        # App 入口 (SwiftData 容器)
    ├── Breathe478.entitlements    # HealthKit 权限
    ├── Info.plist                 # 应用配置
    │
    ├── Models/
    │   ├── BreathingPhase.swift   # 呼吸阶段枚举
    │   ├── BreathingState.swift   # 会话状态枚举
    │   └── SessionRecord.swift    # SwiftData 数据模型
    │
    ├── ViewModels/
    │   └── BreathingViewModel.swift  # 核心业务逻辑
    │
    ├── Views/
    │   ├── ContentView.swift      # 主容器 (TabView)
    │   ├── StartView.swift        # 开始页面
    │   ├── BreathingView.swift    # 呼吸练习页面
    │   ├── CompletionView.swift   # 完成页面
    │   ├── StatisticsView.swift   # 统计页面 (HRV 图表)
    │   ├── PetalView.swift        # 花瓣动画组件
    │   └── Theme.swift            # 主题/颜色/样式
    │
    ├── Managers/
    │   ├── HapticManager.swift    # 触觉反馈
    │   └── HealthKitManager.swift # HealthKit 集成
    │
    └── Resources/
        ├── Localizable.xcstrings  # 多语言 (en/zh-Hans)
        └── Assets.xcassets/       # 图标/颜色
```

---

## 核心组件

### 1. BreathingPhase (模型)

```swift
enum BreathingPhase {
    case inhale  // 4秒, scale → 1.0
    case hold    // 7秒, scale = 1.0
    case exhale  // 8秒, scale → 0.5
}
```

### 2. BreathingState (模型)

```swift
enum BreathingState {
    case ready
    case breathing(phase: BreathingPhase)
    case paused(previousPhase: BreathingPhase)
    case completed
}
```

### 3. SessionRecord (SwiftData)

```swift
@Model
class SessionRecord {
    var startDate: Date
    var endDate: Date
    var cyclesCompleted: Int
    var duration: TimeInterval
    var hrvBefore: Double?      // 练习前 HRV
    var hrvAfter: Double?       // 练习后 HRV
    var averageHeartRate: Double?
    var syncedToHealthKit: Bool
}
```

### 4. BreathingViewModel

核心职责：
- 管理呼吸计时器 (0.05s 间隔)
- 控制阶段切换逻辑
- 驱动动画 scale (0.5 ↔ 1.0)
- 触发触觉反馈
- 保存会话到 SwiftData
- 同步到 HealthKit

### 5. BreathingFlower (动画)

```swift
struct BreathingFlower: View {
    let scale: CGFloat       // 0.5 (收缩) 到 1.0 (展开)
    let phase: BreathingPhase?

    // 6 个圆形花瓣
    // 根据 scale 计算 offset
    // 根据 phase 切换颜色
    // plusLighter 混合模式
    // 60秒缓慢旋转
}
```

---

## 触觉反馈模式

| 时机 | 类型 | 说明 |
|------|------|------|
| 开始吸气 | `.start` | 明显开始提示 |
| 开始屏气 | `.click` | 轻微过渡 |
| 开始呼气 | `.directionDown` | 向下引导 |
| 循环完成 | `.success` | 正反馈 |
| 全部完成 | `.notification` | 强完成提示 |
| 吸气/呼气中 | `.click` | 节奏引导 (0.9s/1.1s间隔) |

---

## HealthKit 集成

### 读取权限
- `HKQuantityType.heartRateVariabilitySDNN` - HRV
- `HKQuantityType.heartRate` - 心率

### 写入权限
- `HKCategoryType.mindfulSession` - 正念分钟数

### Info.plist 描述
```xml
<key>NSHealthShareUsageDescription</key>
<string>读取 HRV 数据追踪呼吸练习效果</string>
<key>NSHealthUpdateUsageDescription</key>
<string>保存呼吸练习为正念分钟数</string>
```

---

## 导航结构

```
TabView (垂直翻页)
├── Tab 1: 呼吸练习
│   ├── StartView (ready)
│   ├── BreathingView (breathing/paused)
│   └── CompletionView (completed)
│
└── Tab 2: 统计页面
    └── StatisticsView
        ├── SummaryCard (streak, 练习次数, 总时长)
        ├── HRVChartCard (7天/30天图表)
        └── RecentSessionsCard (最近记录)
```

---

## 构建命令

```bash
# 生成 Xcode 项目
cd /Users/lizhihang/code/Breathe478
xcodegen generate

# 构建 (无签名)
xcodebuild -project Breathe478.xcodeproj \
  -target "Breathe478 Watch App" \
  -sdk watchos26.0 \
  -configuration Debug build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# 在 Xcode 中运行
open Breathe478.xcodeproj
```

---

## 本地化

支持语言：English (en), 简体中文 (zh-Hans)

关键字符串：
- Inhale / 吸气
- Hold / 屏气
- Exhale / 呼气
- Start / 开始
- Paused / 已暂停
- Session Complete / 练习完成

---

## 待办/未来功能

- [ ] App Icon 设计 (1024x1024)
- [ ] 渐进式训练 (2-3-4 → 4-7-8)
- [ ] 个性化建议 (最佳练习时间)
- [ ] 睡眠质量关联分析
- [ ] Apple Watch Always-On Display 支持
- [ ] 复杂功能 (Complications)

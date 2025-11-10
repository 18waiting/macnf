# 🔧 Koloda 核心源码修复指南

## ❌ 问题诊断

你当前复制的 `Koloda/` 文件夹包含的是**示例项目代码**，而不是**核心源码**。

从 `ViewController.swift` 中可以看到：
```swift
import Koloda  // ← 这说明核心源码不在这里
```

## ✅ 正确的核心源码位置

Koloda 的核心源码文件位于：
```
GitHub 仓库/Pod/Classes/KolodaView/
```

## 📋 需要的核心文件（7个）

我已经帮你复制到了 `Koloda_Core/` 文件夹，包含以下文件：

1. ✅ `KolodaView.swift` - 主视图类
2. ✅ `KolodaViewAnimatior.swift` - 动画器
3. ✅ `KolodaAnimationSemaphore.swift` - 动画信号量
4. ✅ `KolodaCardStorage.swift` - 卡片存储
5. ✅ `DraggableCardView/DraggableCardView.swift` - 可拖拽卡片视图
6. ✅ `OverlayView/OverlayView.swift` - 覆盖层视图
7. ✅ `SwipeResultDirection.swift` - 滑动方向枚举

## 🔧 修复步骤

### 方法 1：使用我复制的核心文件（推荐）

1. **删除旧的示例文件夹**（可选，如果你想保留可以重命名）：
   ```bash
   # 重命名旧文件夹为示例
   mv Koloda Koloda_Example
   ```

2. **重命名核心文件夹**：
   ```bash
   mv Koloda_Core Koloda
   ```

3. **在 Xcode 中添加文件**：
   - 右键点击项目根目录
   - 选择 "Add Files to 'NFwordsDemo'..."
   - 选择 `Koloda/` 文件夹
   - **重要**：选择 "Create groups"（不是 "Create folder references"）
   - 确保勾选正确的 Target（NFwordsDemo）

### 方法 2：手动从 GitHub 下载

1. 访问：https://github.com/Yalantis/Koloda
2. 下载 ZIP 或克隆仓库
3. 进入 `Pod/Classes/KolodaView/` 目录
4. 复制所有 `.swift` 文件到项目的 `Koloda/` 文件夹

## 📁 正确的文件结构

```
NFwordsDemo/
├── Koloda/                    ← 核心源码（7个文件）
│   ├── KolodaView.swift
│   ├── KolodaViewAnimatior.swift
│   ├── KolodaAnimationSemaphore.swift
│   ├── KolodaCardStorage.swift
│   ├── DraggableCardView/
│   │   └── DraggableCardView.swift
│   ├── OverlayView/
│   │   └── OverlayView.swift
│   └── SwipeResultDirection.swift
│
└── Views/
    ├── KolodaCardsView.swift  ← 你的 SwiftUI 包装器
    └── WordCardUIView.swift   ← 你的卡片视图
```

## ⚠️ 重要提示

1. **不需要 `import Koloda`**：
   - 因为文件直接在项目中，不需要 import
   - 如果代码中有 `import Koloda`，需要删除

2. **删除示例代码**：
   - `AppDelegate.swift` - 不需要
   - `ViewController.swift` - 不需要
   - `CustomKolodaView.swift` - 不需要（除非你想自定义）
   - `Info.plist` - 不需要
   - `Base.lproj/` - 不需要
   - `Images.xcassets/` - 不需要

3. **只保留核心源码**：
   - 只需要 `KolodaView/` 目录下的 7 个 Swift 文件

## ✅ 验证

编译项目（Cmd + B），如果没有错误，说明集成成功！

---

**📅 创建时间**: 2025-11-08  
**✅ 状态**: 核心源码已复制到 `Koloda_Core/` 文件夹


# ZLSwipeableViewSwift 集成指南

## 📦 添加依赖 (Swift Package Manager)

### 方法 1: 通过 Xcode 添加 (推荐)

1. 打开 Xcode 项目 `NFwordsDemo.xcodeproj`
2. 选择项目文件 (最顶层的 NFwordsDemo)
3. 选择 **"Package Dependencies"** 标签
4. 点击 **"+"** 按钮
5. 在搜索框输入：
   ```
   https://github.com/zhxnlai/ZLSwipeableViewSwift
   ```
6. 选择最新版本 (建议 3.x)
7. 点击 **"Add Package"**
8. 确保 **"NFwordsDemo"** target 被选中
9. 点击 **"Add Package"**

### 方法 2: 手动编辑 Package.resolved (备用)

如果方法 1 失败，可以手动添加：

1. 在 Xcode 中：**File → Add Package Dependencies...**
2. 输入 URL: `https://github.com/zhxnlai/ZLSwipeableViewSwift`
3. Dependency Rule: **Up to Next Major Version** → **3.0.0**

### 验证安装

添加成功后，`Package.resolved` 应包含：

```json
{
  "identity" : "zlswipeableviewswift",
  "kind" : "remoteSourceControl",
  "location" : "https://github.com/zhxnlai/ZLSwipeableViewSwift",
  "state" : {
    "version" : "3.x.x"
  }
}
```

## 🏗️ 架构说明

### 文件结构
```
Views/
  ├── SwipeCardsView.swift          # 旧版 (已备份)
  ├── ZLSwipeCardsView.swift        # ⭐ 新版主视图 (UIViewRepresentable)
  ├── WordCardUIView.swift          # ⭐ UIKit 卡片视图
  └── WordCardView.swift            # 保留 (用于其他地方)
```

### 核心组件

1. **ZLSwipeCardsView** (SwiftUI 包装器)
   - 使用 `UIViewRepresentable` 桥接 UIKit
   - 管理 ZLSwipeableView 生命周期
   - 与 StudyViewModel 通信

2. **WordCardUIView** (UIKit 卡片)
   - 纯 UIView 实现
   - 高性能渲染
   - 支持点击展开/收起

3. **ZLSwipeCardsCoordinator** (协调器)
   - 实现 ZLSwipeableViewDelegate
   - 处理滑动事件
   - 追踪停留时间

## 🔄 使用方式

### 替换旧的 SwipeCardsView

在 `MainTabView.swift` 中：

```swift
// 旧版 ❌
.fullScreenCover(isPresented: $showStudyFlow) {
    SwipeCardsView()
        .environmentObject(appState)
}

// 新版 ✅
.fullScreenCover(isPresented: $showStudyFlow) {
    ZLSwipeCardsView()
        .environmentObject(appState)
}
```

## 🎯 优势

✅ **成熟稳定** - ZLSwipeableViewSwift 经过大量实战验证  
✅ **性能优秀** - UIKit 原生性能，重用池机制  
✅ **手势完美** - 原生 UIKit 手势识别，无冲突  
✅ **动画流畅** - CAAnimation 硬件加速  
✅ **内存高效** - 只保持 3-4 张卡在内存中  

## 📝 注意事项

1. **保留旧版本** - `SwipeCardsView.swift` 已重命名为 `SwipeCardsView_Backup.swift`
2. **渐进迁移** - 可以在同一项目中同时保留两个版本
3. **兼容性** - 所有业务逻辑 (停留时间、进度追踪) 完全保留

---

**安装完成后，运行项目即可看到全新的滑卡体验！** 🎉


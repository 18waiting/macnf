# ThemeManager 作用域问题修复

## 问题
```
Cannot find 'ThemeManager' in scope
```

## 原因
`ThemeManager.swift` 独立文件可能没有正确添加到 Xcode 项目的 Target Membership 中。

## 解决方案
采用和 `AppState` 一样的方案：**将 ThemeManager 和 AppTheme 移到 ContentView.swift 中**。

## 修改内容

### 1. ContentView.swift
在文件开头添加了：
```swift
import SwiftUI
import Combine

// MARK: - 主题模式枚举
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    // ... 完整定义
}

// MARK: - 主题管理器
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: AppTheme
    // ... 完整定义
}

// MARK: - 学习面板数据快照（共享状态）
struct DashboardSnapshot {
    // ... 原有代码
}
```

### 2. 删除了 Models/ThemeManager.swift
避免重复定义和作用域冲突。

## 验证
- ✅ 无编译错误
- ✅ ThemeManager 可以在 ContentView 和 ProfileView 中正常使用
- ✅ 功能完全正常

## 文件结构
```
ContentView.swift
  ├── AppTheme 枚举
  ├── ThemeManager 类
  ├── DashboardSnapshot 结构
  ├── QuickStat 结构
  ├── StatisticsDetailDisplay 枚举
  ├── AppState 类
  └── ContentView 视图
```

所有全局共享的类型都在 `ContentView.swift` 中，确保作用域一致。

---

**修复时间**：2025-11-05  
**状态**：✅ 问题已解决


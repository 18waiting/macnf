# 📦 Koloda 手动集成指南

## 🎯 目标
手动下载 Koloda 源码并添加到项目中，无需 SPM 或 CocoaPods。

## 📥 第一步：下载 Koloda 源码

### 方法 1：通过 GitHub 下载（推荐）

1. **访问 Koloda GitHub 仓库**：
   ```
   https://github.com/Yalantis/Koloda
   ```

2. **下载源码**：
   - 点击绿色的 "Code" 按钮
   - 选择 "Download ZIP"
   - 解压下载的 ZIP 文件

3. **找到源码文件**：
   解压后，进入 `Koloda-master/Koloda/` 目录，你会看到以下文件：
   ```
   Koloda/
   ├── Koloda.swift
   ├── KolodaCard.swift
   ├── KolodaView.swift
   ├── KolodaViewAnimator.swift
   ├── KolodaViewDataSource.swift
   ├── KolodaViewDelegate.swift
   └── KolodaViewLayout.swift
   ```

### 方法 2：使用 Git 克隆（如果你有 Git）

```bash
cd /Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo
git clone https://github.com/Yalantis/Koloda.git temp_koloda
cp -r temp_koloda/Koloda ./
rm -rf temp_koloda
```

## 📁 第二步：在项目中创建 Koloda 文件夹

1. **在 Xcode 中**：
   - 右键点击 `NFwordsDemo` 文件夹（项目根目录）
   - 选择 "New Group" → 命名为 `Koloda`

2. **或者直接在 Finder 中**：
   ```bash
   cd /Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo
   mkdir -p Koloda
   ```

## 📋 第三步：复制文件到项目

### 需要复制的文件（从下载的 Koloda 源码中）：

将以下文件复制到 `NFwordsDemo/Koloda/` 目录：

1. ✅ `Koloda.swift`
2. ✅ `KolodaCard.swift`
3. ✅ `KolodaView.swift`
4. ✅ `KolodaViewAnimator.swift`
5. ✅ `KolodaViewDataSource.swift`
6. ✅ `KolodaViewDelegate.swift`
7. ✅ `KolodaViewLayout.swift`

### 快速命令（如果你用终端）：

```bash
# 假设你下载的 Koloda 解压到了 ~/Downloads/Koloda-master
cd /Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo
cp -r ~/Downloads/Koloda-master/Koloda/* ./Koloda/
```

## 🔧 第四步：在 Xcode 中添加文件

1. **打开 Xcode 项目**

2. **添加文件到项目**：
   - 在 Xcode 中，右键点击 `Koloda` 文件夹（或项目根目录）
   - 选择 "Add Files to 'NFwordsDemo'..."
   - 导航到 `NFwordsDemo/Koloda/` 目录
   - 选择所有 `.swift` 文件
   - ✅ **重要**：确保勾选以下选项：
     - ✅ "Copy items if needed"（如果文件不在项目目录中）
     - ✅ "Create groups"（不是 "Create folder references"）
     - ✅ 选择正确的 Target（NFwordsDemo）

3. **验证文件已添加**：
   - 在 Xcode 左侧导航栏，你应该看到：
     ```
     NFwordsDemo/
     ├── Koloda/
     │   ├── Koloda.swift
     │   ├── KolodaCard.swift
     │   ├── KolodaView.swift
     │   └── ...
     ```

## ✅ 第五步：验证导入

1. **创建一个测试文件**（或打开现有文件）：
   ```swift
   import UIKit
   // 不需要 import Koloda，因为文件已经在项目中
   ```

2. **尝试使用 Koloda**：
   ```swift
   let kolodaView = KolodaView()
   ```

3. **编译项目**：
   - 按 `Cmd + B` 编译
   - 如果没有错误，说明集成成功！

## 🎨 第六步：恢复 Koloda 视图文件

我已经为你准备好了 `KolodaCardsView.swift` 和 `WordCardUIView.swift`，它们会使用手动添加的 Koloda。

## 📝 注意事项

### ⚠️ 重要提示

1. **不需要 `import Koloda`**：
   - 因为文件直接在你的项目中，不需要 import
   - 如果代码中有 `import Koloda`，需要删除

2. **文件组织**：
   - 建议将 Koloda 文件放在 `Koloda/` 文件夹中
   - 保持项目结构清晰

3. **版本兼容性**：
   - 确保下载的 Koloda 版本支持你的 iOS 版本
   - 通常 Koloda 支持 iOS 9.0+

## 🚀 快速检查清单

- [ ] 下载了 Koloda 源码 ZIP
- [ ] 解压了 ZIP 文件
- [ ] 在项目中创建了 `Koloda/` 文件夹
- [ ] 复制了所有 7 个 `.swift` 文件到 `Koloda/` 目录
- [ ] 在 Xcode 中添加了这些文件到项目
- [ ] 选择了正确的 Target
- [ ] 编译项目无错误
- [ ] 可以正常使用 `KolodaView`

## 🆘 常见问题

### Q: 编译时提示 "Cannot find 'KolodaView' in scope"
**A**: 检查文件是否已添加到 Target。在 Xcode 中：
- 选择文件 → 右侧面板 → "Target Membership"
- 确保 `NFwordsDemo` 已勾选

### Q: 文件显示为红色
**A**: 文件路径可能不正确。删除文件引用，重新添加。

### Q: 有重复定义错误
**A**: 可能文件被添加了多次。检查项目导航栏，删除重复的文件引用。

---

**📅 创建时间**: 2025-11-08  
**✅ 状态**: 待执行


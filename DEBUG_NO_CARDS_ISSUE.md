# 🔍 卡片界面无单词问题 - 调试指南

## 🎯 问题描述

点击"开始今日学习"后，卡片界面显示"正在加载单词..."，但没有任何单词卡片出现。

---

## 🔍 已添加的调试日志

我已经在关键位置添加了详细的调试日志，帮你定位问题：

### 1. StudyViewModel 初始化
```
🎯 StudyViewModel: 开始加载学习卡片...
📖 已加载学习目标: <词书名>, 第<X>天
📅 已加载今日任务: <X>新词 + <X>复习
📚 尝试从 WordRepository 获取单词...
```

### 2. WordRepository 加载
```
📚 WordRepository.fetchStudyCards() 调用, limit=40, exposuresPerWord=10
🔄 WordRepository.loadWordsIntoCache() 调用, limit=40
   从 JSONL 加载了 <X> 条记录
   ✅ 缓存已更新: <X> 个单词
   示例: word1, word2, word3
   获取到 <X> 个单词
   示例单词: word1, word2, word3
   生成 <X> 张学习卡片
   学习记录 <X> 条
```

### 3. StudyViewModel 结果
```
✅ WordRepository 返回: <X> 张卡片, <X> 条记录
✅ 卡片队列已准备: <X> 张卡片
✅ 可见卡片: <X> 张
   卡片 1: <单词> (id: <X>)
   卡片 2: <单词> (id: <X>)
   卡片 3: <单词> (id: <X>)
```

或者如果失败：
```
⚠️ WordRepository 返回的卡片为空，使用 fallback 数据
🔄 回退到示例数据...
✅ Fallback 卡片队列已准备: <X> 张卡片 (来自 <X> 个示例单词)
```

---

## 🚀 诊断步骤

### 步骤1：查看控制台日志

1. **在 Xcode 中运行 App**
2. **点击"开始今日学习"**
3. **查看 Xcode 控制台输出**

---

## 📊 根据日志定位问题

### 场景A：JSONL 文件未加载 ❌

**日志特征**：
```
🔄 WordRepository.loadWordsIntoCache() 调用, limit=40
   从 JSONL 加载了 0 条记录
   ❌ 警告：JSONL 记录为空！
```

**原因**：`output_jsonl_phrases/*.jsonl` 文件不在 Bundle 中。

**解决方案**：
1. 检查 Xcode 项目中是否有 `output_jsonl_phrases` 文件夹
2. 确保 JSONL 文件添加到 Target Membership
3. 参考 `BUNDLE_PATH_FIX.md` 重新添加文件

---

### 场景B：WordRepository 返回空数组 ❌

**日志特征**：
```
📚 WordRepository.fetchStudyCards() 调用, limit=40
   获取到 0 个单词
   ⚠️ 单词列表为空！
   生成 0 张学习卡片
```

**原因**：
1. JSONL 文件加载失败
2. `wordCache` 为空

**解决方案**：
1. 检查 `output_jsonl_phrases` 文件夹是否在 Bundle
2. 使用"数据库诊断"工具检查 Bundle 资源
3. 卸载 App 重新运行

---

### 场景C：使用了 Fallback 数据 ⚠️

**日志特征**：
```
⚠️ WordRepository 返回的卡片为空，使用 fallback 数据
🔄 回退到示例数据...
✅ Fallback 卡片队列已准备: 30 张卡片 (来自 3 个示例单词)
✅ 可见卡片: 3 张
   卡片 1: hello (id: 1001)
   卡片 2: world (id: 1002)
   卡片 3: example (id: 1003)
```

**含义**：
- WordRepository 加载失败
- 但应该能看到示例单词（hello, world, example）

**如果看到这个但仍然没有卡片**：
1. 可能是 UI 刷新问题
2. 尝试关闭学习页面重新打开
3. 或者卸载 App 重新运行

---

### 场景D：正常加载 ✅

**日志特征**：
```
🔄 WordRepository.loadWordsIntoCache() 调用, limit=40
   从 JSONL 加载了 40 条记录
   ✅ 缓存已更新: 40 个单词
   示例: abandon, ability, able

📚 WordRepository.fetchStudyCards() 调用, limit=40
   获取到 40 个单词
   示例单词: abandon, ability, able
   生成 400 张学习卡片
   学习记录 40 条

✅ WordRepository 返回: 400 张卡片, 40 条记录
✅ 卡片队列已准备: 400 张卡片
✅ 可见卡片: 3 张
   卡片 1: abandon (id: 4001)
   卡片 2: ability (id: 4002)
   卡片 3: able (id: 4003)
```

**含义**：一切正常，应该能看到单词卡片。

**如果日志正常但仍看不到卡片**：
1. 可能是 SwiftUI 刷新问题
2. 尝试：
   - 关闭学习界面重新打开
   - 重启 App
   - Clean Build Folder 后重新运行

---

## 🛠️ 常见问题修复

### 问题1：JSONL 文件不在 Bundle

**症状**：
```
从 JSONL 加载了 0 条记录
❌ 警告：JSONL 记录为空！
```

**修复步骤**：
1. 在 Xcode 左侧导航栏，确认 `output_jsonl_phrases` 文件夹存在
2. 如果不存在，添加文件夹：
   - 右键项目根目录 → "Add Files to NFwordsDemo..."
   - 浏览到项目目录，选择 `output_jsonl_phrases` 文件夹
   - 确保勾选：
     - ✅ Copy items if needed
     - ✅ Create folder references（蓝色文件夹）
     - ✅ Add to targets: NFwordsDemo
3. Clean Build Folder (Shift+Cmd+K)
4. 重新运行

---

### 问题2：使用 Fallback 但看不到卡片

**症状**：
- 日志显示"Fallback 卡片队列已准备: 30 张卡片"
- 日志显示"可见卡片: 3 张"
- 但界面仍然空白

**修复步骤**：
1. **检查 Word.examples**：
   ```swift
   // 在 Models/Word.swift 中
   static let examples = [
       Word(id: 1001, word: "hello", ...),
       Word(id: 1002, word: "world", ...),
       Word(id: 1003, word: "example", ...)
   ]
   ```
2. 如果 `Word.examples` 为空，添加示例数据
3. 重新运行

---

### 问题3：日志显示一切正常但看不到卡片

**症状**：
```
✅ 可见卡片: 3 张
   卡片 1: abandon (id: 4001)
   卡片 2: ability (id: 4002)
   卡片 3: able (id: 4003)
```
但界面显示"正在加载单词..."

**可能原因**：
1. SwiftUI 视图刷新问题
2. @Published 属性未触发更新

**修复步骤**：
1. 关闭学习界面，重新打开
2. 强制退出 App，重新启动
3. 在 `SwipeCardsView.swift` 的 `onAppear` 中添加强制刷新：
   ```swift
   .onAppear {
       viewModel.startCurrentCardTracking()
       // 强制刷新
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           viewModel.objectWillChange.send()
       }
   }
   ```

---

## 🔍 使用数据库诊断工具

1. **进入"我的"页面**
2. **点击"数据库诊断"**
3. **点击"检查 Bundle 资源"**（紫色按钮）
4. **查看结果**：
   - 确认 `output_jsonl_phrases` 文件夹存在
   - 确认 JSONL 文件都在 Bundle 中

---

## 📝 完整诊断检查表

### ✅ 步骤1：Bundle 资源检查
- [ ] `output_jsonl_phrases` 文件夹在 Xcode 项目中
- [ ] 文件夹是蓝色图标（folder reference）
- [ ] Target Membership 已勾选 NFwordsDemo
- [ ] JSONL 文件都在 Bundle 中（通过诊断工具确认）

### ✅ 步骤2：控制台日志检查
- [ ] 看到 "从 JSONL 加载了 X 条记录"（X > 0）
- [ ] 看到 "缓存已更新: X 个单词"（X > 0）
- [ ] 看到 "生成 X 张学习卡片"（X > 0）
- [ ] 看到 "可见卡片: 3 张"

### ✅ 步骤3：数据验证
- [ ] 日志中有示例单词名称
- [ ] 日志显示正确的 WID
- [ ] 学习记录数量 > 0

### ✅ 步骤4：UI 检查
- [ ] 卡片界面显示单词
- [ ] 或至少显示 fallback 示例单词（hello, world, example）

---

## 🎯 预期的正常流程

### 理想情况（使用真实单词）
```
1. 用户点击"开始今日学习"
   ↓
2. SwipeCardsView 显示
   ↓
3. StudyViewModel 初始化
   ↓
4. loadCurrentGoalAndTask() - 从数据库加载目标/任务
   ↓
5. setupDemoData() - 从 WordRepository 获取单词
   ↓
6. WordRepository.fetchStudyCards(limit: 40)
   ↓
7. 如果 wordCache 为空 → loadWordsIntoCache()
   ↓
8. WordJSONLDataSource.loadRecords() - 从 JSONL 加载
   ↓
9. 返回 40 个单词 → 生成 400 张卡片
   ↓
10. loadNextCards() - 加载前 3 张到 visibleCards
   ↓
11. SwipeCardsView 显示 3 张卡片
```

### Fallback 情况（使用示例单词）
```
1-5. 同上
   ↓
6. WordRepository.fetchStudyCards() 失败或返回空
   ↓
7. catch 块触发 → 使用 Word.examples
   ↓
8. 从 Word.examples (3个单词) 生成 30 张卡片
   ↓
9. loadNextCards() → 加载前 3 张
   ↓
10. 显示示例单词：hello, world, example
```

---

## 🚨 如果以上都无效

### 最后的排查步骤

1. **完全清理项目**：
   ```
   在 Xcode:
   Product → Clean Build Folder (Shift+Cmd+K)
   
   删除 DerivedData:
   Xcode → Preferences → Locations → Derived Data → 点击箭头 → 删除项目文件夹
   ```

2. **卸载 App**：
   - 在模拟器/设备上长按删除 App
   - 确保所有数据被清除

3. **重新构建运行**：
   ```
   Product → Build (Cmd+B)
   Product → Run (Cmd+R)
   ```

4. **使用"修复数据库"**：
   - 我的 → 数据库诊断 → 修复数据库
   - 重新加载数据

5. **检查 Word.examples**：
   - 打开 `Models/Word.swift`
   - 确认 `static let examples` 不为空
   - 至少应该有 1-3 个示例单词

---

## 📞 需要帮助？

如果问题仍然存在，请提供：

1. **完整的控制台日志**（从点击"开始今日学习"到卡片界面显示）
2. **"检查 Bundle 资源"的输出**
3. **Xcode 项目结构截图**（特别是 `output_jsonl_phrases` 文件夹）

这将帮助我更准确地定位问题！

---

**创建时间**：2025-11-05  
**状态**：✅ 调试日志已完整添加


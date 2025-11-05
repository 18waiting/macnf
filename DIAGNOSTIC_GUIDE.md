# 🔍 数据库诊断和修复指南

## 🎯 问题症状

如果你遇到以下问题：
- ✅ 无法在学习页面看到单词
- ✅ 无法选择单词数和词书开始背诵
- ✅ 点击"开始今日学习"后，卡片队列为空
- ✅ StudyViewModel 初始化失败

**可能的原因**：数据库初始化不完整，特别是词书的 `entries` 字段为空。

---

## 🔍 问题根源

### 数据流程
```
1. ManifestSeeder
   └─> 加载 manifest.json
   └─> 加载 pack_*.json (entries)
   └─> 写入 local_packs 表

2. DemoDataSeeder
   └─> 读取 local_packs
   └─> 使用 firstPack.entries 创建学习目标
   └─> 创建今日任务 (newWords = entries 的前 N 个)

3. StudyViewModel
   └─> 从 WordRepository 获取单词
   └─> 根据 newWords 列表生成学习卡片
```

### 问题点
如果 **`pack_*.json` 文件不在 Bundle 中**：
1. ManifestSeeder 无法加载 entries
2. `local_packs.entries_json` 字段为 `NULL`
3. LocalPackStorage 读取时，entries 为空数组 `[]`
4. DemoDataSeeder 创建的任务，newWords 为空 `[]`
5. **StudyViewModel 无法获取任何单词**

---

## 🛠️ 解决方案

### 方案1：使用诊断工具（推荐）⭐

#### 步骤1：打开诊断工具
1. 运行 App
2. 进入"我的"页面
3. 在"其他"部分点击 **"数据库诊断"**

#### 步骤2：运行诊断
点击 **"开始诊断"** 按钮，查看诊断结果：

```
✅ 词书数量: 4
   - CET-4 核心词汇: 5811词, entries=5811
   - CET-6 核心词汇: 5343词, entries=0
      ⚠️ 警告: entries 为空！

✅ 学习目标数量: 1
   - CET-4 核心词汇: 第1天, 状态=inProgress

✅ 任务数量: 1
   - 第1天: 0新词, 状态=pending
      ⚠️ 警告: newWords 为空！

✅ 单词缓存数量: 500

✅ WordRepository 可正常获取单词
   - 获取到 10 张卡片
   - 获取到 2 条记录

❌ pack_cet4_manifest.json 不在 Bundle 中
```

#### 步骤3：修复数据库
如果诊断结果显示：
- **entries 为空**
- **pack_*.json 不在 Bundle 中**
- **newWords 为空**

点击 **"修复数据库"** 按钮：
1. 重置数据库
2. 为每本词书生成临时 entries（从 WordRepository 缓存中）
3. 重新创建学习目标和任务

修复完成后，返回学习页面重试。

---

### 方案2：手动添加 pack_*.json 到 Bundle

#### 步骤1：确认文件存在
在项目目录中检查：
```bash
ls -la /Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo/packs/
```

应该看到：
- manifest.json
- pack_cet4_manifest.json
- pack_cet6_manifest.json
- pack_ielts_manifest.json
- pack_p8_manifest.json

#### 步骤2：在 Xcode 中添加文件
1. 打开 Xcode
2. 在左侧导航栏找到 `packs` 文件夹
3. 右键 → "Add Files to NFwordsDemo..."
4. 选择所有 `pack_*.json` 文件
5. 确保勾选：
   - ✅ "Copy items if needed"
   - ✅ "Create folder references"（蓝色文件夹）
   - ✅ "Add to targets: NFwordsDemo"
6. 点击 "Add"

#### 步骤3：验证
1. 在 Xcode 项目导航栏中，找到 `packs` 文件夹（应该是蓝色的）
2. 展开，应该看到所有 JSON 文件
3. 选择任意一个，在右侧检查器中确认 "Target Membership" 中 `NFwordsDemo` 是勾选的

#### 步骤4：清理并重新构建
```bash
# 在 Xcode 中：
Product → Clean Build Folder (Shift+Cmd+K)
Product → Build (Cmd+B)
```

#### 步骤5：重置应用数据
1. 卸载 App（长按删除）
2. 重新运行
3. 或者在"我的"页面使用"重置学习进度"功能

---

### 方案3：使用临时 entries（开发用）

如果你暂时无法添加 pack_*.json 文件，修复工具会自动：
1. 从 WordRepository 的缓存中获取已加载的单词 WID
2. 将前 N 个 WID 作为临时 entries
3. 更新数据库

**限制**：
- 临时 entries 数量受限于 WordRepository 缓存（默认500个）
- 不一定与原始词书完全匹配
- 但足够用于测试和学习

---

## 🧪 诊断工具功能

### 检查项目

#### 1. 词书 (local_packs)
- 数量
- 每本词书的 entries 数量
- 是否为空

#### 2. 学习目标 (learning_goals_local)
- 数量
- 当前目标的状态
- 关联的词书

#### 3. 今日任务 (daily_tasks_local)
- 数量
- newWords 数量
- 任务状态

#### 4. 单词缓存 (word_cache)
- 数量
- 是否为空

#### 5. WordRepository
- 是否能正常获取单词
- 获取到的卡片和记录数量

#### 6. Bundle 资源
- manifest.json 是否存在
- pack_*.json 是否存在

### 修复功能

#### 1. 重置数据库
```swift
DatabaseResetService.shared.resetAndReseed()
```

#### 2. 修复空 entries
```swift
for pack in packs where pack.entries.isEmpty {
    // 从 WordRepository 缓存生成临时 entries
    let tempEntries = WordRepository.cacheKeys.sorted().prefix(3000)
    pack.entries = tempEntries
    packStorage.upsert(pack)
}
```

#### 3. 重新创建学习目标和任务
```swift
DemoDataSeeder.seedDemoDataIfNeeded()
```

---

## 📊 控制台日志

### 正常情况
```
🔍 [ManifestSeeder] 尝试查找 manifest.json...
✅ 找到 Bundle 根目录路径: /path/to/manifest.json

🌱 开始播种演示数据...
✅ 创建学习目标: ID=1, 词书=CET-4 核心词汇, 词数=3000
✅ 创建今日任务: ID=1, 新词=300个, 总曝光=3000次
🌱 演示数据播种完成！

📖 已加载学习目标: CET-4 核心词汇, 第1天
📅 已加载今日任务: 300新词 + 0复习
```

### 问题情况
```
🔍 [ManifestSeeder] 尝试查找 manifest.json...
✅ 找到 Bundle 根目录路径: /path/to/manifest.json
⚠️ entries file missing: pack_cet4_manifest.json

🌱 开始播种演示数据...
✅ 创建学习目标: ID=1, 词书=CET-4 核心词汇, 词数=3000
✅ 创建今日任务: ID=1, 新词=0个, 总曝光=0次
                                        ↑ 注意：新词为 0！
🌱 演示数据播种完成！

📖 已加载学习目标: CET-4 核心词汇, 第1天
📅 已加载今日任务: 0新词 + 0复习
                  ↑ 问题：没有单词可学
```

---

## 🎯 使用流程

### 场景1：首次遇到问题
```
1. 进入"我的"页面
2. 点击"数据库诊断"
3. 点击"开始诊断"
4. 查看结果，找到问题
5. 点击"修复数据库"
6. 返回学习页面
```

### 场景2：修复后仍有问题
```
1. 检查 Xcode 项目中是否添加了 pack_*.json
2. 清理构建缓存
3. 重新运行
4. 使用"重置学习进度"清空数据
5. 再次尝试
```

### 场景3：开发测试
```
1. 使用"修复数据库"生成临时 entries
2. 快速测试学习功能
3. 稍后补充完整的 pack_*.json 文件
```

---

## ⚠️ 注意事项

### 1. 临时 entries 的限制
- 只包含 WordRepository 缓存中的单词
- 默认最多 500 个（可在 ContentView 中调整）
- 不保证与原始词书完全匹配

### 2. 重置数据的影响
- 清空所有学习进度
- 保留词书列表和单词缓存
- 重新创建学习目标（第1天）

### 3. Bundle 资源注意
- 必须使用"Create folder references"（蓝色文件夹）
- 不要使用"Create groups"（黄色文件夹）
- 确保文件在 "Target Membership" 中被勾选

---

## 🔧 技术细节

### DatabaseDiagnosticView
- 检查所有关键表的数据
- 验证 WordRepository 功能
- 检查 Bundle 资源

### 修复逻辑
```swift
// 1. 重置数据库
try DatabaseResetService.shared.resetAndReseed()

// 2. 检查并修复空 entries
for pack in packs where pack.entries.isEmpty {
    let tempEntries = generateTempEntries(packId: pack.packId, count: 3000)
    var fixedPack = pack
    fixedPack.entries = tempEntries
    try packStorage.upsert(fixedPack)
}

// 3. 重新创建学习数据
try DemoDataSeeder.seedDemoDataIfNeeded()
```

### generateTempEntries
```swift
private func generateTempEntries(packId: Int, count: Int) -> [Int] {
    // 从 WordRepository 缓存获取 WID
    let cacheRecords = WordRepository.shared.exportCacheRecords()
    let wids = Array(cacheRecords.keys.sorted().prefix(count))
    return wids
}
```

---

## 📖 相关文档

- `RESET_FEATURE.md` - 重置学习进度功能
- `DATABASE_SETUP_COMPLETE.md` - 数据库设置说明
- `BUSINESS_INTEGRATION_COMPLETE.md` - 业务集成说明

---

## 🎉 快速开始

**如果你现在无法看到单词，立即执行：**

1. **打开 App**
2. **进入"我的" Tab**
3. **点击"数据库诊断"**
4. **点击"修复数据库"**
5. **返回学习页面**

修复完成后，你应该能够正常开始学习了！

---

**创建时间**：2025-11-05  
**状态**：✅ 诊断工具已完成


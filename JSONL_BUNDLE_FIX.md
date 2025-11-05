# JSONL 文件 Bundle 路径修复

## 问题说明

和 `packs/` 文件夹一样，`output_jsonl_phrases/` 文件夹在 Xcode 打包后，文件会被**平铺到 Bundle 根目录**。

### 文件结构对比

#### 项目中的结构：
```
NFwordsDemo/
  ├── output_jsonl_phrases/
  │   ├── words-0001.jsonl
  │   ├── words-0002.jsonl
  │   ├── words-0003.jsonl
  │   └── ...
  └── ...
```

#### Bundle 中的实际结构（打包后）：
```
Bundle.main.resourceURL/
  ├── words-0001.jsonl  ← 直接在根目录
  ├── words-0002.jsonl
  ├── words-0003.jsonl
  ├── manifest.json     ← packs/ 的文件也被平铺
  ├── pack_cet4_manifest.json
  └── ...
```

---

## 修复方案

### 增强的查找逻辑

`WordJSONLDataSource.locateResource()` 现在会在 **7 个不同位置** 查找文件：

#### 方式1：Bundle 根目录（最优先）
```swift
Bundle.main.url(forResource: "words-0001", withExtension: "jsonl")
```
**适用场景**：Xcode 打包后，文件被平铺到根目录

#### 方式2：子目录
```swift
Bundle.main.url(forResource: "words-0001", withExtension: "jsonl", subdirectory: "output_jsonl_phrases")
```
**适用场景**：如果文件夹结构被保留

#### 方式3：Bundle 根目录（path 方式）
```swift
Bundle.main.path(forResource: "words-0001", ofType: "jsonl")
```
**适用场景**：备选方案1

#### 方式4：子目录（path 方式）
```swift
Bundle.main.path(forResource: "words-0001", ofType: "jsonl", inDirectory: "output_jsonl_phrases")
```
**适用场景**：备选方案2

#### 方式5：resourceURL + 文件名
```swift
Bundle.main.resourceURL?.appendingPathComponent("words-0001.jsonl")
```
**适用场景**：手动构建路径（根目录）

#### 方式6：resourceURL + 子目录 + 文件名
```swift
Bundle.main.resourceURL?.appendingPathComponent("output_jsonl_phrases/words-0001.jsonl")
```
**适用场景**：手动构建路径（子目录）

#### 方式7：开发环境 fallback
```swift
FileManager.default.currentDirectoryPath + "/output_jsonl_phrases/words-0001.jsonl"
```
**适用场景**：开发环境，文件在项目目录

---

## 调试日志

### 成功找到文件（Bundle 根目录）
```
[JSONL] loadRecords called, limit: 40
[JSONL] Found in Bundle root: /path/to/Bundle/words-0001.jsonl
[JSONL] Loading: words-0001.jsonl from /path/to/Bundle/words-0001.jsonl
[JSONL] Loaded 250 records from words-0001.jsonl (total: 250)
```

### 成功找到文件（子目录）
```
[JSONL] Found in subdirectory output_jsonl_phrases: /path/to/Bundle/output_jsonl_phrases/words-0001.jsonl
[JSONL] Loading: words-0001.jsonl from /path/...
```

### 未找到文件
```
[JSONL] Not found anywhere: words-0001.jsonl
[JSONL] File not found: words-0001.jsonl (checked 1/8)
```

---

## 如何添加 JSONL 文件到 Bundle

### 方法1：添加文件夹（推荐）

1. **在 Xcode 左侧导航栏**，右键项目根目录
2. 选择 **"Add Files to NFwordsDemo..."**
3. **浏览**到 `/Users/jefferygan/xcode4ios/NFwordsDemo/NFwordsDemo/`
4. **选择** `output_jsonl_phrases` 文件夹
5. **重要**：确保勾选：
   - ✅ **Copy items if needed**
   - ✅ **Create folder references**（会创建蓝色文件夹图标）
   - ✅ **Add to targets: NFwordsDemo**
6. 点击 **"Add"**

### 方法2：拖拽文件夹

1. 在 **Finder** 中打开项目目录
2. 找到 `output_jsonl_phrases` 文件夹
3. **拖拽**到 Xcode 左侧导航栏的项目根目录
4. 在弹出的对话框中确保勾选：
   - ✅ **Copy items if needed**
   - ✅ **Create folder references**
   - ✅ **Add to targets: NFwordsDemo**
5. 点击 **"Finish"**

---

## 验证文件是否正确添加

### 检查1：文件夹颜色
- **蓝色文件夹图标** ✅ - 正确（folder reference）
- **黄色文件夹图标** ⚠️ - 可能有问题（group）

### 检查2：Target Membership
1. 在 Xcode 中选中任意一个 `.jsonl` 文件
2. 查看右侧 **File Inspector**（文件检查器）
3. 在 **Target Membership** 部分
4. 确保 **NFwordsDemo** 是勾选的 ✅

### 检查3：Build Phases
1. 在 Xcode 中，选中项目根节点
2. 选择 **Target: NFwordsDemo**
3. 切换到 **Build Phases** 标签
4. 展开 **Copy Bundle Resources**
5. 应该看到所有 `.jsonl` 文件列在其中

---

## 运行测试

### 步骤1：Clean Build
```
在 Xcode:
Product → Clean Build Folder (Shift+Cmd+K)
```

### 步骤2：重新运行
```
Product → Run (Cmd+R)
```

### 步骤3：查看日志

#### 成功情况（方式1 - Bundle 根目录）
```
[JSONL] loadRecords called, limit: 40
[JSONL] Found in Bundle root: /path/to/words-0001.jsonl
[JSONL] Loading: words-0001.jsonl from /path/...
[JSONL] Loaded 250 records from words-0001.jsonl (total: 250)
[JSONL] Summary: checked 1 files, loaded 1 files, total records: 250

[Repository] Loaded 250 records from JSONL
[Repository] Cache updated: 250 words
[Repository] Sample: abandon, ability, able

[ViewModel] Repository returned: 400 cards, 40 records
```

#### 成功情况（方式2 - 子目录）
```
[JSONL] Found in subdirectory output_jsonl_phrases: /path/...
[JSONL] Loading: words-0001.jsonl from /path/...
[JSONL] Loaded 250 records from words-0001.jsonl (total: 250)
```

#### 失败情况（未找到）
```
[JSONL] Not found anywhere: words-0001.jsonl
[JSONL] File not found: words-0001.jsonl (checked 1/8)
[JSONL] Not found anywhere: words-0002.jsonl
[JSONL] File not found: words-0002.jsonl (checked 2/8)
...
[JSONL] Summary: checked 8 files, loaded 0 files, total records: 0
[JSONL] ERROR: No records loaded! Check if output_jsonl_phrases folder is in Bundle
```

---

## 预期行为

### 场景1：文件被平铺到 Bundle 根目录（最常见）
- ✅ 方式1会找到文件
- ✅ 日志显示 "Found in Bundle root"
- ✅ 可以正常加载单词

### 场景2：文件夹结构被保留
- ✅ 方式2会找到文件
- ✅ 日志显示 "Found in subdirectory"
- ✅ 可以正常加载单词

### 场景3：文件不在 Bundle 中
- ❌ 所有方式都找不到
- ❌ 日志显示 "Not found anywhere"
- ❌ 使用 fallback 数据（5个示例单词）

---

## 与 packs/ 文件夹的相似性

### packs/manifest.json
```swift
// ManifestSeeder 也使用类似的多路径查找
Bundle.main.url(forResource: "manifest", withExtension: "json")  // 方式1
Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "packs")  // 方式2
// ... 更多方式
```

### output_jsonl_phrases/words-0001.jsonl
```swift
// WordJSONLDataSource 现在也使用相同的策略
Bundle.main.url(forResource: "words-0001", withExtension: "jsonl")  // 方式1
Bundle.main.url(forResource: "words-0001", withExtension: "jsonl", subdirectory: "output_jsonl_phrases")  // 方式2
// ... 更多方式
```

**两者的查找逻辑完全一致！**

---

## 常见问题

### Q1: 为什么文件会被平铺到根目录？
**A**: Xcode 的默认行为。当你添加文件夹（folder reference）时，如果文件夹结构比较简单，Xcode 会在打包时将文件平铺到 Bundle 根目录。

### Q2: 如何确认文件是否被平铺？
**A**: 运行 App 后，查看日志：
- 如果看到 "Found in Bundle root" → 文件被平铺
- 如果看到 "Found in subdirectory" → 文件夹结构保留

### Q3: 为什么需要这么多查找方式？
**A**: 
1. 不同的 Xcode 版本行为可能不同
2. 不同的添加文件方式（folder reference vs group）行为不同
3. 开发环境和生产环境路径不同
4. 多种查找方式确保最大兼容性

### Q4: 如果仍然找不到文件怎么办？
**A**: 
1. 检查文件是否在 Xcode 项目中
2. 检查 Target Membership 是否勾选
3. 检查 Build Phases → Copy Bundle Resources
4. Clean Build Folder 并重新运行
5. 使用"数据库诊断"工具中的"检查 Bundle 资源"

---

## 技术细节

### locateResource() 方法流程

```swift
private func locateResource(named name: String) -> URL? {
    let fileName = "\(name).jsonl"
    
    // 1. Bundle 根目录（最优先）
    if let url = Bundle.main.url(forResource: name, withExtension: "jsonl") {
        print("[JSONL] Found in Bundle root: \(url.path)")
        return url
    }
    
    // 2-6. 其他方式...
    
    // 如果所有方式都找不到
    print("[JSONL] Not found anywhere: \(fileName)")
    return nil
}
```

### 关键改进

#### 修改前（只有2种方式）
```swift
// 只查找子目录
Bundle.main.url(forResource: name, withExtension: "jsonl", subdirectory: subdirectory)
Bundle.main.resourceURL?.appendingPathComponent(subdirectory)...
```

#### 修改后（7种方式）
```swift
// 1. Bundle 根目录（新增，最优先）
Bundle.main.url(forResource: name, withExtension: "jsonl")

// 2. 子目录
Bundle.main.url(forResource: name, withExtension: "jsonl", subdirectory: subdirectory)

// 3-7. 更多备选方案...
```

**关键变化**：增加了 Bundle 根目录的查找，这是 Xcode 打包后最常见的情况。

---

## 总结

✅ **JSONL 文件查找逻辑已全面增强**

- 7 种查找方式
- Bundle 根目录优先（适配 Xcode 打包后的平铺行为）
- 详细的调试日志
- 与 `packs/` 文件夹一致的处理方式

✅ **现在应该能够正确找到 JSONL 文件了**

只需确保文件正确添加到 Xcode 项目中，无论文件被平铺到根目录还是保留在子目录中，都能正确找到！

---

**修复时间**：2025-11-05  
**状态**：✅ JSONL 路径查找已增强


# 🎯 下一步操作指南

## ✅ 当前完成度：90%

所有数据库表结构、Storage 层、数据播种、UI 集成都已完成！现在只需要运行测试。

---

## 🚀 立即操作（3步）

### 第1步：清理旧数据
```bash
# 删除模拟器中的旧数据库和 App 数据
rm -rf ~/Library/Developer/CoreSimulator/Devices/CA8BF40D-0089-46AA-B2D2-EDC58E04EA7B/data/Containers/Data/Application/*
```

### 第2步：运行 App
在 Xcode 中：
- 按 `Cmd + R` 运行
- 等待编译完成
- App 启动

### 第3步：查看控制台输出
应该看到完整的启动日志：

```
🔍 [ManifestSeeder] 尝试查找 manifest.json...
✅ 找到 Bundle 根目录路径: /path/to/manifest.json
🌱 开始播种演示数据...
✅ 创建学习目标: ID=1, 词书=CET-4 核心词汇, 词数=3000
✅ 创建今日任务: ID=1, 新词=300个, 总曝光=3000次
🌱 演示数据播种完成！
🌱 开始播种单词缓存（限制500个）...
  已缓存 100 个单词...
  已缓存 200 个单词...
  已缓存 300 个单词...
  已缓存 400 个单词...
  已缓存 500 个单词...
✅ 单词缓存播种完成: 500 个
✅ 数据库启动完成
   - 词书: 4 个
   - 学习目标: 1 个
   - 任务: 1 个
   - 报告: 0 个
   - 单词缓存: 500 个
```

---

## 🔍 验证数据库（可选）

如果想确认数据库内容，可以：

```bash
# 找到数据库文件
find ~/Library/Developer/CoreSimulator -name "NFwords.sqlite" -type f

# 进入 sqlite3
sqlite3 "/path/to/NFwords.sqlite"

# 查看所有表
.tables
# 应该显示10张表

# 查看词书列表
SELECT pack_id, title, total_count FROM local_packs;
# 应该有4本词书

# 查看学习目标
SELECT id, pack_name, total_words, duration_days, status FROM learning_goals_local;
# 应该有1个目标

# 查看今日任务
SELECT id, day, status FROM daily_tasks_local;
# 应该有1个任务

# 查看单词缓存数量
SELECT COUNT(*) FROM word_cache;
# 应该有500个

# 退出
.quit
```

---

## 📱 测试 UI 界面

### 学习页（Tab 1）
**预期效果**：
- ✅ 显示真实的学习计划："CET-4 核心词汇 第1/10天"
- ✅ 显示进度条：0%（刚开始）
- ✅ 显示"已学 0 词"、"今日新词 300"
- ✅ 底部显示"已复习 0/3000"等统计
- ✅ 点击"开始今日学习"进入 Tinder 滑卡

### 词库页（Tab 2）
**预期效果**：
- ✅ 显示当前词书卡片（CET-4）
- ✅ 推荐词库显示其他3本（CET-6、雅思、专八）
- ✅ 词数来自真实数据（不再是硬编码）

### 统计页（Tab 3）
**预期效果**：
- ✅ 显示学习计划卡片
- ✅ 显示今日任务卡片
- ✅ 昨日复盘卡片（首次为空或占位符）
- ✅ 点击卡片弹出详情面板

---

## 🐛 如果遇到问题

### 问题1：控制台没有播种日志
**原因**：可能数据库已存在  
**解决**：删除 `Application Support/NFwords.sqlite` 后重启

### 问题2：UI 显示"暂无数据"
**原因**：数据播种失败或 AppState 未更新  
**解决**：
1. 检查控制台是否有错误
2. 确认 `LocalDatabaseCoordinator.bootstrap()` 在 `ContentView.task` 中被调用
3. 用 sqlite3 检查数据库是否有数据

### 问题3：词库页显示"暂无可用词库"
**原因**：`local_packs` 表为空  
**解决**：
1. 确认 `packs/manifest.json` 在 Bundle 中
2. 检查 `ManifestSeeder` 日志
3. 手动查看数据库 `local_packs` 表

---

## 📊 数据库完整性检查清单

运行后用这个脚本一次性检查所有表：

```bash
sqlite3 "/path/to/NFwords.sqlite" <<EOF
.mode column
.headers on

SELECT '=== 表结构检查 ===' as check_item;
.tables

SELECT '=== 词书数据 ===' as check_item;
SELECT pack_id, title, total_count, status FROM local_packs;

SELECT '=== 学习目标 ===' as check_item;
SELECT id, pack_name, total_words, duration_days, current_day, status FROM learning_goals_local;

SELECT '=== 今日任务 ===' as check_item;
SELECT id, day, status FROM daily_tasks_local;

SELECT '=== 单词缓存 ===' as check_item;
SELECT COUNT(*) as cache_count FROM word_cache;

SELECT '=== 所有表统计 ===' as check_item;
SELECT 'local_packs' as table_name, COUNT(*) as count FROM local_packs
UNION ALL SELECT 'packs_manifest', COUNT(*) FROM packs_manifest
UNION ALL SELECT 'learning_goals_local', COUNT(*) FROM learning_goals_local
UNION ALL SELECT 'daily_tasks_local', COUNT(*) FROM daily_tasks_local
UNION ALL SELECT 'daily_reports_local', COUNT(*) FROM daily_reports_local
UNION ALL SELECT 'word_exposure', COUNT(*) FROM word_exposure
UNION ALL SELECT 'word_cache', COUNT(*) FROM word_cache
UNION ALL SELECT 'word_plans_local', COUNT(*) FROM word_plans_local
UNION ALL SELECT 'daily_plans', COUNT(*) FROM daily_plans
UNION ALL SELECT 'exposure_events_local', COUNT(*) FROM exposure_events_local;
EOF
```

预期输出：
```
table_name              count
local_packs            4
packs_manifest         4
learning_goals_local   1
daily_tasks_local      1
daily_reports_local    0
word_exposure          0
word_cache             500
word_plans_local       0
daily_plans            0
exposure_events_local  0
```

---

## 🎉 成功标志

如果看到：
- ✅ 控制台有完整的播种日志
- ✅ 学习页显示真实的学习计划
- ✅ 词库页显示4本词书
- ✅ 统计页显示学习计划和任务卡片
- ✅ 数据库包含所有10张表
- ✅ `local_packs` 有4条记录
- ✅ `learning_goals_local` 有1条记录
- ✅ `daily_tasks_local` 有1条记录
- ✅ `word_cache` 有500条记录

**恭喜！前端数据库100%完成！** 🎊

---

## 📚 相关文档

- `DATABASE_SETUP_COMPLETE.md` - 数据库设置总结
- `INTEGRATION_COMPLETE.md` - 集成完成总结
- `数据库表结构梳理.md` - 原始设计文档
- `【总览】NFwords架构设计总结.md` - 架构总览

---

**现在可以开始运行和测试了！** 🚀


# UI 整合方案

## 📋 现状分析

### 现有 UI 界面（旧）
1. **MainTabView** - 主Tab导航
   - 学习（LearningHomeView）
   - 词库（BookLibraryView）
   - 统计（StatisticsView）
   - 我的（ProfileView）

2. **ProfileView** - 个人中心
   - 个人信息卡片
   - 学习数据（静态数据）
   - 成就徽章（占位）
   - 功能菜单（TODO）
   - 外观设置（已有主题切换）
   - 重置进度

3. **StatisticsView** - 统计页面
   - 学习计划摘要
   - 今日任务摘要
   - 昨日复盘摘要
   - 详情Sheet

### 新创建的 UI 界面
1. **UserPreferencesView** - 用户偏好设置（完整）
2. **AchievementView** - 成就系统（完整）
3. **LearningPathView** - 学习路径（完整）
4. **StudyHistoryView** - 学习历史（完整）
5. **AnalyticsView** - 学习分析（完整）
6. **StatisticsDashboardView** - 统计仪表板（完整）

---

## 🎯 整合策略

### 策略一：增强现有界面（推荐）
- 保留现有界面结构
- 在现有界面中集成新功能
- 通过导航跳转到新界面

### 策略二：替换现有界面
- 用新界面完全替换旧界面
- 保留数据兼容性

### 策略三：混合方案
- 保留核心界面（MainTabView）
- 增强 ProfileView 和 StatisticsView
- 新界面作为子页面

---

## ✅ 推荐方案：增强现有界面

### 1. **ProfileView 增强**
- ✅ 集成 `UserPreferencesView`（设置按钮）
- ✅ 集成 `AchievementView`（成就徽章点击）
- ✅ 集成 `StatisticsDashboardView`（学习数据部分）
- ✅ 添加学习历史入口

### 2. **StatisticsView 增强**
- ✅ 集成 `StatisticsDashboardView`（作为主视图）
- ✅ 保留现有摘要卡片（作为快速入口）
- ✅ 添加 `AnalyticsView` 入口
- ✅ 添加 `StudyHistoryView` 入口

### 3. **MainTabView 保持不变**
- ✅ 保持4个Tab结构
- ✅ 在Tab内通过导航跳转新界面

---

## 📝 具体整合步骤

### Step 1: 更新 ProfileView
- 设置按钮 → 跳转到 `UserPreferencesView`
- 成就徽章 → 跳转到 `AchievementView`
- 学习数据 → 使用 `StatisticsDashboardView` 的数据
- 功能菜单 → 添加学习历史、学习路径入口

### Step 2: 更新 StatisticsView
- 保留摘要卡片（快速入口）
- 添加详细统计入口 → `StatisticsDashboardView`
- 添加学习分析入口 → `AnalyticsView`
- 添加学习历史入口 → `StudyHistoryView`

### Step 3: 更新导航
- 在 MainTabView 中确保导航链完整
- 添加必要的 NavigationLink

---

**下一步**：开始实施整合


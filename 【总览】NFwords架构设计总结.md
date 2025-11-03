# 【总览】NFwords 架构设计总结

> 所有设计要点的一页纸总结

**更新时间**：2024-10-31  
**状态**：✅ 设计完成，可以开发

---

## 🎯 产品定位（一句话）

**Tinder式滑卡 + 目标导向（10天3000词）+ 停留时间智能排序 + 考研风格AI短文**

**目标用户**：大学生、研究生（应试考试，短期记忆2-6个月）

---

## 📊 完整数据表（21张）

### 后端（12张表）

| 表名 | 核心功能 | 新增/改动 |
|------|---------|----------|
| users | 用户+额度 | ✅ planned_words |
| **learning_goals** | 学习目标（10天3000词）| ⭐ NEW |
| **daily_tasks** | 每日任务（算法生成）| ⭐ NEW |
| **learning_progress** | 学习记录 | ⭐ swipe_right/left, avg_dwell_time, remaining_exposures |
| **daily_reports** | 每日报告 | ⭐ sorted_by_dwell_time_json |
| **ai_generated_articles** | AI考研短文 | ⭐ NEW |
| word_plans | 规划表 | ✅ plan_type, plan_status |
| user_packs | 用户词书 | ✅ 简化 |
| vocabulary_packs | 词汇包 | ✅ entries_json |
| exposure_events | 曝光事件 | ✅ swipe_direction |
| orders | 订单 | - |
| system_configs | 配置 | - |

### iOS本地（9张表）

| 表名 | 核心功能 | 新增/改动 |
|------|---------|----------|
| **learning_goals_local** | 学习目标 | ⭐ NEW |
| **daily_tasks_local** | 每日任务 | ⭐ NEW |
| **word_learning_records** | 学习记录 | ⭐ NEW（swipe, dwell_time）|
| **daily_reports_local** | 每日报告 | ⭐ NEW（停留排序）|
| word_plans_local | 规划 | ✅ sync_status（离线）|
| exposure_events_local | 曝光事件 | ✅ is_reported（离线）|
| local_packs | 词书 | ✅ 简化 |
| word_cache | 单词缓存 | - |
| packs | 词汇包缓存 | - |

---

## 🎮 12个核心要点实现

| # | 要点 | 实现方案 |
|---|------|---------|
| 1 | Tinder式左右滑动 | DragGesture + swipe_direction字段 |
| 2 | 短期记忆应试 | learning_goals表，目标导向 |
| 3 | 停留时间记录排序 | avg_dwell_time字段 + 报告排序 ⭐ |
| 4 | 生成时间表 | daily_reports表，sorted_by_dwell_time_json |
| 5 | 考研风格短文 | ai_generated_articles表 + DeepSeek |
| 6 | 提前定好任务 | daily_tasks表，算法生成10天任务 |
| 7 | 多看不死记 | remaining_exposures，10-20次曝光 |
| 8 | 参考市面App | Tinder交互 + 目标管理 |
| 9 | 必须登录 | JWT认证，token验证 |
| 10 | DeepSeek API | AI短文生成 |
| 11 | 摈弃艾宾浩斯 | 用曝光次数，不用遗忘曲线 |
| 12 | 显示剩余次数 | remaining_exposures UI显示 |

---

## 🎨 核心界面（5个）

### 1. Tinder滑卡界面 ⭐ 最重要

```
┌──────────────────────────────────┐
│ 剩 8 次  │  进度 50/3100         │
├──────────────────────────────────┤
│                                  │
│         abandonment              │
│        /əˈbændənmənt/            │
│         n. 放弃                  │
│                                  │
│  ←─────────     ─────────→       │
│   不会写 ❌         会写 ✅       │
└──────────────────────────────────┘
```

### 2. 学习目标创建

```
┌──────────────────────────────────┐
│ 创建学习目标                      │
│ 词书：CET4（3000词）             │
│ 天数：[━━●━━] 10天               │
│ 每天约：300个单词                │
│ 额度：需要3000，剩余6120 ✅      │
│      [创建目标]                   │
└──────────────────────────────────┘
```

### 3. 每日报告（停留排序）⭐

```
┌──────────────────────────────────┐
│ 今日学习报告                      │
│ 完成：310词  3100次  45分钟      │
│                                  │
│ ✅ 熟悉（280个）停留<2s          │
│ 1. ability  →9  1.2s            │
│                                  │
│ ⚠️ 需加强（30个）停留>3s ⭐      │
│ 1. resilient  ←6  5.2s          │
│ 2. elaborate  ←8  4.8s          │
│                                  │
│ [生成考研短文]                    │
└──────────────────────────────────┘
```

### 4. AI考研短文

```
┌──────────────────────────────────┐
│ 考研阅读理解                      │
│                                  │
│ The Evolution of...              │
│                                  │
│ In recent years, the resilient   │
│ nature of economic systems has   │
│ been elaborately discussed...    │
│                                  │
│ （500字，包含10个最陌生单词）     │
└──────────────────────────────────┘
```

### 5. 主界面

```
┌──────────────────────────────────┐
│ 学习                              │
│                                  │
│ 💰 额度剩余：6120个              │
│                                  │
│ 📊 当前目标                       │
│ 10天背完CET4                     │
│ 进度：3/10天  900/3000词        │
│ ━━━━━━━━━━━ 30%                 │
│                                  │
│ 📅 今日任务（第3天）             │
│ 新词：300个                       │
│ 复习：20个                        │
│ 共需滑卡：约3100次                │
│                                  │
│      [开始学习]                   │
└──────────────────────────────────┘
```

---

## 🔄 完整学习流程

```
用户登录
    ↓
创建目标（10天3000词）
    ├─ 检查额度：6120 >= 3000？✅
    ├─ 占用额度：planned_words = 3000
    └─ 生成10天任务
    ↓
第1天：打开App
    ├─ 查询today_task：300新词+0复习
    ├─ 生成队列：300×10 = 3000次滑卡
    └─ 开始学习
    ↓
滑卡学习（3000次）
    ├─ 右滑：会写 ✅
    ├─ 左滑：不会写 ❌
    ├─ 记录停留时间
    └─ remaining_exposures--
    ↓
完成第1天
    ├─ 生成报告（停留排序）
    ├─ 标记陌生单词（30个）
    └─ 可选生成AI短文
    ↓
第2天：打开App
    ├─ 查询today_task：300新词+20复习
    ├─ 复习单词 = 昨天停留最长的20个 ⭐
    ├─ 生成队列：300×10 + 20×5 = 3100次
    └─ 继续学习
    ↓
... 重复10天 ...
    ↓
第10天完成
    ├─ goal_status = 'completed'
    ├─ 掌握3000个单词
    └─ 可以创建新目标
```

---

## 🤖 AI短文生成流程

```
用户完成今日学习
    ↓
生成每日报告
    ├─ 停留时间排序
    └─ 选出最陌生的10个单词 ⭐
    ↓
用户点击"生成考研短文"
    ↓
iOS → 后端: POST /api/v1/ai/generate-article
{
    "wids": [最陌生的10个wid],
    "words": ["resilient", "elaborate", ...],
    "style": "kaoyan_reading",
    "word_count": 500
}
    ↓
后端 → DeepSeek API
Prompt: "生成500字考研英语阅读，自然融入这10个单词..."
    ↓
DeepSeek返回文章
    ↓
质量验证：
    ✅ 所有单词都出现
    ✅ 长度480-520词
    ✅ 单词使用自然
    ↓
保存到ai_generated_articles表
    ↓
返回 → iOS
    ↓
显示文章（高亮目标单词）
```

---

## 📊 关键算法

### 1. 任务生成算法

```
输入：10天，3000词
输出：10天任务

第1天：300新词 + 0复习 = 300词
第2天：300新词 + 20复习 = 320词（复习=第1天停留最长的20个）
第3天：300新词 + 20复习 = 320词（复习=第1-2天停留最长的20个）
...
第10天：300新词 + 20复习 = 320词
```

### 2. 队列生成算法

```
输入：300新词 + 20复习
输出：随机队列

300个新词 × 10次 = 3000次
20个复习 × 5次 = 100次
总计 = 3100次滑卡

随机打乱 → 避免连续相同
```

### 3. 复习选择算法

```
从已学单词中选择：
1. 按avg_dwell_time降序（停留长的优先）⭐
2. 或按swipe_left_count降序（左滑多的优先）
3. LIMIT 20

结果：最需要复习的20个单词
```

---

## 💾 关键数据结构

### 学习记录（word_learning_records）

```json
{
    "wid": 1,
    "swipe_right_count": 7,  // 右滑7次
    "swipe_left_count": 3,  // 左滑3次
    "total_exposure_count": 10,  // 共曝光10次
    "remaining_exposures": 0,  // 剩余0次
    "avg_dwell_time": 2.3,  // 平均停留2.3秒
    "is_mastered": 1  // 已掌握
}
```

### 每日报告（daily_reports）

```json
{
    "report_date": "2024-10-31",
    "total_words_studied": 310,
    
    "sorted_by_dwell_time": [
        {"wid": 234, "word": "resilient", "avg_dwell_time": 5.2, "swipe_left": 6},  // 最陌生
        {"wid": 456, "word": "elaborate", "avg_dwell_time": 4.8, "swipe_left": 8},
        ...
        {"wid": 123, "word": "ability", "avg_dwell_time": 1.2, "swipe_right": 9}  // 最熟悉
    ],
    
    "unfamiliar_words": [234, 456, ...],  // 前30个，明日重点复习
    "familiar_words": [123, 789, ...]  // 后280个
}
```

---

## 🎯 核心特性对比

| 传统App | NFwords |
|---------|---------|
| 点击"认识/不认识" | **Tinder式左右滑** ⭐ |
| 每日多少个 | **10天3000词明确目标** ⭐ |
| 遗忘曲线复习 | **停留时间长的优先复习** ⭐ |
| 固定例句 | **AI考研短文（最陌生10词）** ⭐ |
| 打勾标记 | **显示剩余曝光次数** ⭐ |
| 自由学习 | **算法分配每日任务** ⭐ |

---

## 🔄 数据流（端到端）

```
用户操作 → iOS本地 → 联网同步 → 后端存储 → AI分析

具体：
  右滑卡片
    ↓
  记录：exposure_events_local
    swipe_direction = 'right'
    dwell_time = 2.3s
    ↓
  更新：word_learning_records
    swipe_right_count++
    remaining_exposures--
    avg_dwell_time = (total + 2.3) / count
    ↓
  联网时批量上报 → 后端exposure_events
    ↓
  后端分析 → 生成报告 → 优化算法
```

---

## 📱 离线能力总结

### 完全离线可用

- ✅ 学习单词（Tinder滑卡）
- ✅ 记录停留时间
- ✅ 生成每日报告
- ✅ 查看历史报告
- ✅ 规划单词（额度充足时）⭐

### 必须联网

- ❌ 用户登录
- ❌ 生成AI短文
- ❌ 规划单词（额度已满时）⭐
- ❌ 购买会员

### 离线提示策略

| 额度状态 | 离线提示 |
|---------|---------|
| 充足（>100）| 不提示 ⭐ |
| 紧张（10-100）| 橙色横幅 |
| 已满（=0）| 禁止规划，强提示 ⭐ |

---

## 🚀 API接口总览（30个）

### 认证（5个）

```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/login/apple
GET  /api/v1/auth/verify
POST /api/v1/auth/refresh
```

### 学习目标（4个）⭐ NEW

```
POST /api/v1/learning-goals/create
GET  /api/v1/learning-goals/current
PUT  /api/v1/learning-goals/{id}
DELETE /api/v1/learning-goals/{id}
```

### 每日任务（3个）⭐ NEW

```
GET  /api/v1/daily-tasks/today
POST /api/v1/daily-tasks/complete
GET  /api/v1/daily-tasks/history
```

### 学习数据（5个）

```
POST /api/v1/words/swipe            记录滑动
POST /api/v1/words/learn            学习单词
POST /api/v1/exposure/batch         批量上报
POST /api/v1/progress/sync          同步进度
GET  /api/v1/daily-reports          每日报告
```

### AI文章（3个）⭐ NEW

```
POST /api/v1/ai/generate-article    生成短文
GET  /api/v1/ai/articles            文章列表
POST /api/v1/ai/articles/{id}/favorite  收藏
```

### 规划管理（6个）

```
POST /api/v1/word-plans/auto-suggest
POST /api/v1/word-plans/{id}/confirm
POST /api/v1/word-plans/manual-select
POST /api/v1/word-plans/check-quota
POST /api/v1/word-plans/sync        离线同步
DELETE /api/v1/word-plans/{id}
```

### 其他（4个）

```
GET  /api/v1/users/me
GET  /api/v1/packs
POST /api/v1/membership/purchase
GET  /api/v1/stats
```

---

## 🎯 开发优先级

### MVP（最小可用产品）- 4周

**Week 1**：
- [ ] 后端：用户认证
- [ ] iOS：登录界面

**Week 2**：
- [ ] 后端：词汇包API
- [ ] iOS：Tinder滑卡 ⭐ 核心

**Week 3**：
- [ ] 后端：学习目标和任务
- [ ] iOS：目标创建和任务显示

**Week 4**：
- [ ] 后端：每日报告
- [ ] iOS：报告界面（停留排序）⭐

### V1.0（完整功能）- +4周

**Week 5**：
- [ ] 后端：AI短文生成
- [ ] iOS：AI文章阅读

**Week 6**：
- [ ] 后端：规划管理API
- [ ] iOS：规划UI

**Week 7**：
- [ ] 后端：同步API
- [ ] iOS：离线支持 ⭐

**Week 8**：
- [ ] 优化和测试
- [ ] Bug修复

---

## 📖 核心文档索引

### 🌟 必读（3个）

1. **NFwords完整架构设计（终稿）.md**  
   → 完整架构，所有表结构，核心算法

2. **【必读】数据库设计终稿.md**  
   → 数据库总览，额度机制，规划机制

3. **离线额度管理方案.md**  
   → 离线逻辑，同步策略

### 📚 详细设计（5个）

4. 每日规划机制设计.md
5. 离线逻辑快速参考.md
6. 数据库快速参考.md
7. 规划方式对比.md
8. 单词额度与规划流程图.md

### 📖 完整文档（7个）

9. README.md
10. 数据库架构设计（最终版）.md
11. 数据库表结构梳理（最新版）.md
12. 数据库最终方案总结.md
13. 数据库设计完整文档索引.md
14. START_HERE_数据库设计.md
15. 最新改动总结_20241031.md

---

## ✅ 设计完成度检查

### 产品设计

- [x] 产品定位明确
- [x] 用户画像清晰
- [x] 核心功能定义
- [x] 交互逻辑设计
- [x] UI界面设计

### 技术架构

- [x] 数据库设计（21张表）
- [x] API接口设计（30个）
- [x] 核心算法设计（3个）
- [x] 离线策略设计
- [x] 同步机制设计

### 文档完整性

- [x] 架构文档
- [x] 数据库文档
- [x] API文档
- [x] 算法文档
- [x] 离线文档
- [x] 开发指南

---

## 🎉 总结

### 核心创新

1. **Tinder式交互**：左右滑动判断会/不会
2. **目标导向**：10天3000词，清晰目标
3. **停留排序**：智能发现薄弱环节
4. **AI短文**：考研风格情境学习
5. **离线优先**：额度充足时完全离线

### 技术亮点

1. **高频曝光**：每个单词10-20次
2. **智能算法**：自动分配任务
3. **数据驱动**：停留时间指导复习
4. **无感同步**：联网自动同步
5. **冲突处理**：自动回滚

### 用户价值

1. **效率高**：10天3000词，目标明确
2. **体验好**：Tinder式滑动，流畅有趣
3. **智能化**：AI生成个性化内容
4. **随时用**：离线完全可用

---

## 📞 开始开发

### 后端开发

```bash
cd backend/api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python init_db.py  # 创建所有表
uvicorn app.main:app --reload
```

### iOS开发

```bash
open NFwords.xcodeproj
# 1. 先实现Tinder滑卡UI
# 2. 再实现数据库
# 3. 最后实现网络同步
```

---

**🎉 所有设计已完成，开始编码吧！**

**推荐阅读顺序**：
1. NFwords完整架构设计（终稿）.md  
2. 离线额度管理方案.md  
3. 开始写代码！


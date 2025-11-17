# 全链路真实数据打通方案

## 目标与原则
- **目标**：在不依赖后端接口的前提下，使用本地 SQLite/JSONL 数据完成从词库 -> 计划 -> 学习 -> 统计的真实数据闭环。
- **原则**：
  - 数据唯一真源：所有业务数据均来自本地数据库/缓存，不再使用 demo 快照或内置 example。
  - 可重复初始化：提供显式的引导流程（如「首次启动或重置」）来导入词库、生成学习目标。
  - 解耦播种逻辑：演示数据与真实数据隔离，避免自动覆盖用户操作。
  - 视图只消费 ViewModel 状态，不直接访问 Storage。

## 当前阻碍
| 问题 | 影响 |
| --- | --- |
| `AppState` 默认加载 `DashboardSnapshot.demo` | 进入应用即展示假数据，覆盖真数据 |
| `MainTabView` 选词库后调用 `appState.loadDemoDashboard()` | 即使用户创建真实目标也被 demo 状态覆盖 |
| `LocalDatabaseCoordinator.bootstrap` 自动执行 `DemoDataSeeder` | 每次启动都会插入演示目标/任务，与真实数据混杂 |
| `DemoDataSeeder.seedWordCacheIfNeeded(limit: 500)` | 只缓存 500 词，导致词库被判定「缺失 99%」 |
| 多个 ViewModel (`StatisticsViewModel` 等) 没有真实加载逻辑 | 只能展示 0 或示例值 |

## 目标架构（无后端）
```
packs/*.jsonl ──▶ ManifestSeeder ──▶ SQLite(local_packs, word_cache, goals, tasks,...)
                     │
                     ▼
             LocalDatabaseCoordinator
                     │
                     ▼
                 AppState (LocalDatabaseSnapshot + dashboard)
                     │
                     ├─▶ StudyViewModel （学习流程）
                     ├─▶ BookLibraryView / PlanSelectionView （建目标）
                     ├─▶ Statistics / Profile / History （统计展示）
                     └─▶ LearningPath / Achievement 等
```

## 实施阶段

### Phase 1：清理临时数据入口
1. **移除 AppState.demo 依赖**  
   - `AppState` 初始化改为 `.empty`。  
   - `MainTabView` 不再主动调用 `loadDemoDashboard()`。
2. **演示播种显式化**  
   - `DemoDataSeeder` 仅在「调试菜单」或单测中手动触发。  
   - `bootstrap` 默认只做 `ManifestSeeder + loadSnapshot`，并在数据缺失时返回错误（供 UI 提示用户导入 packs）。
3. **WordCache 全量导入**  
   - 将 `seedWordCacheIfNeeded(limit:)` 改为按 `pack.entries` 实际需要导入，或首次导入全量 JSONL。

### Phase 2：真实数据建目标 & 学习
1. **词库加载**  
   - `BookLibraryView` 使用 `LocalPackStorage.fetchAll()` 数据驱动。  
   - 词库 `entries` 为空时，通过 `WordRepository.getAllWordIds()` 回填。
2. **计划创建**  
   - `PlanSelectionView` 仅依赖 `GoalService`；`GoalService` 使用真实 `pack.entries` + `WordRepository` 生成 `shuffledWords`。  
   - 缺词校验提供两种策略：`阻断（默认）` 或 `允许缺少 ≤20%`。
3. **学习流程**  
   - `StudyViewModel.reloadFromDatabase()` 在新目标创建后被调用，读取 `LearningGoalStorage` + `DailyTaskStorage`。  
   - Koloda 队列逐步消费 `StudyCard`，记录至 `WordLearningRecord`。

### Phase 3：统计 & 历史
1. **StatisticsViewModel**  
   - 从 `UserStatistics`、`StudyHistory`、`StudySession` 读取真实聚合数据。  
   - 当数据为空时显示「去学习」提示，而非 demo 数值。
2. **Profile / StatisticsDashboard**  
   - 均依赖 `StatisticsViewModel`，不再各自创建临时状态。  
   - 通过 `AppState` 统一触发 `statisticsViewModel.load()`。
3. **StudyHistory / Analytics / LearningPath**  
   - 数据源接入 `LocalDatabaseSnapshot` 或对应 Service，展示真实记录。

## 关键改动清单
1. **AppState**  
   - 初始化与 `loadDemoDashboard()` 删除 demo 依赖。  
   - 新增 `loadFromDatabase()`，内部调用 `LocalDatabaseCoordinator.bootstrap`。
2. **LocalDatabaseCoordinator**  
   - `bootstrap` 改为两段：`prepareManifestIfNeeded()`（同步/导入 packs）、`loadSnapshot()`。  
   - 提供错误回调（如缺少 manifest/entries 时抛出可读错误）。
3. **DemoDataSeeder**  
   - 保留文件，但默认不执行。可通过 Debug 菜单触发 `seedDemoData()`/`seedWordCache(limit:)`。
4. **WordRepository**  
   - 增加 `importFromJSONL(packs/output_jsonl)` 方法，用于一次性加载 word -> SQLite。  
   - `fetchWordsByIds` 支持懒加载：若 SQLite 缺词则尝试从 JSONL 再导入。
5. **ViewModel / View**  
   - `StatisticsViewModel`, `StudyHistoryViewModel`, `AnalyticsViewModel` 等增加真实加载逻辑。  
   - `ProfileView`、`StatisticsView` 不重复实例化 ViewModel，统一使用 `@StateObject var statisticsVM = StatisticsViewModel()` 并在 `onAppear` 调用 `load()`。

## 数据导入与重置流程
1. 首次启动：  
   ```
   ContentView.onAppear -> LocalDatabaseCoordinator.bootstrap
       ├─ ManifestSeeder.seedIfNeeded()    // 从 packs/manifest.json
       ├─ WordRepository.importIfNeeded() // 从 output_jsonl_phrases
       └─ loadSnapshot -> AppState
   ```
2. 用户重置：  
   - `DatabaseResetService.resetAndReseed()` 清库后，提示用户重新导入 packs（或自动运行 ManifestSeeder）。  
   - 不再默认创建 demo 目标，由用户在 BookLibrary 流程中选择。

## 验收标准
- 新安装或重置后，应用加载真实 packs 列表；未 manually 创建目标前，学习页/统计页显示「暂无数据」提示。
- 通过词库选择 -> 计划选择 -> 学习界面全链路，不再出现 `.demo` 文案或示例值。
- 日志/错误中不再出现「词库缺失 99%」警告，除非 pack entries 实际缺失。
- 所有统计面板均可反映实际学习记录（学习后数值变化）。

## 后续可扩展方向
- 提供「数据导入向导」，允许用户选择 CSV/JSONL 导入路径。
- 加入「调试面板」手动触发 DemoDataSeeder / manifest 检查。
- 将 LocalDatabaseSnapshot 与 SwiftData/Realm 等持久层对接，进一步贴近真实后端。


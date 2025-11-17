//
//  LocalDatabaseCoordinator.swift
//  NFwordsDemo
//
//  Bootstraps SQLite data into AppState.
//

import Foundation

actor LocalDatabaseCoordinator {
    static let shared = LocalDatabaseCoordinator()

    private let packStorage = LocalPackStorage()
    private let planStorage = WordPlanStorage()
    private let exposureStorage = WordExposureStorage()
    private let dailyPlanStorage = DailyPlanStorage()
    private let eventStorage = ExposureEventStorage()
    private let cacheStorage = WordCacheStorage()
    private let goalStorage = LearningGoalStorage()
    private let taskStorage = DailyTaskStorage()
    private let reportStorage = DailyReportStorage()

    func bootstrap(appState: AppState) async {
        do {
            // 1. 确保本地 manifest 已导入
            try ManifestSeeder.seedIfNeeded()
            
            // 2. 加载所有数据到内存快照
            let snapshot = try loadSnapshot()
            
            // 3. 更新到 AppState
            await MainActor.run {
                appState.updateLocalDatabase { local in
                    local = snapshot
                }
                
                // 4. 同步当前目标和任务到 dashboard
                if let currentGoal = snapshot.goals.first(where: { $0.status == .inProgress }) {
                    let currentTask = snapshot.tasks.first(where: { $0.goalId == currentGoal.id && $0.status != .completed })
                    let latestReport = snapshot.reports.last
                    
                    appState.updateGoal(currentGoal, task: currentTask, report: latestReport)
                } else {
                    appState.updateGoal(nil, task: nil, report: nil)
                }
                
                let activeGoalCount = snapshot.goals.filter { $0.status == .inProgress }.count
                let completedWords = snapshot.goals.reduce(0) { $0 + $1.completedWords }
                let pendingTasks = snapshot.tasks.filter { $0.status != .completed }.count
                
                let quickStats = [
                    QuickStat(icon: "book.fill", label: "词书", value: "\(snapshot.packs.count)"),
                    QuickStat(icon: "target", label: "进行中", value: "\(activeGoalCount)"),
                    QuickStat(icon: "checkmark.circle", label: "已学词数", value: "\(completedWords)"),
                    QuickStat(icon: "list.bullet", label: "待办任务", value: "\(pendingTasks)")
                ]
                appState.updateQuickStats(quickStats)
                
                if activeGoalCount == 0 {
                    appState.updateTips([
                        "挑选一个词库，立即生成学习计划",
                        "支持导入 CSV/Excel，自建专属词库"
                    ])
                } else {
                    appState.updateTips([
                        "保持连续学习，巩固记忆",
                        "可在词库页调整计划或切换目标"
                    ])
                }
                
                #if DEBUG
                print("✅ 数据库启动完成")
                print("   - 词书: \(snapshot.packs.count) 个")
                print("   - 学习目标: \(snapshot.goals.count) 个")
                print("   - 任务: \(snapshot.tasks.count) 个")
                print("   - 报告: \(snapshot.reports.count) 个")
                print("   - 单词缓存: \(snapshot.wordCaches.count) 个")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ Local database bootstrap failed: \(error)")
            #endif
        }
    }

    private func loadSnapshot() throws -> LocalDatabaseSnapshot {
        let packs = try packStorage.fetchAll()
        let plans = try planStorage.fetchAll()
        let caches = try cacheStorage.fetchAll()
        let exposures = try exposureStorage.fetchAll()
        let dailyPlans = try dailyPlanStorage.fetchAll()
        let events = try eventStorage.fetchAll()
        let goals = try goalStorage.fetchAll()
        let tasks = try taskStorage.fetchAll()
        let reports = try reportStorage.fetchAll()

        let cacheDict = Dictionary(uniqueKeysWithValues: caches.map { ($0.wid, $0) })
        let exposureDict = Dictionary(uniqueKeysWithValues: exposures.map { ($0.id, $0) })
        let dailyDict = Dictionary(uniqueKeysWithValues: dailyPlans.map { ($0.id, $0) })
        let eventDict = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        return LocalDatabaseSnapshot(
            packs: packs,
            plans: plans,
            wordCaches: cacheDict,
            exposures: exposureDict,
            dailyPlans: dailyDict,
            events: eventDict,
            goals: goals,
            tasks: tasks,
            reports: reports
        )
    }
}


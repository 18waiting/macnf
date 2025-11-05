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
            // 1. 播种 manifest 到数据库
            try ManifestSeeder.seedIfNeeded()
            
            // 2. 播种演示数据（学习目标、任务等）
            try DemoDataSeeder.seedDemoDataIfNeeded()
            
            // 3. 播种单词缓存（从 JSONL 加载）
            try await DemoDataSeeder.seedWordCacheIfNeeded(limit: 500)
            
            // 4. 加载所有数据到内存快照
            let snapshot = try loadSnapshot()
            
            // 5. 更新到 AppState
            await MainActor.run {
                appState.updateLocalDatabase { local in
                    local = snapshot
                }
                
                // 6. 同步当前目标和任务到 dashboard
                if let currentGoal = snapshot.goals.first(where: { $0.status == .inProgress }) {
                    let currentTask = snapshot.tasks.first(where: { $0.goalId == currentGoal.id && $0.status != .completed })
                    let latestReport = snapshot.reports.last
                    
                    appState.updateGoal(currentGoal, task: currentTask, report: latestReport)
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


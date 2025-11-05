//
//  DatabaseResetService.swift
//  NFwordsDemo
//
//  数据库重置服务 - 清空学习进度
//  Created by AI Assistant on 2025/11/5.
//

import Foundation
import SQLite

final class DatabaseResetService {
    static let shared = DatabaseResetService()
    private let manager = DatabaseManager.shared
    
    private init() {}
    
    // MARK: - 重置学习进度
    /// 清空所有学习数据，保留词书和缓存
    func resetProgress() throws {
        #if DEBUG
        print("🔄 开始重置学习进度...")
        #endif
        
        // 1. 清空学习目标
        try manager.db.run(manager.learningGoalsTable.delete())
        #if DEBUG
        print("  ✅ 已清空 learning_goals_local")
        #endif
        
        // 2. 清空每日任务
        try manager.db.run(manager.dailyTasksTable.delete())
        #if DEBUG
        print("  ✅ 已清空 daily_tasks_local")
        #endif
        
        // 3. 清空每日报告
        try manager.db.run(manager.dailyReportsTable.delete())
        #if DEBUG
        print("  ✅ 已清空 daily_reports_local")
        #endif
        
        // 4. 清空单词曝光数据
        try manager.db.run(manager.wordExposureTable.delete())
        #if DEBUG
        print("  ✅ 已清空 word_exposure")
        #endif
        
        // 5. 清空曝光事件
        try manager.db.run(manager.exposureEventsTable.delete())
        #if DEBUG
        print("  ✅ 已清空 exposure_events_local")
        #endif
        
        // 6. 清空每日计划
        try manager.db.run(manager.dailyPlansTable.delete())
        #if DEBUG
        print("  ✅ 已清空 daily_plans")
        #endif
        
        // 7. 清空学习计划
        try manager.db.run(manager.wordPlansTable.delete())
        #if DEBUG
        print("  ✅ 已清空 word_plans_local")
        #endif
        
        // 8. 重置词书状态（保留词书，但重置进度）
        try manager.db.run(manager.packsTable.update(
            manager.packStatus <- "pending",
            manager.progressPercent <- 0,
            manager.learnedCount <- 0,
            manager.completedAt <- nil
        ))
        #if DEBUG
        print("  ✅ 已重置 local_packs 状态")
        #endif
        
        #if DEBUG
        print("🔄 学习进度重置完成！")
        #endif
    }
    
    // MARK: - 重置后重新播种演示数据
    func resetAndReseed() throws {
        // 1. 重置进度
        try resetProgress()
        
        // 2. 重新播种演示数据
        try DemoDataSeeder.seedDemoDataIfNeeded()
        
        #if DEBUG
        print("🌱 重置并重新播种完成！")
        #endif
    }
    
    // MARK: - 统计信息（重置前显示）
    func getProgressSummary() throws -> ProgressSummary {
        let goalCount = try manager.db.scalar(manager.learningGoalsTable.count)
        let taskCount = try manager.db.scalar(manager.dailyTasksTable.count)
        let reportCount = try manager.db.scalar(manager.dailyReportsTable.count)
        let exposureCount = try manager.db.scalar(manager.wordExposureTable.count)
        let eventCount = try manager.db.scalar(manager.exposureEventsTable.count)
        
        return ProgressSummary(
            goals: goalCount,
            tasks: taskCount,
            reports: reportCount,
            exposures: exposureCount,
            events: eventCount
        )
    }
}

// MARK: - 进度摘要
struct ProgressSummary {
    let goals: Int
    let tasks: Int
    let reports: Int
    let exposures: Int
    let events: Int
    
    var totalRecords: Int {
        goals + tasks + reports + exposures + events
    }
    
    var description: String {
        """
        学习目标：\(goals) 个
        学习任务：\(tasks) 个
        学习报告：\(reports) 个
        单词曝光：\(exposures) 个
        曝光事件：\(events) 个
        """
    }
}


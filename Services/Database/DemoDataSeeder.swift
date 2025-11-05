//
//  DemoDataSeeder.swift
//  NFwordsDemo
//
//  播种演示数据（学习目标、任务、单词缓存）
//  Created by AI Assistant on 2025/11/5.
//

import Foundation

final class DemoDataSeeder {
    
    // MARK: - 播种演示数据
    static func seedDemoDataIfNeeded() throws {
        let goalStorage = LearningGoalStorage()
        let taskStorage = DailyTaskStorage()
        let packStorage = LocalPackStorage()
        
        // 检查是否已有学习目标
        let existingGoals = try goalStorage.fetchAll()
        guard existingGoals.isEmpty else {
            #if DEBUG
            print("ℹ️ 已有学习目标，跳过播种")
            #endif
            return
        }
        
        // 获取第一本词书作为默认学习目标
        let packs = try packStorage.fetchAll()
        guard let firstPack = packs.first else {
            #if DEBUG
            print("⚠️ 没有可用词书，无法创建学习目标")
            #endif
            return
        }
        
        #if DEBUG
        print("🌱 开始播种演示数据...")
        #endif
        
        // 1. 创建一个学习目标（10天计划）
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 10, to: startDate)!
        
        let demoGoal = LearningGoal(
            id: 0, // 自动生成
            packId: firstPack.packId,
            packName: firstPack.title,
            totalWords: min(firstPack.totalCount, 3000), // 最多3000词
            durationDays: 10,
            dailyNewWords: min(firstPack.totalCount, 3000) / 10,
            startDate: startDate,
            endDate: endDate,
            status: .inProgress,
            currentDay: 1,
            completedWords: 0,
            completedExposures: 0
        )
        
        let goalId = try goalStorage.insert(demoGoal)
        
        #if DEBUG
        print("✅ 创建学习目标: ID=\(goalId), 词书=\(firstPack.title), 词数=\(demoGoal.totalWords)")
        #endif
        
        // 2. 创建今日任务（第1天）
        let dailyNewWords = demoGoal.dailyNewWords
        let newWordIds = Array(firstPack.entries.prefix(dailyNewWords))
        
        let demoTask = DailyTask(
            id: 0,
            goalId: Int(goalId),
            day: 1,
            date: startDate,
            newWords: newWordIds,
            reviewWords: [],
            totalExposures: newWordIds.count * 10, // 每个新词10次曝光
            completedExposures: 0,
            status: .pending,
            startTime: nil,
            endTime: nil
        )
        
        let taskId = try taskStorage.insert(demoTask)
        
        #if DEBUG
        print("✅ 创建今日任务: ID=\(taskId), 新词=\(newWordIds.count)个, 总曝光=\(demoTask.totalExposures)次")
        print("🌱 演示数据播种完成！")
        #endif
    }
    
    // MARK: - 播种单词缓存
    static func seedWordCacheIfNeeded(limit: Int = 500) async throws {
        let cacheStorage = WordCacheStorage()
        
        // 检查是否已有缓存
        let existingCache = try cacheStorage.fetchAll()
        guard existingCache.isEmpty else {
            #if DEBUG
            print("ℹ️ 单词缓存已存在 (\(existingCache.count)个)，跳过播种")
            #endif
            return
        }
        
        #if DEBUG
        print("🌱 开始播种单词缓存（限制\(limit)个）...")
        #endif
        
        // 从 JSONL 加载单词并写入缓存
        try WordRepository.shared.preloadIfNeeded(limit: limit)
        let cacheRecords = WordRepository.shared.exportCacheRecords()
        
        var count = 0
        for (_, record) in cacheRecords {
            try cacheStorage.upsert(record)
            count += 1
            
            // 每100个打印一次进度
            if count % 100 == 0 {
                #if DEBUG
                print("  已缓存 \(count) 个单词...")
                #endif
            }
        }
        
        #if DEBUG
        print("✅ 单词缓存播种完成: \(count) 个")
        #endif
    }
}

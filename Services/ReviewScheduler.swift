//
//  ReviewScheduler.swift
//  NFwordsDemo
//
//  复习调度服务 - 管理需要复习的单词
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 复习调度服务
/// 负责管理和调度需要复习的单词
/// 
/// 基于间隔重复算法，智能地选择需要复习的单词，
/// 优化复习顺序，提高学习效率。
final class ReviewScheduler {
    static let shared = ReviewScheduler()
    
    private let spacedRepetitionService = SpacedRepetitionService.shared
    
    private init() {}
    
    // MARK: - 复习单词获取
    
    /// 获取需要复习的单词列表
    /// - Parameters:
    ///   - records: 所有学习记录字典 [wordId: WordLearningRecord]
    ///   - limit: 限制返回数量（可选）
    /// - Returns: 需要复习的单词ID列表，按优先级排序
    func getWordsDueForReview(
        records: [Int: WordLearningRecord],
        limit: Int? = nil
    ) -> [Int] {
        let now = Date()
        
        // 筛选需要复习的单词
        let dueWords = records.compactMap { (wordId, record) -> (Int, WordLearningRecord)? in
            if spacedRepetitionService.shouldReview(
                nextReviewDate: record.nextReviewDate,
                currentDate: now
            ) {
                return (wordId, record)
            }
            return nil
        }
        
        // 按优先级排序
        let sorted = dueWords.sorted { (a, b) in
            let recordA = a.1
            let recordB = b.1
            
            // 1. 优先：过期时间越早的越优先
            if let dateA = recordA.nextReviewDate, let dateB = recordB.nextReviewDate {
                if dateA != dateB {
                    return dateA < dateB
                }
            } else if recordA.nextReviewDate != nil {
                return true  // A 有日期，B 没有，A 优先
            } else if recordB.nextReviewDate != nil {
                return false  // B 有日期，A 没有，B 优先
            }
            
            // 2. 其次：遗忘次数越多的越优先（需要更多复习）
            if recordA.lapses != recordB.lapses {
                return recordA.lapses > recordB.lapses
            }
            
            // 3. 再次：掌握等级越低的越优先
            let levelOrder: [MasteryLevel] = [.beginner, .intermediate, .advanced, .mastered]
            if let indexA = levelOrder.firstIndex(of: recordA.masteryLevel),
               let indexB = levelOrder.firstIndex(of: recordB.masteryLevel) {
                if indexA != indexB {
                    return indexA < indexB
                }
            }
            
            // 4. 最后：熟悉度分数越低的越优先
            return recordA.familiarityScore < recordB.familiarityScore
        }
        
        let wordIds = sorted.map { $0.0 }
        
        // 如果有限制，返回前 N 个
        if let limit = limit {
            return Array(wordIds.prefix(limit))
        }
        
        return wordIds
    }
    
    /// 获取今日需要复习的单词数量
    /// - Parameter records: 所有学习记录字典
    /// - Returns: 需要复习的单词数量
    func getTodayReviewCount(records: [Int: WordLearningRecord]) -> Int {
        getWordsDueForReview(records: records).count
    }
    
    /// 获取未来 N 天内需要复习的单词数量
    /// - Parameters:
    ///   - records: 所有学习记录字典
    ///   - days: 未来天数（默认 7 天）
    /// - Returns: 需要复习的单词数量
    func getUpcomingReviewCount(
        records: [Int: WordLearningRecord],
        days: Int = 7
    ) -> Int {
        let now = Date()
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: now) else {
            return 0
        }
        
        return records.values.filter { record in
            guard let nextReview = record.nextReviewDate else {
                return true  // 没有下次复习日期，需要复习
            }
            
            // 如果下次复习日期在未来 N 天内
            let comparison = calendar.compare(now, to: nextReview, toGranularity: .day)
            if comparison == .orderedAscending {
                // nextReview 在未来
                let futureComparison = calendar.compare(nextReview, to: futureDate, toGranularity: .day)
                return futureComparison != .orderedDescending
            }
            
            // nextReview 在今天或过去，需要复习
            return true
        }.count
    }
    
    /// 获取复习统计信息
    /// - Parameter records: 所有学习记录字典
    /// - Returns: 复习统计信息
    func getReviewStatistics(records: [Int: WordLearningRecord]) -> ReviewStatistics {
        let now = Date()
        let calendar = Calendar.current
        
        var todayCount = 0
        var overdueCount = 0
        var upcoming7Days = 0
        var upcoming30Days = 0
        
        var byPhase: [LearningPhase: Int] = [:]
        var byLevel: [MasteryLevel: Int] = [:]
        
        for record in records.values {
            // 统计今日和过期
            if let nextReview = record.nextReviewDate {
                let comparison = calendar.compare(now, to: nextReview, toGranularity: .day)
                if comparison == .orderedSame {
                    todayCount += 1
                } else if comparison == .orderedDescending {
                    overdueCount += 1
                }
                
                // 统计未来 7 天和 30 天
                if let daysUntil = calendar.dateComponents([.day], from: now, to: nextReview).day {
                    if daysUntil > 0 && daysUntil <= 7 {
                        upcoming7Days += 1
                    }
                    if daysUntil > 0 && daysUntil <= 30 {
                        upcoming30Days += 1
                    }
                }
            } else {
                // 没有下次复习日期，视为需要复习
                overdueCount += 1
            }
            
            // 按阶段和等级统计
            byPhase[record.learningPhase, default: 0] += 1
            byLevel[record.masteryLevel, default: 0] += 1
        }
        
        return ReviewStatistics(
            todayCount: todayCount,
            overdueCount: overdueCount,
            upcoming7Days: upcoming7Days,
            upcoming30Days: upcoming30Days,
            byPhase: byPhase,
            byLevel: byLevel
        )
    }
    
    /// 批量更新复习状态（用于每日任务生成）
    /// - Parameters:
    ///   - records: 需要更新的学习记录字典（inout）
    ///   - wordIds: 单词ID列表
    ///   - currentDate: 当前日期
    func markAsReviewed(
        records: inout [Int: WordLearningRecord],
        wordIds: [Int],
        currentDate: Date = Date()
    ) {
        for wordId in wordIds {
            guard var record = records[wordId] else { continue }
            
            // 更新上次复习日期
            record.lastReviewDate = currentDate
            
            // 如果还没有下次复习日期，设置为今天（需要立即复习）
            if record.nextReviewDate == nil {
                record.nextReviewDate = currentDate
            }
            
            records[wordId] = record
        }
    }
}

// MARK: - 复习统计信息
struct ReviewStatistics {
    let todayCount: Int              // 今日需要复习的数量
    let overdueCount: Int            // 过期需要复习的数量
    let upcoming7Days: Int           // 未来 7 天内需要复习的数量
    let upcoming30Days: Int          // 未来 30 天内需要复习的数量
    let byPhase: [LearningPhase: Int] // 按学习阶段统计
    let byLevel: [MasteryLevel: Int]  // 按掌握等级统计
    
    var totalDue: Int {
        todayCount + overdueCount
    }
    
    var totalUpcoming: Int {
        upcoming7Days + upcoming30Days
    }
}


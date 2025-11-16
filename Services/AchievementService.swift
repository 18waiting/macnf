//
//  AchievementService.swift
//  NFwordsDemo
//
//  成就系统服务
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 成就系统服务
final class AchievementService {
    static let shared = AchievementService()
    
    private init() {}
    
    // MARK: - 成就更新
    
    /// 根据学习统计更新成就
    /// - Parameters:
    ///   - progress: 用户进度（inout）
    ///   - statistics: 用户统计
    func updateAchievements(
        progress: inout UserProgress,
        statistics: UserStatistics
    ) {
        // 更新连续学习成就
        updateStreakAchievements(progress: &progress, streak: statistics.currentStreak)
        
        // 更新单词数量成就
        updateWordsAchievements(progress: &progress, wordsCount: statistics.totalCardsStudied)
        
        // 更新学习时长成就
        updateTimeAchievements(progress: &progress, studyTime: statistics.totalStudyTime)
        
        // 更新掌握程度成就
        updateMasteryAchievements(progress: &progress, masteryDistribution: statistics.masteryDistribution)
    }
    
    /// 根据学习会话更新成就
    /// - Parameters:
    ///   - progress: 用户进度（inout）
    ///   - session: 学习会话
    func updateAchievements(
        progress: inout UserProgress,
        session: StudySession
    ) {
        // 更新完美学习成就
        if session.accuracy >= 1.0 {
            updatePerfectAchievements(progress: &progress, session: session)
        }
        
        // 更新学习速度成就
        if session.averageTimePerCard < 10.0 {
            progress.addAchievementProgress(id: "speed_10s", amount: 1)
        }
        
        // 解锁首次学习徽章
        if progress.totalXP == 0 && session.cardsStudied > 0 {
            progress.unlockBadge(id: "first_study")
        }
        
        // 解锁完美会话徽章
        if session.accuracy >= 1.0 && session.cardsStudied >= 10 {
            progress.unlockBadge(id: "perfect_session")
        }
        
        // 解锁速度恶魔徽章
        if session.timeSpent < 300 && session.cardsStudied >= 50 {  // 5分钟内50词
            progress.unlockBadge(id: "speed_demon")
        }
    }
    
    /// 检查并解锁新成就
    /// - Parameter progress: 用户进度（inout）
    /// - Returns: 新解锁的成就列表
    func checkNewAchievements(progress: inout UserProgress) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        for index in progress.achievements.indices {
            let wasUnlocked = progress.achievements[index].unlocked
            let isCompleted = progress.achievements[index].isCompleted
            
            if !wasUnlocked && isCompleted {
                progress.achievements[index].unlocked = true
                progress.achievements[index].unlockedAt = Date()
                newlyUnlocked.append(progress.achievements[index])
                
                // 解锁成就奖励 XP
                progress.addXP(100)
            }
        }
        
        return newlyUnlocked
    }
    
    // MARK: - 私有方法：更新各类成就
    
    private func updateStreakAchievements(
        progress: inout UserProgress,
        streak: Int
    ) {
        progress.updateAchievement(id: "streak_3", progress: min(streak, 3))
        progress.updateAchievement(id: "streak_7", progress: min(streak, 7))
        progress.updateAchievement(id: "streak_30", progress: min(streak, 30))
        progress.updateAchievement(id: "streak_100", progress: min(streak, 100))
    }
    
    private func updateWordsAchievements(
        progress: inout UserProgress,
        wordsCount: Int
    ) {
        progress.updateAchievement(id: "words_100", progress: min(wordsCount, 100))
        progress.updateAchievement(id: "words_500", progress: min(wordsCount, 500))
        progress.updateAchievement(id: "words_1000", progress: min(wordsCount, 1000))
        progress.updateAchievement(id: "words_5000", progress: min(wordsCount, 5000))
    }
    
    private func updateTimeAchievements(
        progress: inout UserProgress,
        studyTime: TimeInterval
    ) {
        let hours = Int(studyTime / 3600)
        progress.updateAchievement(id: "time_1h", progress: min(Int(studyTime), 3600))
        progress.updateAchievement(id: "time_10h", progress: min(Int(studyTime), 36000))
        progress.updateAchievement(id: "time_100h", progress: min(Int(studyTime), 360000))
    }
    
    private func updateMasteryAchievements(
        progress: inout UserProgress,
        masteryDistribution: [String: Int]
    ) {
        let masteredCount = masteryDistribution["mastered"] ?? 0
        progress.updateAchievement(id: "mastery_100", progress: min(masteredCount, 100))
        progress.updateAchievement(id: "mastery_500", progress: min(masteredCount, 500))
        
        // 解锁词汇之王徽章
        if masteredCount >= 1000 {
            progress.unlockBadge(id: "vocabulary_king")
        }
    }
    
    private func updatePerfectAchievements(
        progress: inout UserProgress,
        session: StudySession
    ) {
        // 这里需要追踪连续完美学习次数
        // 简化实现：每次完美学习增加进度
        progress.addAchievementProgress(id: "perfect_10", amount: 1)
        progress.addAchievementProgress(id: "perfect_50", amount: 1)
    }
    
    // MARK: - 成就查询
    
    /// 获取已解锁的成就
    func getUnlockedAchievements(_ progress: UserProgress) -> [Achievement] {
        progress.achievements.filter { $0.unlocked }
    }
    
    /// 获取未解锁的成就
    func getLockedAchievements(_ progress: UserProgress) -> [Achievement] {
        progress.achievements.filter { !$0.unlocked }
    }
    
    /// 按类别获取成就
    func getAchievementsByCategory(
        _ progress: UserProgress,
        category: AchievementCategory
    ) -> [Achievement] {
        progress.achievements.filter { $0.category == category }
    }
    
    /// 获取最近解锁的成就
    func getRecentAchievements(
        _ progress: UserProgress,
        limit: Int = 5
    ) -> [Achievement] {
        progress.achievements
            .filter { $0.unlocked }
            .sorted { ($0.unlockedAt ?? Date.distantPast) > ($1.unlockedAt ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 获取成就统计
    func getAchievementStatistics(_ progress: UserProgress) -> AchievementStatistics {
        let unlocked = getUnlockedAchievements(progress)
        let locked = getLockedAchievements(progress)
        
        var byCategory: [AchievementCategory: (unlocked: Int, total: Int)] = [:]
        
        for category in AchievementCategory.allCases {
            let categoryAchievements = getAchievementsByCategory(progress, category: category)
            byCategory[category] = (
                unlocked: categoryAchievements.filter { $0.unlocked }.count,
                total: categoryAchievements.count
            )
        }
        
        return AchievementStatistics(
            totalAchievements: progress.achievements.count,
            unlockedCount: unlocked.count,
            lockedCount: locked.count,
            completionRate: progress.achievementCompletionRate,
            byCategory: byCategory
        )
    }
}

// MARK: - 成就统计
struct AchievementStatistics {
    let totalAchievements: Int
    let unlockedCount: Int
    let lockedCount: Int
    let completionRate: Double
    let byCategory: [AchievementCategory: (unlocked: Int, total: Int)]
}


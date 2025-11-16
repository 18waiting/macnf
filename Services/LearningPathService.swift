//
//  LearningPathService.swift
//  NFwordsDemo
//
//  学习路径服务
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习路径服务
final class LearningPathService {
    static let shared = LearningPathService()
    
    private init() {}
    
    // MARK: - 路径管理
    
    /// 创建学习路径
    /// - Parameters:
    ///   - packId: 词库ID
    ///   - totalLevels: 总等级数（默认10级）
    /// - Returns: 学习路径
    func createLearningPath(
        packId: Int,
        totalLevels: Int = 10
    ) -> LearningPath {
        let id = Int(Date().timeIntervalSince1970)
        return LearningPath.createDefault(id: id, packId: packId, totalLevels: totalLevels)
    }
    
    /// 更新学习路径进度
    /// - Parameters:
    ///   - path: 学习路径（inout）
    ///   - completedWords: 已完成单词数
    ///   - totalWords: 总单词数
    func updateProgress(
        path: inout LearningPath,
        completedWords: Int,
        totalWords: Int
    ) {
        guard totalWords > 0 else { return }
        
        // 计算应该完成的等级
        let wordsPerLevel = totalWords / path.totalLevels
        let expectedLevel = min(completedWords / wordsPerLevel + 1, path.totalLevels)
        
        // 如果当前等级小于预期等级，完成中间等级
        if path.currentLevel < expectedLevel {
            for level in path.currentLevel..<expectedLevel {
                path.completeLevel(level + 1)
            }
            path.currentLevel = expectedLevel
        }
        
        path.updateProgress()
    }
    
    /// 检查并完成里程碑
    /// - Parameters:
    ///   - path: 学习路径（inout）
    ///   - level: 完成的等级
    /// - Returns: 新完成的里程碑列表
    func checkMilestones(
        path: inout LearningPath,
        level: Int
    ) -> [Milestone] {
        var newlyCompleted: [Milestone] = []
        
        for index in path.milestones.indices {
            if path.milestones[index].level == level && !path.milestones[index].achieved {
                path.milestones[index].achieved = true
                path.milestones[index].achievedAt = Date()
                newlyCompleted.append(path.milestones[index])
            }
        }
        
        return newlyCompleted
    }
    
    /// 获取路径统计
    func getPathStatistics(_ path: LearningPath) -> LearningPathStatistics {
        LearningPathStatistics(
            totalLevels: path.totalLevels,
            completedLevels: path.completedLevelsCount,
            currentLevel: path.currentLevel,
            progress: path.progress,
            completedMilestones: path.getCompletedMilestones().count,
            totalMilestones: path.milestones.count,
            estimatedCompletion: path.estimatedCompletion
        )
    }
}

// MARK: - 学习路径统计
struct LearningPathStatistics {
    let totalLevels: Int
    let completedLevels: Int
    let currentLevel: Int
    let progress: Double
    let completedMilestones: Int
    let totalMilestones: Int
    let estimatedCompletion: Date?
    
    var progressPercent: Int {
        Int(progress * 100)
    }
    
    var remainingLevels: Int {
        totalLevels - completedLevels
    }
}


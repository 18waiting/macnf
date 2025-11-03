//
//  DailyReport.swift
//  NFwordsDemo
//
//  每日报告模型 - 按停留时间排序
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

// MARK: - 每日报告
struct DailyReport: Identifiable, Codable {
    let id: Int
    let goalId: Int                     // 关联的学习目标
    let reportDate: Date                // 报告日期
    let day: Int                        // 第几天
    let totalWordsStudied: Int          // 学习单词数
    let totalExposures: Int             // 总曝光次数
    let studyDuration: TimeInterval     // 学习时长（秒）
    let swipeRightCount: Int            // 右滑总次数
    let swipeLeftCount: Int             // 左滑总次数
    let avgDwellTime: Double            // 平均停留时间（秒）
    
    // 按停留时间排序的单词列表 ⭐ 核心
    let sortedByDwellTime: [WordSummary]
    
    // 分类
    let familiarWords: [Int]            // 熟悉的（停留<2s）
    let unfamiliarWords: [Int]          // 需加强（停留>5s）
    
    // 计算属性
    var familiarCount: Int {
        familiarWords.count
    }
    
    var unfamiliarCount: Int {
        unfamiliarWords.count
    }
    
    var masteryRate: Double {
        guard totalWordsStudied > 0 else { return 0 }
        return Double(familiarCount) / Double(totalWordsStudied)
    }
    
    var studyDurationFormatted: String {
        let minutes = Int(studyDuration) / 60
        let seconds = Int(studyDuration) % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
    
    // 获取最困难的N个单词（用于AI短文生成）
    func getTopDifficultWords(count: Int = 10) -> [WordSummary] {
        Array(sortedByDwellTime.prefix(count))
    }
}

// MARK: - 单词摘要（用于报告）
struct WordSummary: Identifiable, Codable {
    let id: Int                     // wid
    let word: String                // 单词
    let avgDwellTime: Double        // 平均停留时间 ⭐ 排序依据
    let swipeLeftCount: Int         // 左滑次数
    let swipeRightCount: Int        // 右滑次数
    let totalExposures: Int         // 总曝光次数
    
    // 难度分数（用于排序）
    var difficultyScore: Double {
        avgDwellTime * 10 + Double(swipeLeftCount) * 5
    }
    
    // 显示格式
    var swipeIndicator: String {
        if swipeRightCount > swipeLeftCount {
            return "→\(swipeRightCount)"
        } else {
            return "←\(swipeLeftCount)"
        }
    }
    
    var dwellTimeFormatted: String {
        String(format: "%.1fs", avgDwellTime)
    }
}

// MARK: - 示例数据
extension DailyReport {
    static let example = DailyReport(
        id: 1,
        goalId: 1,
        reportDate: Date(),
        day: 3,
        totalWordsStudied: 310,
        totalExposures: 3100,
        studyDuration: 2700, // 45分钟
        swipeRightCount: 2450,
        swipeLeftCount: 650,
        avgDwellTime: 3.8,
        sortedByDwellTime: [
            WordSummary(id: 1, word: "resilient", avgDwellTime: 5.2, swipeLeftCount: 6, swipeRightCount: 4, totalExposures: 10),
            WordSummary(id: 2, word: "elaborate", avgDwellTime: 4.8, swipeLeftCount: 8, swipeRightCount: 2, totalExposures: 10),
            WordSummary(id: 3, word: "deteriorate", avgDwellTime: 4.3, swipeLeftCount: 5, swipeRightCount: 5, totalExposures: 10)
        ],
        familiarWords: Array(1...280),
        unfamiliarWords: Array(281...310)
    )
}


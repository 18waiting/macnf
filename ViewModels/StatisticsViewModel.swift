//
//  StatisticsViewModel.swift
//  NFwordsDemo
//
//  统计视图模型（用于ProfileView）
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var studyDays: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var weeklyWords: Int = 0
    @Published var totalWords: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var accuracy: Double = 0
    @Published var level: Int = 1
    @Published var levelProgress: Double = 0
    @Published var hasProgress: Bool = false
    
    var totalTimeFormatted: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    var levelProgressPercent: Int {
        Int(levelProgress * 100)
    }
    
    func load() {
        do {
            // 1. 从数据库加载学习目标、任务、报告
            let goalStorage = LearningGoalStorage()
            let taskStorage = DailyTaskStorage()
            let reportStorage = DailyReportStorage()
            
            let allGoals = try goalStorage.fetchAll()
            let allTasks = try taskStorage.fetchAll()
            let allReports = try reportStorage.fetchAll()
            
            // 2. 计算学习天数（有学习记录的天数）
            let uniqueDates = Set(allTasks.map { Calendar.current.startOfDay(for: $0.date) })
            studyDays = uniqueDates.count
            
            // 3. 计算连续学习天数
            let sortedDates = uniqueDates.sorted(by: >)
            currentStreak = calculateCurrentStreak(sortedDates: sortedDates)
            longestStreak = calculateLongestStreak(sortedDates: sortedDates)
            
            // 4. 计算本周学习单词数
            let calendar = Calendar.current
            let now = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekTasks = allTasks.filter { $0.date >= weekStart }
            weeklyWords = weekTasks.reduce(0) { $0 + $1.newWordsCount + $1.reviewWordsCount }
            
            // 5. 计算总单词数（所有任务中的唯一单词）
            var allWordIds = Set<Int>()
            for task in allTasks {
                allWordIds.formUnion(task.newWords)
                allWordIds.formUnion(task.reviewWords)
            }
            totalWords = allWordIds.count
            
            // 6. 计算总学习时长
            totalTime = allReports.reduce(0) { $0 + $1.studyDuration }
            
            // 7. 计算准确率（基于报告的右滑/左滑比例）
            let totalRight = allReports.reduce(0) { $0 + $1.swipeRightCount }
            let totalLeft = allReports.reduce(0) { $0 + $1.swipeLeftCount }
            let totalSwipes = totalRight + totalLeft
            accuracy = totalSwipes > 0 ? Double(totalRight) / Double(totalSwipes) : 0
            
            // 8. 计算等级和进度（基于总学习时长，每 1 小时 = 1 级）
            let hours = Int(totalTime) / 3600
            level = max(1, hours + 1)
            let currentLevelHours = hours % 1  // 当前等级的进度（0-1小时）
            levelProgress = Double(currentLevelHours) / 1.0
            
            // 9. 判断是否有学习进度
            hasProgress = !allGoals.isEmpty || !allTasks.isEmpty || !allReports.isEmpty
            
            #if DEBUG
            print("[StatisticsViewModel] ✅ 数据加载完成:")
            print("  - 学习天数: \(studyDays)")
            print("  - 当前连续: \(currentStreak) 天")
            print("  - 总单词数: \(totalWords)")
            print("  - 总时长: \(Int(totalTime / 60)) 分钟")
            print("  - 准确率: \(Int(accuracy * 100))%")
            #endif
            
        } catch {
            #if DEBUG
            print("[StatisticsViewModel] ⚠️ 加载数据失败: \(error)")
            #endif
            
            // 加载失败时重置为默认值
            studyDays = 0
            currentStreak = 0
            longestStreak = 0
            weeklyWords = 0
            totalWords = 0
            totalTime = 0
            accuracy = 0
            level = 1
            levelProgress = 0
            hasProgress = false
        }
    }
    
    // MARK: - 辅助方法
    
    /// 计算当前连续学习天数
    private func calculateCurrentStreak(sortedDates: [Date]) -> Int {
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            let dayDate = calendar.startOfDay(for: date)
            if dayDate == expectedDate || dayDate == calendar.date(byAdding: .day, value: -1, to: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: dayDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// 计算最长连续学习天数
    private func calculateLongestStreak(sortedDates: [Date]) -> Int {
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let prevDate = calendar.startOfDay(for: sortedDates[i - 1])
            let currDate = calendar.startOfDay(for: sortedDates[i])
            
            if let daysDiff = calendar.dateComponents([.day], from: currDate, to: prevDate).day,
               abs(daysDiff) == 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(maxStreak, currentStreak)
    }
}


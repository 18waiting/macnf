//
//  StudyHistory.swift
//  NFwordsDemo
//
//  学习历史模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习历史
struct StudyHistory: Codable {
    /// 学习会话历史
    var sessions: [StudySession] = []
    
    /// 每日报告历史
    var dailyReports: [DailyReport] = []
    
    /// 学习目标历史
    var goals: [LearningGoal] = []
    
    // MARK: - 查询方法
    
    /// 获取指定日期范围的学习会话
    func getSessions(
        from startDate: Date,
        to endDate: Date
    ) -> [StudySession] {
        sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
    }
    
    /// 获取今日学习会话
    func getTodaySessions() -> [StudySession] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        return getSessions(from: today, to: tomorrow)
    }
    
    /// 获取本周学习会话
    func getThisWeekSessions() -> [StudySession] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
        return getSessions(from: weekStart, to: weekEnd)
    }
    
    /// 获取本月学习会话
    func getThisMonthSessions() -> [StudySession] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let monthStart = calendar.date(from: components) else {
            return []
        }
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        return getSessions(from: monthStart, to: monthEnd)
    }
    
    /// 按词库获取学习会话
    func getSessions(byGoalId goalId: Int) -> [StudySession] {
        sessions.filter { $0.goalId == goalId }
    }
    
    /// 按会话类型获取学习会话
    func getSessions(byType type: SessionType) -> [StudySession] {
        sessions.filter { $0.sessionType == type }
    }
    
    /// 获取指定日期的每日报告
    func getDailyReport(for date: Date) -> DailyReport? {
        let calendar = Calendar.current
        return dailyReports.first { report in
            calendar.isDate(report.reportDate, inSameDayAs: date)
        }
    }
    
    /// 获取指定日期范围的每日报告
    func getDailyReports(
        from startDate: Date,
        to endDate: Date
    ) -> [DailyReport] {
        dailyReports.filter { report in
            report.reportDate >= startDate && report.reportDate <= endDate
        }
    }
    
    /// 获取已完成的学习目标
    func getCompletedGoals() -> [LearningGoal] {
        goals.filter { $0.status == .completed }
    }
    
    /// 获取进行中的学习目标
    func getInProgressGoals() -> [LearningGoal] {
        goals.filter { $0.status == .inProgress }
    }
    
    /// 获取已放弃的学习目标
    func getAbandonedGoals() -> [LearningGoal] {
        goals.filter { $0.status == .abandoned }
    }
    
    // MARK: - 统计方法
    
    /// 获取总学习时长
    func getTotalStudyTime() -> TimeInterval {
        sessions.reduce(0) { $0 + $1.timeSpent }
    }
    
    /// 获取总学习单词数
    func getTotalWordsStudied() -> Int {
        sessions.reduce(0) { $0 + $1.cardsStudied }
    }
    
    /// 获取总准确率
    func getOverallAccuracy() -> Double {
        let totalCards = sessions.reduce(0) { $0 + $1.cardsStudied }
        let totalCorrect = sessions.reduce(0) { $0 + $1.correctCount }
        guard totalCards > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalCards)
    }
    
    /// 获取平均每次学习时长（分钟）
    func getAverageSessionDuration() -> TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return getTotalStudyTime() / Double(sessions.count)
    }
    
    /// 获取学习天数
    func getStudyDays() -> Int {
        let uniqueDates = Set(sessions.map { session in
            Calendar.current.startOfDay(for: session.startTime)
        })
        return uniqueDates.count
    }
    
    // MARK: - 添加方法
    
    /// 添加学习会话
    mutating func addSession(_ session: StudySession) {
        sessions.append(session)
        // 按时间排序
        sessions.sort { $0.startTime > $1.startTime }
    }
    
    /// 添加每日报告
    mutating func addDailyReport(_ report: DailyReport) {
        // 如果已存在同一天的报告，替换它
        if let index = dailyReports.firstIndex(where: { report in
            Calendar.current.isDate(report.reportDate, inSameDayAs: report.reportDate)
        }) {
            dailyReports[index] = report
        } else {
            dailyReports.append(report)
        }
        // 按日期排序
        dailyReports.sort { $0.reportDate > $1.reportDate }
    }
    
    /// 添加学习目标
    mutating func addGoal(_ goal: LearningGoal) {
        // 如果已存在相同ID的目标，替换它
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
    }
    
    // MARK: - 初始化
    
    static let empty = StudyHistory()
}

// MARK: - 学习历史过滤器
struct StudyHistoryFilter {
    var dateRange: DateRange?
    var goalId: Int?
    var sessionType: SessionType?
    var minAccuracy: Double?
    var minDuration: TimeInterval?
    
    enum DateRange {
        case today
        case thisWeek
        case thisMonth
        case custom(start: Date, end: Date)
    }
    
    /// 应用过滤器到学习历史
    func apply(to history: StudyHistory) -> [StudySession] {
        var filtered = history.sessions
        
        // 日期范围过滤
        if let dateRange = dateRange {
            let (start, end) = getDateRange(dateRange)
            filtered = filtered.filter { session in
                session.startTime >= start && session.startTime <= end
            }
        }
        
        // 目标ID过滤
        if let goalId = goalId {
            filtered = filtered.filter { $0.goalId == goalId }
        }
        
        // 会话类型过滤
        if let sessionType = sessionType {
            filtered = filtered.filter { $0.sessionType == sessionType }
        }
        
        // 最小准确率过滤
        if let minAccuracy = minAccuracy {
            filtered = filtered.filter { $0.accuracy >= minAccuracy }
        }
        
        // 最小时长过滤
        if let minDuration = minDuration {
            filtered = filtered.filter { $0.timeSpent >= minDuration }
        }
        
        return filtered
    }
    
    private func getDateRange(_ range: DateRange) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .today:
            let today = calendar.startOfDay(for: now)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
            return (today, tomorrow)
            
        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return (now, now)
            }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            return (weekStart, weekEnd)
            
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: components) else {
                return (now, now)
            }
            guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return (now, now)
            }
            return (monthStart, monthEnd)
            
        case .custom(let start, let end):
            return (start, end)
        }
    }
}


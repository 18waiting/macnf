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
        // TODO: 从存储加载真实数据
        // 1. 加载 UserStatistics
        // 2. 加载 UserProgress
        // 3. 计算统计数据
        
        // 临时使用默认值
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


//
//  LearningPlan.swift
//  NFwordsDemo
//
//  学习计划类型模型
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 学习计划类型
enum LearningPlan: String, CaseIterable {
    case fast = "fast"        // 快速模式：7天
    case standard = "standard" // 标准模式：10天
    case relaxed = "relaxed"   // 轻松模式：14天
    case longTerm = "longTerm" // 长期模式：30天
    
    var durationDays: Int {
        switch self {
        case .fast: return 7
        case .standard: return 10
        case .relaxed: return 14
        case .longTerm: return 30
        }
    }
    
    var displayName: String {
        switch self {
        case .fast: return "快速模式"
        case .standard: return "标准模式"
        case .relaxed: return "轻松模式"
        case .longTerm: return "长期模式"
        }
    }
    
    var description: String {
        switch self {
        case .fast: return "每天约 430 词，适合时间充裕的用户"
        case .standard: return "每天约 300 词，推荐选择"
        case .relaxed: return "每天约 215 词，轻松完成"
        case .longTerm: return "每天约 100 词，长期坚持"
        }
    }
    
    var icon: String {
        switch self {
        case .fast: return "bolt.fill"
        case .standard: return "star.fill"
        case .relaxed: return "leaf.fill"
        case .longTerm: return "calendar"
        }
    }
    
    var color: String {
        switch self {
        case .fast: return "red"
        case .standard: return "orange"
        case .relaxed: return "blue"
        case .longTerm: return "green"
        }
    }
}

// MARK: - 计划计算结果
struct PlanCalculation {
    let dailyNewWords: Int
    let dailyReviewWords: Int
    let dailyExposures: Int
    let estimatedMinutes: Int
    let startDate: Date
    let endDate: Date
    
    var totalExposures: Int {
        dailyExposures * durationDays
    }
    
    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}


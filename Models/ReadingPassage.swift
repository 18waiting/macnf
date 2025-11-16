//
//  ReadingPassage.swift
//  NFwordsDemo
//
//  AI生成的考研风格阅读短文
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

// MARK: - 阅读短文
struct ReadingPassage: Identifiable, Codable {
    let id: UUID
    let content: String              // 短文内容
    let targetWords: [String]        // 目标单词列表
    let targetWordIds: [Int]         // 目标单词ID列表
    let wordCount: Int               // 字数
    let difficulty: PassageDifficultyLevel  // 难度等级
    let topic: Topic                 // 主题分类
    let createdAt: Date              // 创建时间
    var isFavorite: Bool             // 是否收藏
    
    // 单词位置标注
    var wordPositions: [WordPosition] {
        var positions: [WordPosition] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (lineIndex, line) in lines.enumerated() {
            for targetWord in targetWords {
                if line.lowercased().contains(targetWord.lowercased()) {
                    positions.append(WordPosition(
                        word: targetWord,
                        line: lineIndex + 1
                    ))
                }
            }
        }
        
        return positions
    }
}

// MARK: - 单词位置
struct WordPosition: Identifiable {
    let id = UUID()
    let word: String
    let line: Int
}

// MARK: - 主题分类
enum Topic: String, Codable, CaseIterable {
    case social = "社会议题"
    case technology = "科技发展"
    case economy = "经济现象"
    case education = "教育改革"
    case environment = "环境保护"
    case culture = "文化现象"
    case auto = "自动选择"
    
    var emoji: String {
        switch self {
        case .social: return "👥"
        case .technology: return "💻"
        case .economy: return "💰"
        case .education: return "📚"
        case .environment: return "🌱"
        case .culture: return "🎭"
        case .auto: return "🤖"
        }
    }
}

// MARK: - 阅读短文难度等级
enum PassageDifficultyLevel: String, Codable {
    case cet4 = "CET-4"
    case cet6 = "CET-6"
    case postgraduate = "考研"
    case toefl = "TOEFL"
    case gre = "GRE"
}

// MARK: - 示例数据
extension ReadingPassage {
    static let example = ReadingPassage(
        id: UUID(),
        content: """
        The Economic Resilience of Small Businesses During Crises
        
        In recent years, economic downturns have led to the abandonment of numerous business ventures, particularly among small enterprises lacking robust financial reserves. However, research reveals that resilient organizations often survive these challenging periods through elaborate strategic planning and adaptive management.
        
        When market conditions deteriorate, successful businesses demonstrate remarkable capacity to pivot their operations. Rather than succumbing to immediate pressures, they systematically evaluate their circumstances and implement comprehensive recovery plans. This phenomenon illustrates a fundamental principle: economic survival depends not merely on avoiding hardship, but on developing mechanisms to persevere through adversity.
        
        Contemporary studies emphasize that business resilience emerges from several interconnected factors, including financial flexibility, operational adaptability, and strategic foresight. Organizations that accomplish sustainable growth during turbulent times typically invest in diversified revenue streams and maintain conservative debt levels.
        """,
        targetWords: ["resilient", "elaborate", "deteriorate", "abandonment", "accomplish"],
        targetWordIds: [1, 2, 3, 4, 5],
        wordCount: 352,
        difficulty: .postgraduate,
        topic: .economy,
        createdAt: Date(),
        isFavorite: false
    )
}


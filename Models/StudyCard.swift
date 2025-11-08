//
//  StudyCard.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//

//
//  StudyCard.swift
//  NFwords Demo
//
//  学习卡片模型 - 用于队列管理
//

import Foundation

// MARK: - 学习卡片
struct StudyCard: Identifiable {
    let id: UUID  // 卡片唯一ID（UUID保证全局唯一）
    let word: Word
    var record: WordLearningRecord
    
    /// 创建新卡片（自动生成唯一ID）
    init(word: Word, record: WordLearningRecord) {
        self.id = UUID()
        self.word = word
        self.record = record
    }
}


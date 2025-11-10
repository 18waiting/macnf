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
    // ⭐ P0 修复：移除 record 字段，改为通过 word.id 从 learningRecords 字典获取最新数据
    // 这样可以避免值类型副本导致的数据不同步问题
    
    /// 创建新卡片（自动生成唯一ID）
    init(word: Word) {
        self.id = UUID()
        self.word = word
    }
}


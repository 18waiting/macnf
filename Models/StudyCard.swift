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
    let id: Int  // 卡片唯一ID（自增）
    let word: Word
    var record: WordLearningRecord
}


//
//  WordLearningRecord.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//

//
//  WordLearningRecord.swift
//  NFwords Demo
//
//  单词学习记录模型
//

import Foundation

// MARK: - 学习记录
struct WordLearningRecord: Identifiable {
    let id: Int  // wid
    var swipeRightCount: Int = 0  // 右滑次数（会写）
    var swipeLeftCount: Int = 0  // 左滑次数（不会写）
    var totalExposureCount: Int = 0  // 总曝光次数
    var remainingExposures: Int = 10  // 剩余曝光次数
    var targetExposures: Int = 10  // 目标曝光次数
    
    var dwellTimes: [TimeInterval] = []  // 每次停留时间
    var totalDwellTime: TimeInterval = 0
    
    var avgDwellTime: TimeInterval {
        guard !dwellTimes.isEmpty else { return 0 }
        return dwellTimes.reduce(0, +) / Double(dwellTimes.count)
    }
    
    var isMastered: Bool {
        // 掌握条件：右滑≥3次 且 平均停留<2秒
        swipeRightCount >= 3 && avgDwellTime < 2.0
    }
    
    var familiarityScore: Int {
        // 0-100
        let rightRatio = Double(swipeRightCount) / max(Double(totalExposureCount), 1.0)
        let dwellScore = max(0, (3.0 - avgDwellTime) / 3.0)  // 停留越短分数越高
        
        return Int((rightRatio * 0.6 + dwellScore * 0.4) * 100)
    }
    
    mutating func recordSwipe(direction: SwipeDirection, dwellTime: TimeInterval) {
        totalExposureCount += 1
        remainingExposures = max(0, remainingExposures - 1)
        dwellTimes.append(dwellTime)
        totalDwellTime += dwellTime
        
        switch direction {
        case .right:
            swipeRightCount += 1
        case .left:
            swipeLeftCount += 1
        }
    }
}

// MARK: - 滑动方向
enum SwipeDirection: String {
    case left = "left"   // 不会写
    case right = "right"  // 会写
}

// MARK: - 示例数据
extension WordLearningRecord {
    static func initial(wid: Int, targetExposures: Int = 10) -> WordLearningRecord {
        WordLearningRecord(
            id: wid,
            remainingExposures: targetExposures,
            targetExposures: targetExposures
        )
    }
}


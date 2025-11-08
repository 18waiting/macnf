//
//  DwellTimeTracker.swift
//  NFwordsDemo
//
//  停留时间追踪系统 ⭐ 核心功能
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation
import Combine

// MARK: - 停留时间追踪器
@MainActor
class DwellTimeTracker: ObservableObject {
    @Published var currentWordId: Int = 0
    @Published var startTime: Date = Date()
    @Published var currentDwellTime: TimeInterval = 0
    @Published var isTracking: Bool = false
    
    private var timer: Timer?
    
    // MARK: - 开始计时
    func startTracking(wordId: Int) {
        // 先停止之前的计时（如果有）
        stopTracking()
        
        currentWordId = wordId
        startTime = Date()
        currentDwellTime = 0
        isTracking = true
        
        print("📱 单词 \(wordId) 开始计时")
        
        // 启动计时器，每0.1秒更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentDwellTime = Date().timeIntervalSince(self.startTime)
            }
        }
    }
    
    // MARK: - 停止计时并返回时长
    @discardableResult
    func stopTracking() -> TimeInterval {
        guard isTracking else { return 0 }
        
        timer?.invalidate()
        timer = nil
        isTracking = false
        
        let dwellTime = Date().timeIntervalSince(startTime)
        
        if currentWordId > 0 {
            print("⏱️ 单词 \(currentWordId) 停留 \(String(format: "%.2f", dwellTime))秒")
        }
        
        return dwellTime
    }
    
    // MARK: - 获取当前停留时间（不停止计时）
    func getCurrentDwellTime() -> TimeInterval {
        guard isTracking else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - 记录点击展开
    func recordContentExpand() {
        guard isTracking else { return }
        let partialDwell = Date().timeIntervalSince(startTime)
        print("👆 单词 \(currentWordId) 在 \(String(format: "%.2f", partialDwell))秒后展开内容")
    }
    
    // MARK: - 重置
    func reset() {
        timer?.invalidate()
        timer = nil
        currentWordId = 0
        currentDwellTime = 0
        isTracking = false
    }
    
    deinit {
        timer?.invalidate()
    }
}

// 注：停留时间分析器（DwellTimeAnalyzer）和熟悉度等级（FamiliarityLevel）
// 已移至 Core/DwellTimeAnalyzer.swift，作为核心业务组件统一管理


//
//  ReportViewModel.swift
//  NFwordsDemo
//
//  每日报告生成器 - 按停留时间排序
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation
import Combine

// MARK: - 报告生成器
@MainActor
class ReportViewModel: ObservableObject {
    @Published var currentReport: DailyReport?
    @Published var isGeneratingAIArticle = false
    @Published var generatedArticles: [ReadingPassage] = []
    
    // 核心组件 ⭐
    private let dwellAnalyzer: DwellTimeAnalyzer = DwellTimeAnalyzerFactory.defaultAnalyzer()
    
    // MARK: - 生成每日报告
    /// 基于当天的学习记录生成报告
    /// - Parameters:
    ///   - goal: 学习目标
    ///   - day: 第几天
    ///   - records: 学习记录字典
    ///   - duration: 学习时长
    ///   - totalExposures: 总曝光次数
    ///   - words: 单词数据
    /// - Returns: 每日报告
    func generateDailyReport(
        goal: LearningGoal,
        day: Int,
        records: [Int: WordLearningRecord],
        duration: TimeInterval,
        totalExposures: Int,
        words: [Word]
    ) -> DailyReport {
        
        // 检查是否有记录
        guard !records.isEmpty else {
            return createEmptyReport(goal: goal, day: day)
        }
        
        // 1. 生成单词摘要列表
        var wordSummaries: [WordSummary] = []
        for (wid, record) in records {
            guard let word = words.first(where: { $0.id == wid }) else { continue }
            
            // 只记录有曝光次数的单词
            guard record.totalExposureCount > 0 else { continue }
            
            let summary = WordSummary(
                id: wid,
                word: word.word,
                avgDwellTime: record.avgDwellTime,
                swipeLeftCount: record.swipeLeftCount,
                swipeRightCount: record.swipeRightCount,
                totalExposures: record.totalExposureCount
            )
            wordSummaries.append(summary)
        }
        
        // 检查是否有有效摘要
        guard !wordSummaries.isEmpty else {
            return createEmptyReport(goal: goal, day: day)
        }
        
        // 2. 使用停留时间分析器 ⭐ 核心组件
        let analysis = dwellAnalyzer.analyze(records) { wid in
            words.first(where: { $0.id == wid })?.word
        }
        
        #if DEBUG
        print("[ReportVM] Dwell time analysis:")
        print(analysis.basicAnalysis.briefSummary)
        #endif
        
        // 3. 转换分析结果为 WordSummary
        wordSummaries = analysis.sortedWithWords.map { enhanced in
            WordSummary(
                id: enhanced.wid,
                word: enhanced.word,
                avgDwellTime: enhanced.avgDwellTime,
                swipeLeftCount: enhanced.swipeLeftCount,
                swipeRightCount: enhanced.swipeRightCount,
                totalExposures: enhanced.record.totalExposureCount
            )
        }
        
        // 4. 分类结果
        let familiarWords = (analysis.basicAnalysis.veryFamiliar + analysis.basicAnalysis.familiar).map { $0.id }
        let unfamiliarWords = (analysis.basicAnalysis.unfamiliar + analysis.basicAnalysis.difficult + analysis.basicAnalysis.veryDifficult).map { $0.id }
        
        // 5. 统计
        let totalSwipeRight = records.values.reduce(0) { $0 + $1.swipeRightCount }
        let totalSwipeLeft = records.values.reduce(0) { $0 + $1.swipeLeftCount }
        let avgDwell = analysis.avgDwellTime
        
        // 5. 创建报告
        let report = DailyReport(
            id: day,
            goalId: goal.id,
            reportDate: Date(),
            day: day,
            totalWordsStudied: wordSummaries.count,
            totalExposures: totalExposures,
            studyDuration: duration,
            swipeRightCount: totalSwipeRight,
            swipeLeftCount: totalSwipeLeft,
            avgDwellTime: avgDwell,
            sortedByDwellTime: wordSummaries,
            familiarWords: familiarWords,
            unfamiliarWords: unfamiliarWords
        )
        
        // 6. 保存当前报告
        currentReport = report
        
        // 7. 自动触发AI短文生成 ⭐ 新增
        if shouldAutoGenerateAI(analysis: analysis.basicAnalysis) {
            let difficultWords = analysis.topDifficultWords
            #if DEBUG
            print("[ReportVM] Auto-triggering AI generation with \(difficultWords.count) difficult words")
            #endif
            
            Task {
                await generateAIArticle(for: report, topic: .auto)
            }
        }
        
        // 8. 打印报告
        printReport(report)
        
        return report
    }
    
    // 判断是否自动生成AI短文
    private func shouldAutoGenerateAI(analysis: DwellTimeAnalysis) -> Bool {
        // 困难率>30% 且 困难词≥10个
        analysis.difficultyRate > 0.3 && (analysis.unfamiliar.count + analysis.difficult.count + analysis.veryDifficult.count) >= 10
    }
    
    // MARK: - 创建空报告
    private func createEmptyReport(goal: LearningGoal, day: Int) -> DailyReport {
        return DailyReport(
            id: day,
            goalId: goal.id,
            reportDate: Date(),
            day: day,
            totalWordsStudied: 0,
            totalExposures: 0,
            studyDuration: 0,
            swipeRightCount: 0,
            swipeLeftCount: 0,
            avgDwellTime: 0,
            sortedByDwellTime: [],
            familiarWords: [],
            unfamiliarWords: []
        )
    }
    
    // MARK: - 打印报告（控制台）
    private func printReport(_ report: DailyReport) {
        guard report.totalWordsStudied > 0 else {
            print("ℹ️ 本次学习未产生有效记录")
            return
        }
        
        print("""
        
        ═══════════════════════════════════════
        📊 今日学习报告（第\(report.day)天）
        ═══════════════════════════════════════
        
        总计：
        • 学习单词：\(report.totalWordsStudied)个
        • 曝光次数：\(report.totalExposures)次
        • 学习时长：\(report.studyDurationFormatted)
        • 右滑（会写）：\(report.swipeRightCount)次
        • 左滑（不会写）：\(report.swipeLeftCount)次
        • 平均停留：\(String(format: "%.1f", report.avgDwellTime))秒 ⭐
        • 掌握率：\(Int(report.masteryRate * 100))%
        
        ✅ 熟悉的单词（\(report.familiarCount)个）停留<2s
        """)
        
        // 打印熟悉的单词（停留最短的前5个）
        let familiarTop5 = report.sortedByDwellTime.reversed().prefix(5)
        if !familiarTop5.isEmpty {
            for (index, word) in familiarTop5.enumerated() {
                print("   \(index + 1). \(word.word)  \(word.swipeIndicator)  \(word.dwellTimeFormatted)")
            }
        } else {
            print("   暂无数据")
        }
        
        print("""
        
        ⚠️ 需加强的单词（\(report.unfamiliarCount)个）停留>5s ⭐
        """)
        
        // 打印需加强的单词（停留最长的前10个）
        let difficultTop10 = report.sortedByDwellTime.prefix(10)
        if !difficultTop10.isEmpty {
            for (index, word) in difficultTop10.enumerated() {
                print("   \(index + 1). \(word.word)  \(word.swipeIndicator)  \(word.dwellTimeFormatted)")
            }
        } else {
            print("   暂无数据")
        }
        
        print("""
        
        💡 建议：
        • 前\(min(report.unfamiliarCount, 20))个困难词明日会重点复习
        • 可生成AI考研短文加强理解（使用前10个最陌生的词）
        
        ═══════════════════════════════════════
        
        """)
    }
    
    // MARK: - 获取困难词列表（用于AI短文生成）
    func getDifficultWordsForAI(count: Int = 10) -> [String] {
        guard let report = currentReport else { return [] }
        return report.getTopDifficultWords(count: count).map { $0.word }
    }
    
    func getDifficultWordsForAI(report: DailyReport, count: Int = 10) -> [String] {
        return report.getTopDifficultWords(count: count).map { $0.word }
    }
    
    // MARK: - 生成AI短文
    func generateAIArticle(for report: DailyReport, topic: Topic = .auto) async {
        isGeneratingAIArticle = true
        
        do {
            // 获取最困难的10个单词
            let difficultWords = getDifficultWordsForAI(report: report, count: 10)
            
            guard !difficultWords.isEmpty else {
                print("⚠️ 没有困难词汇，无法生成短文")
                isGeneratingAIArticle = false
                return
            }
            
            print("🤖 开始生成AI短文，使用单词：\(difficultWords.joined(separator: ", "))")
            
            // 调用DeepSeek服务
            let passage = try await DeepSeekService.shared.generateReadingPassage(
                difficultWords: difficultWords,
                topic: topic
            )
            
            // 保存生成的短文
            generatedArticles.append(passage)
            
            print("✅ AI短文生成成功！")
            print("📄 标题：\(passage.topic.rawValue)")
            print("📏 字数：\(passage.wordCount)词")
            print("🔤 包含单词：\(passage.targetWords.count)个")
            
        } catch {
            print("❌ AI短文生成失败：\(error.localizedDescription)")
        }
        
        isGeneratingAIArticle = false
    }
    
    // MARK: - 获取停留时间分布
    func getDwellTimeDistribution(report: DailyReport) -> [DwellTimeRange: Int] {
        var distribution: [DwellTimeRange: Int] = [
            .veryFast: 0,
            .fast: 0,
            .medium: 0,
            .slow: 0,
            .verySlow: 0
        ]
        
        for summary in report.sortedByDwellTime {
            let range = DwellTimeRange.fromDwellTime(summary.avgDwellTime)
            distribution[range, default: 0] += 1
        }
        
        return distribution
    }
}

// DwellTimeRange 已移至 Core/DwellTimeAnalyzer.swift，避免重复定义


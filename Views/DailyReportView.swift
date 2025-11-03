//
//  DailyReportView.swift
//  NFwordsDemo
//
//  每日学习报告 - 按停留时间排序
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 每日报告视图
struct DailyReportView: View {
    let report: DailyReport
    @State private var showGenerateArticle = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部摘要
                    summaryCard
                    
                    // 熟悉的单词
                    familiarWordsSection
                    
                    // 需加强的单词 ⭐
                    unfamiliarWordsSection
                    
                    // AI短文生成
                    aiArticleSection
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("📊 今日学习报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    /// 摘要卡片
    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text("🎉 第\(report.day)天学习完成")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Divider()
            
            // 统计数据
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(title: "学习单词", value: "\(report.totalWordsStudied)个")
                StatItem(title: "曝光次数", value: "\(report.totalExposures)次")
                StatItem(title: "学习时长", value: report.studyDurationFormatted)
                StatItem(title: "平均停留", value: String(format: "%.1fs", report.avgDwellTime), highlight: true)
            }
            
            Divider()
            
            // 左右滑统计
            HStack(spacing: 40) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("会写")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(report.swipeRightCount)次")
                            .font(.title3.bold())
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("不会写")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(report.swipeLeftCount)次")
                            .font(.title3.bold())
                    }
                }
            }
            
            // 掌握率
            VStack(spacing: 8) {
                Text("掌握率")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(report.masteryRate * 100))%")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    /// 熟悉的单词部分
    private var familiarWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("✅ 熟悉（\(report.familiarCount)个）停留<2s")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(report.sortedByDwellTime.reversed().prefix(5)) { wordSum in
                    WordSummaryRow(summary: wordSum, type: .familiar)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 需加强的单词部分 ⭐ 核心
    private var unfamiliarWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("⚠️ 需加强（\(report.unfamiliarCount)个）停留>5s")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(report.sortedByDwellTime.prefix(10)) { wordSum in
                    WordSummaryRow(summary: wordSum, type: .unfamiliar)
                }
            }
            .padding(.horizontal)
            
            if report.unfamiliarCount > 10 {
                Button(action: {
                    // TODO: 显示完整列表
                }) {
                    HStack {
                        Text("查看全部 \(report.unfamiliarCount) 个")
                        Image(systemName: "chevron.right")
                    }
                    .font(.callout)
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// AI短文生成部分
    private var aiArticleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("AI考研短文")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Text("💡 建议")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("• 前\(min(report.unfamiliarCount, 20))个困难词明日会重点复习")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text("• 可生成AI考研短文加强理解")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: {
                showGenerateArticle = true
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("生成考研短文")
                    Text("（用前10个最陌生的词）")
                        .font(.caption)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    /// 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Text("继续学习")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
            Button(action: {
                // TODO: 查看详细洞察
            }) {
                Text("详细洞察")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 统计项
struct StatItem: View {
    let title: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(highlight ? .blue : .primary)
        }
        .padding()
        .background(highlight ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - 单词摘要行
struct WordSummaryRow: View {
    let summary: WordSummary
    let type: WordType
    
    enum WordType {
        case familiar, unfamiliar
    }
    
    var body: some View {
        HStack {
            // 序号
            Text("\(summary.id)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(type == .familiar ? Color.green : Color.orange)
                )
            
            // 单词
            Text(summary.word)
                .font(.body.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            // 滑动指示
            Text(summary.swipeIndicator)
                .font(.caption.bold())
                .foregroundColor(type == .familiar ? .green : .orange)
            
            // 停留时间 ⭐
            Text(summary.dwellTimeFormatted)
                .font(.callout.bold())
                .foregroundColor(type == .familiar ? .green : .orange)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.03), radius: 5)
    }
}

// MARK: - 预览
struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportView(report: DailyReport.example)
    }
}


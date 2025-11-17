//
//  StudyHistoryView.swift
//  NFwordsDemo
//
//  学习历史界面
//  Created by AI Assistant on 2025-01-XX.
//

import SwiftUI
import Combine

// MARK: - 学习历史主视图
struct StudyHistoryView: View {
    @StateObject private var viewModel = StudyHistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                filterBar
                
                // 历史列表
                if viewModel.filteredSessions.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("学习历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheet(filter: $viewModel.filter)
            }
            .onAppear {
                viewModel.load()
            }
        }
    }
    
    // MARK: - 筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "今日",
                    isSelected: viewModel.selectedDateRange == .today,
                    action: { viewModel.selectedDateRange = .today }
                )
                
                FilterButton(
                    title: "本周",
                    isSelected: viewModel.selectedDateRange == .thisWeek,
                    action: { viewModel.selectedDateRange = .thisWeek }
                )
                
                FilterButton(
                    title: "本月",
                    isSelected: viewModel.selectedDateRange == .thisMonth,
                    action: { viewModel.selectedDateRange = .thisMonth }
                )
                
                FilterButton(
                    title: "全部",
                    isSelected: viewModel.selectedDateRange == .all,
                    action: { viewModel.selectedDateRange = .all }
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无学习记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始学习以查看历史记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 历史列表
    private var historyList: some View {
        List {
            ForEach(viewModel.groupedSessions.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(viewModel.groupedSessions[date] ?? []) { session in
                        SessionRow(session: session)
                    }
                } header: {
                    Text(formatDate(date))
                        .font(.headline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 辅助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 筛选按钮
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

// MARK: - 会话行组件
struct SessionRow: View {
    let session: StudySession
    
    var body: some View {
        HStack(spacing: 16) {
            // 会话类型图标
            ZStack {
                Circle()
                    .fill(sessionTypeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: session.sessionType.icon)
                    .foregroundColor(sessionTypeColor)
            }
            
            // 会话信息
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType.displayName)
                    .font(.headline)
                
                HStack {
                    Text("\(session.cardsStudied) 词")
                        .font(.subheadline)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(session.timeSpent))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                // 准确率
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(String(format: "%.1f%%", session.accuracy * 100))
                        .font(.caption.bold())
                }
            }
            
            Spacer()
            
            // 时间
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(session.startTime))
                    .font(.subheadline.bold())
                
                Text(formatDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var sessionTypeColor: Color {
        switch session.sessionType {
        case .flashcards: return .blue
        case .review: return .orange
        case .test: return .purple
        case .practice: return .green
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - 筛选表单
struct FilterSheet: View {
    @Binding var filter: StudyHistoryFilter
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 会话类型
                Section("会话类型") {
                    Picker("类型", selection: $filter.sessionType) {
                        Text("全部").tag(nil as SessionType?)
                        ForEach(SessionType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as SessionType?)
                        }
                    }
                }
                
                // 准确率
                Section("准确率") {
                    if let minAccuracy = filter.minAccuracy {
                        VStack {
                            HStack {
                                Text("最小准确率")
                                Spacer()
                                Text(String(format: "%.0f%%", minAccuracy * 100))
                                    .fontWeight(.semibold)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { minAccuracy },
                                    set: { filter.minAccuracy = $0 }
                                ),
                                in: 0...1,
                                step: 0.1
                            )
                        }
                    } else {
                        Toggle("筛选准确率", isOn: Binding(
                            get: { filter.minAccuracy != nil },
                            set: { filter.minAccuracy = $0 ? 0.5 : nil }
                        ))
                    }
                }
            }
            .navigationTitle("筛选")
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
}

// MARK: - 视图模型
@MainActor
class StudyHistoryViewModel: ObservableObject {
    @Published var history: StudyHistory = .empty
    @Published var filter: StudyHistoryFilter = StudyHistoryFilter()
    @Published var selectedDateRange: DateRange = .today
    @Published var showFilterSheet = false
    
    var filteredSessions: [StudySession] {
        let sessions = getSessionsForDateRange(selectedDateRange)
        return filter.apply(to: StudyHistory(sessions: sessions, dailyReports: [], goals: []))
    }
    
    var groupedSessions: [Date: [StudySession]] {
        Dictionary(grouping: filteredSessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }
    
    func load() {
        do {
            // 1. 从数据库加载报告、任务、目标
            let reportStorage = DailyReportStorage()
            let taskStorage = DailyTaskStorage()
            let goalStorage = LearningGoalStorage()
            
            let allReports = try reportStorage.fetchAll()
            let allTasks = try taskStorage.fetchAll()
            let allGoals = try goalStorage.fetchAll()
            
            // 2. 从报告构建学习会话
            var sessions: [StudySession] = []
            for report in allReports {
                let session = StudySession(
                    id: UUID(),
                    goalId: report.goalId,
                    sessionType: .flashcards,
                    startTime: report.reportDate
                )
                
                var mutableSession = session
                mutableSession.endTime = report.reportDate
                mutableSession.cardsStudied = report.totalWordsStudied
                mutableSession.correctCount = report.swipeRightCount
                mutableSession.incorrectCount = report.swipeLeftCount
                mutableSession.timeSpent = report.studyDuration
                
                sessions.append(mutableSession)
            }
            
            // 3. 构建学习历史
            history = StudyHistory(
                sessions: sessions,
                dailyReports: allReports,
                goals: allGoals
            )
            
            #if DEBUG
            print("[StudyHistoryViewModel] ✅ 数据加载完成:")
            print("  - 会话数: \(sessions.count)")
            print("  - 报告数: \(allReports.count)")
            print("  - 目标数: \(allGoals.count)")
            #endif
            
        } catch {
            #if DEBUG
            print("[StudyHistoryViewModel] ⚠️ 加载数据失败: \(error)")
            #endif
            
            // 加载失败时使用空数据
            history = .empty
        }
    }
    
    private func getSessionsForDateRange(_ range: DateRange) -> [StudySession] {
        switch range {
        case .today:
            return history.getTodaySessions()
        case .thisWeek:
            return history.getThisWeekSessions()
        case .thisMonth:
            return history.getThisMonthSessions()
        case .all:
            return history.sessions
        }
    }
}

enum DateRange {
    case today
    case thisWeek
    case thisMonth
    case all
}

// MARK: - 预览
struct StudyHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        StudyHistoryView()
    }
}


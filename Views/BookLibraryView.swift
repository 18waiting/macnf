//
//  BookLibraryView.swift
//  NFwordsDemo
//
//  词库管理页面（墨墨式）
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 词库管理视图
struct BookLibraryView: View {
    var onSelectPack: (() -> Void)? = nil
    @State private var showingAddPack = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 当前词库
                    currentPackCard
                    
                    // 推荐词库
                    recommendedPacksSection
                    
                    // 自定义导入
                    customImportSection
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("📚 我的词库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPack = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var currentPackCard: some View {
        Group {
            if let goal = appState.dashboard.goal,
               let task = appState.dashboard.todayTask {
                ActivePackCard(goal: goal, task: task, onSelectPack: onSelectPack)
            } else {
                EmptyPackPlaceholder(onSelectPack: onSelectPack)
            }
        }
    }
    
    private var recommendedPacksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推荐词库")
                .font(.headline)
                .padding(.horizontal)
            
            let availablePacks = appState.localDatabase.packs.filter { pack in
                // 排除当前正在学习的词书
                if let currentGoal = appState.dashboard.goal {
                    return pack.packId != currentGoal.packId
                }
                return true
            }
            
            if availablePacks.isEmpty {
                Text("暂无可用词库")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(availablePacks) { pack in
                        PackCard(
                            name: pack.title,
                            wordCount: pack.totalCount,
                            onSelect: onSelectPack
                        )
                    }
                }
            }
        }
    }
    
    private var customImportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("自定义词库")
                .font(.headline)
                .padding(.horizontal)
            
            Button(action: {
                showingAddPack = true
                onSelectPack?()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导入词库")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("支持：Excel / CSV / TXT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - 词库卡片
struct PackCard: View {
    let name: String
    let wordCount: Int
    var onSelect: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.6))
            
            Text(name)
                .font(.headline)
            
            Text("\(wordCount)词")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("开始学习") {
                onSelect?()
            }
            .font(.caption.bold())
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - 当前词库卡片
private struct ActivePackCard: View {
    let goal: LearningGoal
    let task: DailyTask
    var onSelectPack: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(goal.packName)
                    .font(.title3.bold())
                Spacer()
                Text(String(format: "%.0f%%", goal.progress * 100))
                    .font(.callout.bold())
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: goal.progress)
                .tint(.blue)
                .scaleEffect(y: 2)
            
            HStack {
                Text("已学 \(goal.completedWords) / 总计 \(goal.totalWords)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
                Text("第 \(goal.currentDay) 天")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("今日新词: \(task.newWordsCount)", systemImage: "plus.circle")
                    .font(.caption)
                Spacer()
                Label("复习: \(task.reviewWordsCount)", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {
                    onSelectPack?()
                }) {
                    Text("继续学习")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // TODO: 跳转到计划详情
                }) {
                    Text("查看详情")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 15)
    }
}

// MARK: - 空状态
private struct EmptyPackPlaceholder: View {
    var onSelectPack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("还没有选择词库")
                .font(.headline)
            
            Text("挑选一个目标词库，系统会为你生成 10 天冲刺计划。")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                onSelectPack?()
            }) {
                Text("选择词库")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 12)
    }
}

// MARK: - 预览
struct BookLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        BookLibraryView()
            .environmentObject(AppState(dashboard: .demo))
    }
}


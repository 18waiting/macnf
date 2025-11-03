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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("CET-4 核心词汇")
                    .font(.title3.bold())
                
                Spacer()
            }
            
            ProgressView(value: 0.72)
                .tint(.blue)
                .scaleEffect(y: 2)
            
            HStack {
                Text("已学 3,240 / 总计 4,500")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
                Text("72%")
                    .font(.callout.bold())
                    .foregroundColor(.blue)
            }
            
            HStack {
                Label("今日新词: 50", systemImage: "plus.circle")
                    .font(.caption)
                Spacer()
                Label("复习: 120", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {
                    // 继续学习
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
                    // 查看详情
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
    
    private var recommendedPacksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推荐词库")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                PackCard(name: "CET-6", wordCount: 5500, onSelect: onSelectPack)
                PackCard(name: "TOEFL", wordCount: 8000, onSelect: onSelectPack)
                PackCard(name: "GRE", wordCount: 15000, onSelect: onSelectPack)
                PackCard(name: "考研核心", wordCount: 5500, onSelect: onSelectPack)
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

// MARK: - 预览
struct BookLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        BookLibraryView()
    }
}


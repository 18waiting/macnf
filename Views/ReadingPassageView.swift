//
//  ReadingPassageView.swift
//  NFwordsDemo
//
//  AI考研风格阅读短文视图
//  Created by 甘名杨 on 2025/11/3.
//

import SwiftUI

// MARK: - 阅读短文视图
struct ReadingPassageView: View {
    let passage: ReadingPassage
    @Environment(\.dismiss) var dismiss
    @State private var selectedWord: String?
    @State private var showWordDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    titleSection
                    
                    // 短文内容（高亮目标词）
                    passageContent
                    
                    // 单词标注列表
                    wordAnnotations
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("📖 考研阅读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: 收藏
                    }) {
                        Image(systemName: passage.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - 子视图
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label(passage.topic.rawValue, systemImage: passage.topic.emoji)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Label(passage.difficulty.rawValue, systemImage: "graduationcap.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            HStack {
                Label("\(passage.targetWords.count)个单词", systemImage: "text.book.closed.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(passage.wordCount)词", systemImage: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var passageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("短文内容")
                .font(.headline)
            
            // 高亮显示目标单词
            HighlightedText(
                content: passage.content,
                highlightWords: passage.targetWords
            )
            .font(.body)
            .lineSpacing(6)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private var wordAnnotations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📌 单词标注 (\(passage.targetWords.count)个)")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(passage.wordPositions) { position in
                    WordAnnotationRow(position: position)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                // TODO: 朗读全文
            }) {
                Label("朗读全文", systemImage: "speaker.wave.2.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Button(action: {
                // TODO: 导出PDF
            }) {
                Label("导出", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - 高亮文本
struct HighlightedText: View {
    let content: String
    let highlightWords: [String]
    
    var body: some View {
        Text(attributedString)
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(content)
        
        // 高亮每个目标单词
        for word in highlightWords {
            if let range = attributedString.range(of: word, options: .caseInsensitive) {
                attributedString[range].foregroundColor = .blue
                attributedString[range].font = .body.bold()
                attributedString[range].backgroundColor = Color.blue.opacity(0.1)
            }
        }
        
        return attributedString
    }
}

// MARK: - 单词标注行
struct WordAnnotationRow: View {
    let position: WordPosition
    
    var body: some View {
        HStack {
            Text(position.word)
                .font(.body.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("第\(position.line)行")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                // TODO: 查看释义
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

// MARK: - 预览
struct ReadingPassageView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingPassageView(passage: ReadingPassage.example)
    }
}


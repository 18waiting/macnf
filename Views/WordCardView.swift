//
//  WordCardView.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//  Updated by 甘名杨 on 2025/11/3 - Tinder式纯粹设计
//

//
//  WordCardView.swift
//  NFwords Demo
//
//  Tinder式单词卡片 - 左右滑动 + 点击展开
//

import SwiftUI

// MARK: - Tinder式单词卡片
struct WordCardView: View {
    let word: Word
    let record: WordLearningRecord
    let isTopCard: Bool
    let onSwipe: (SwipeDirection, TimeInterval) -> Void
    
    // 滑动状态
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @GestureState private var isDragging = false
    
    // 内容展开状态
    @State private var isExpanded = false
    
    // 停留时间
    @State private var startTime = Date()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 卡片主体
                cardContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                
                // 方向指示器（Tinder式）⭐
                if isTopCard {
                    directionIndicators
                }
            }
            .offset(x: offset.width, y: offset.height * 0.1)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture(minimumDistance: 10)  // ⭐ 增加最小距离，避免拦截点击
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { gesture in
                        if isTopCard {
                            offset = gesture.translation
                            rotation = Double(gesture.translation.width / 20).clamped(to: -15...15)
                            #if DEBUG
                            // 只在大幅度拖动时打印日志
                            if abs(gesture.translation.width) > 50 {
                                // print("[Card] Dragging: \(Int(gesture.translation.width))pt")
                            }
                            #endif
                        }
                    }
                    .onEnded { gesture in
                        if isTopCard {
                            #if DEBUG
                            print("[Card] Drag ended: translation=\(Int(gesture.translation.width))pt, velocity=\(Int(gesture.predictedEndTranslation.width))pt")
                            #endif
                            handleSwipeGesture(translation: gesture.translation, velocity: gesture.predictedEndTranslation)
                        }
                    }
            )
        }
        .onAppear {
            startTime = Date()
            #if DEBUG
            print("[Card] Card appeared: \(word.word) (wid: \(word.id)), isTopCard: \(isTopCard)")
            #endif
        }
        .onChange(of: isTopCard) { newValue in
            #if DEBUG
            print("[Card] Card \(word.word) isTopCard changed to: \(newValue)")
            #endif
            if newValue {
                // 当卡片变成顶部卡片时，重置状态
                startTime = Date()
                offset = .zero
                rotation = 0
                isExpanded = false
                #if DEBUG
                print("[Card] Card \(word.word) state reset")
                #endif
            }
        }
    }
    
    // MARK: - 卡片内容
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // 主显示区域
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)
                    
                    // 单词和音标（始终显示）
                    wordHeader
                    
                    // 释义和例句（点击后展开）
                    if isExpanded {
                        expandedContent
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                #if DEBUG
                                print("[Card] ✅ Expanded content is now VISIBLE")
                                #endif
                            }
                    } else {
                        // 展开提示
                        expandHint
                            .onAppear {
                                #if DEBUG
                                print("[Card] 📍 Showing expand hint (collapsed state)")
                                #endif
                            }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 30)
            }
            .disabled(isDragging)  // 滑动时禁用滚动
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            // ⭐ 使用 simultaneousGesture 让点击手势和拖拽手势共存
            TapGesture()
                .onEnded { _ in
                    #if DEBUG
                    print("[Card] Tap detected on card: \(word.word), isTopCard: \(isTopCard), current isExpanded: \(isExpanded)")
                    #endif
                    guard isTopCard else {
                        #if DEBUG
                        print("[Card] Ignoring tap - not top card")
                        #endif
                        return
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                        #if DEBUG
                        print("[Card] Expanded toggled to: \(isExpanded)")
                        #endif
                    }
                }
        )
    }
    
    // MARK: - 单词头部
    
    private var wordHeader: some View {
        VStack(spacing: 16) {
            // 单词
            Text(word.word)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            // 音标
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // 简短释义（不展开时显示）
            if !isExpanded, let firstTranslation = word.translations.first {
                HStack(spacing: 8) {
                    Text(firstTranslation.displayPartOfSpeech)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(6)
                    
                    Text(firstTranslation.meaning)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - 展开内容
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Divider()
                .padding(.horizontal, 20)
            
            // 所有释义
            VStack(alignment: .leading, spacing: 12) {
                ForEach(word.translations, id: \.self) { translation in
                    HStack(alignment: .top, spacing: 12) {
                        Text(translation.displayPartOfSpeech)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(6)
                        
                        Text(translation.meaning)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            
            // 短语搭配
            if !word.phrases.isEmpty {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("常用搭配")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(word.phrases.prefix(3), id: \.self) { phrase in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.english)
                                .font(.body.bold())
                                .foregroundColor(.primary)
                            
                            Text(phrase.chinese)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            
            // 微场景（如果有）
            if let scene = word.scenes.first {
                Divider()
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("场景例句")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scene.english)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                        
                        if let chinese = scene.chinese {
                            Text(chinese)
                                .font(.caption)
                                .lineSpacing(4)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 展开提示
    
    private var expandHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.6))
            
            Text("点击查看更多")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 方向指示器（Tinder式）⭐
    
    private var directionIndicators: some View {
        ZStack {
            // 右滑指示器（绿色✓）
            if offset.width > 30 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .opacity({
                                let progress = min(abs(offset.width) / CGFloat(120), CGFloat(1))
                                return Double(progress)
                            }())
                            .padding(.trailing, 30)
                            .padding(.top, 50)
                    }
                    Spacer()
                }
            }
            
            // 左滑指示器（橙色✗）
            if offset.width < -30 {
                VStack {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .opacity({
                                let progress = min(abs(offset.width) / CGFloat(120), CGFloat(1))
                                return Double(progress)
                            }())
                            .padding(.leading, 30)
                            .padding(.top, 50)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 手势处理
    
    private func handleSwipeGesture(translation: CGSize, velocity: CGSize) {
        let threshold: CGFloat = 100
        let velocityThreshold: CGFloat = 500
        
        // 判断是否触发滑动
        let shouldSwipe = abs(translation.width) > threshold || abs(velocity.width) > velocityThreshold
        
        if shouldSwipe {
            if translation.width > 0 {
                swipeRight()
            } else {
                swipeLeft()
            }
        } else {
            // 回弹
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                offset = .zero
                rotation = 0
            }
        }
    }
    
    private func swipeRight() {
        let dwellTime = Date().timeIntervalSince(startTime)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offset = CGSize(width: 500, height: 0)
            rotation = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(.right, dwellTime)
        }
        
        // 触觉反馈（轻）
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func swipeLeft() {
        let dwellTime = Date().timeIntervalSince(startTime)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offset = CGSize(width: -500, height: 0)
            rotation = -15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwipe(.left, dwellTime)
        }
        
        // 触觉反馈（中等）
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - 辅助扩展

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - 预览
struct WordCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .ignoresSafeArea()
            
            WordCardView(
                word: Word.examples[0],
                record: .initial(wid: 1, targetExposures: 10),
                isTopCard: true,
                onSwipe: { direction, time in
                    print("Swiped \(direction.rawValue), dwell time: \(time)s")
                }
            )
            .frame(height: 550)
            .padding()
        }
    }
}

//
//  ZLSwipeCardsView.swift
//  NFwordsDemo
//
//  基于 ZLSwipeableViewSwift 的滑卡视图
//  完整实现 Tinder/探探 风格的卡片交互
//
//  ⭐ 核心架构：
//  1. ZLSwipeCardsView (SwiftUI 入口)
//  2. ZLSwipeableViewWrapper (UIViewRepresentable 桥接)
//  3. ZLSwipeCardsCoordinator (处理所有回调和业务逻辑)
//

import SwiftUI
import ZLSwipeableViewSwift

// MARK: - SwiftUI 主视图

struct ZLSwipeCardsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    private var viewModel: StudyViewModel {
        appState.studyViewModel
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部状态栏
                topStatusBar
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // 卡片区域 (ZLSwipeableView)
                ZStack {
                    if viewModel.visibleCards.isEmpty {
                        emptyStateView
                    } else {
                        ZLSwipeableViewWrapper(
                            cards: viewModel.visibleCards,
                            onSwipe: { cardId, direction, dwellTime in
                                handleSwipe(cardId: cardId, direction: direction, dwellTime: dwellTime)
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 550)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 滑动提示
                swipeHints
                    .padding(.vertical, 20)
                
                // 底部工具栏
                bottomToolbar
                    .padding(.bottom, 40)
                    .padding(.horizontal, 20)
            }
            
            // 完成庆祝动画
            if viewModel.isCompleted {
                CompletionView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            #if DEBUG
            print("[ZLSwipeCardsView] 📱 视图出现")
            print("[ZLSwipeCardsView] visibleCards 数量: \(viewModel.visibleCards.count)")
            for (index, card) in viewModel.visibleCards.enumerated() {
                print("[ZLSwipeCardsView]   [\(index)]: \(card.word.word) (id: \(card.id))")
            }
            #endif
            viewModel.startCurrentCardTracking()
        }
        .onDisappear {
            #if DEBUG
            print("[ZLSwipeCardsView] 📱 视图消失")
            #endif
        }
    }
    
    // MARK: - Swipe Handler
    
    private func handleSwipe(cardId: UUID, direction: SwipeDirection, dwellTime: TimeInterval) {
        #if DEBUG
        print("[ZLSwipeCardsView] 🎯 接收到滑动: cardId=\(cardId), direction=\(direction.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 查找对应的单词ID
        if let card = viewModel.visibleCards.first(where: { $0.id == cardId }) {
            viewModel.handleSwipe(
                wordId: card.word.id,
                direction: direction,
                dwellTime: dwellTime
            )
        } else {
            #if DEBUG
            print("[ZLSwipeCardsView] ⚠️ 未找到对应的卡片: \(cardId)")
            #endif
        }
    }
    
    // MARK: - 子视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("正在加载单词...")
                .font(.title3)
                .foregroundColor(.white)
            
            Text("如果长时间未加载，请返回检查词库设置")
                .font(.callout)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var topStatusBar: some View {
        HStack {
            // 返回按钮
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 剩余次数
            if let currentCard = viewModel.visibleCards.first {
                Text("剩 \(currentCard.record.remainingExposures) 次")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            
            Spacer()
            
            // 进度显示
            Text("进度 \(viewModel.completedCount)/\(viewModel.totalCount)")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
    
    private var swipeHints: some View {
        HStack(spacing: 40) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                Text("不会写")
                    .font(.callout)
            }
            .foregroundColor(.orange)
            
            Text("|")
                .foregroundColor(.white.opacity(0.3))
            
            HStack(spacing: 8) {
                Text("会写")
                    .font(.callout)
                Image(systemName: "arrow.right")
                    .font(.title3)
            }
            .foregroundColor(.green)
        }
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 40) {
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                    Text("发音")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                    Text("撤回")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                    Text("更多")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - UIViewRepresentable 包装器

struct ZLSwipeableViewWrapper: UIViewRepresentable {
    let cards: [StudyCard]
    let onSwipe: (UUID, SwipeDirection, TimeInterval) -> Void
    
    func makeUIView(context: Context) -> ZLSwipeableView {
        let swipeableView = ZLSwipeableView()
        
        // 配置 ZLSwipeableView
        swipeableView.numberOfActiveView = 3  // 同时显示 3 张卡
        swipeableView.didStart = context.coordinator.didStart
        swipeableView.swiping = context.coordinator.swiping
        swipeableView.didSwipe = context.coordinator.didSwipe
        swipeableView.didEnd = context.coordinator.didEnd
        swipeableView.didCancel = context.coordinator.didCancel
        
        // 设置数据源和代理
        swipeableView.dataSource = context.coordinator
        swipeableView.delegate = context.coordinator
        
        context.coordinator.swipeableView = swipeableView
        
        #if DEBUG
        print("[ZLSwipeableViewWrapper] ✅ makeUIView 完成, cards: \(cards.count)")
        #endif
        
        return swipeableView
    }
    
    func updateUIView(_ uiView: ZLSwipeableView, context: Context) {
        // 更新 Coordinator 的卡片数据
        context.coordinator.cards = cards
        context.coordinator.onSwipe = onSwipe
        
        // 刷新视图
        uiView.discardViews()
        uiView.loadViews()
        
        #if DEBUG
        print("[ZLSwipeableViewWrapper] 🔄 updateUIView, cards: \(cards.count)")
        #endif
    }
    
    func makeCoordinator() -> ZLSwipeCardsCoordinator {
        return ZLSwipeCardsCoordinator(cards: cards, onSwipe: onSwipe)
    }
}

// MARK: - Coordinator (核心业务逻辑)

class ZLSwipeCardsCoordinator: NSObject, ZLSwipeableViewDataSource, ZLSwipeableViewDelegate {
    
    // MARK: - Properties
    
    var cards: [StudyCard]
    var onSwipe: (UUID, SwipeDirection, TimeInterval) -> Void
    weak var swipeableView: ZLSwipeableView?
    
    // 追踪当前卡片的停留时间
    private var currentCardId: UUID?
    private var currentCardStartTime: Date?
    
    // 卡片视图缓存
    private var cardViews: [Int: WordCardUIView] = [:]
    
    // MARK: - Initialization
    
    init(cards: [StudyCard], onSwipe: @escaping (UUID, SwipeDirection, TimeInterval) -> Void) {
        self.cards = cards
        self.onSwipe = onSwipe
        super.init()
        
        #if DEBUG
        print("[Coordinator] 🎬 初始化, cards: \(cards.count)")
        #endif
    }
    
    // MARK: - ZLSwipeableViewDataSource
    
    func nextView(for swipeableView: ZLSwipeableView) -> UIView? {
        guard cards.count > swipeableView.history.count else {
            #if DEBUG
            print("[Coordinator] ⚠️ 没有更多卡片: history=\(swipeableView.history.count), cards=\(cards.count)")
            #endif
            return nil
        }
        
        let index = swipeableView.history.count
        let card = cards[index]
        
        // 创建或复用卡片视图
        let cardView: WordCardUIView
        if let cachedView = cardViews[index] {
            cardView = cachedView
        } else {
            cardView = WordCardUIView()
            cardView.backgroundColor = .clear
            cardViews[index] = cardView
        }
        
        cardView.card = card
        
        // 如果是第一张卡，开始计时
        if index == 0 {
            currentCardId = card.id
            currentCardStartTime = Date()
            #if DEBUG
            print("[Coordinator] ⏱️ 开始计时: \(card.word.word) (id: \(card.id))")
            #endif
        }
        
        #if DEBUG
        print("[Coordinator] 📄 提供卡片视图: index=\(index), word=\(card.word.word)")
        #endif
        
        return cardView
    }
    
    func view(for swipeableView: ZLSwipeableView, index: Int) -> UIView? {
        guard index < cards.count else {
            return nil
        }
        
        let card = cards[index]
        let cardView = WordCardUIView()
        cardView.backgroundColor = .clear
        cardView.card = card
        
        return cardView
    }
    
    // MARK: - ZLSwipeableView Lifecycle Callbacks
    
    lazy var didStart: (ZLSwipeableView, UIView, CGPoint) -> Void = { [weak self] swipeableView, view, location in
        guard let self = self else { return }
        
        #if DEBUG
        print("[Coordinator] 🚀 didStart: location=\(location)")
        #endif
    }
    
    lazy var swiping: (ZLSwipeableView, UIView, CGPoint, CGPoint) -> Void = { [weak self] swipeableView, view, location, translation in
        guard let self = self else { return }
        
        // 更新方向指示器
        if let cardView = view as? WordCardUIView {
            cardView.updateDirectionIndicator(offset: translation.x)
        }
    }
    
    lazy var didSwipe: (ZLSwipeableView, Int, ZLSwipeableViewDirection) -> Void = { [weak self] swipeableView, index, direction in
        guard let self = self else { return }
        
        guard index < self.cards.count else {
            #if DEBUG
            print("[Coordinator] ⚠️ didSwipe: index 越界: \(index)")
            #endif
            return
        }
        
        let card = self.cards[index]
        
        // 计算停留时间
        let dwellTime: TimeInterval
        if self.currentCardId == card.id, let startTime = self.currentCardStartTime {
            dwellTime = Date().timeIntervalSince(startTime)
        } else {
            dwellTime = 0
            #if DEBUG
            print("[Coordinator] ⚠️ 停留时间追踪异常: currentCardId=\(String(describing: self.currentCardId)), cardId=\(card.id)")
            #endif
        }
        
        // 转换方向
        let swipeDirection: SwipeDirection
        switch direction {
        case .Left, .Up:
            swipeDirection = .left
        case .Right, .Down:
            swipeDirection = .right
        default:
            swipeDirection = .left
        }
        
        #if DEBUG
        print("[Coordinator] 🎯 didSwipe: word=\(card.word.word), direction=\(swipeDirection.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 触发回调
        self.onSwipe(card.id, swipeDirection, dwellTime)
        
        // 开始下一张卡的计时
        if index + 1 < self.cards.count {
            let nextCard = self.cards[index + 1]
            self.currentCardId = nextCard.id
            self.currentCardStartTime = Date()
            #if DEBUG
            print("[Coordinator] ⏱️ 开始计时下一张: \(nextCard.word.word) (id: \(nextCard.id))")
            #endif
        } else {
            self.currentCardId = nil
            self.currentCardStartTime = nil
        }
        
        // 清理缓存
        self.cardViews[index] = nil
    }
    
    lazy var didEnd: (ZLSwipeableView, Int, ZLSwipeableViewDirection) -> Void = { [weak self] swipeableView, index, direction in
        guard let self = self else { return }
        
        #if DEBUG
        print("[Coordinator] ✅ didEnd: index=\(index), direction=\(direction)")
        #endif
    }
    
    lazy var didCancel: (ZLSwipeableView) -> Void = { [weak self] swipeableView in
        guard let self = self else { return }
        
        #if DEBUG
        print("[Coordinator] ❌ didCancel: 卡片回弹")
        #endif
    }
    
    // MARK: - ZLSwipeableViewDelegate (可选)
    
    func swipeableView(_ swipeableView: ZLSwipeableView, shouldSwipeAt index: Int, inDirection direction: ZLSwipeableViewDirection) -> Bool {
        // 允许所有方向的滑动
        return true
    }
    
    func swipeableView(_ swipeableView: ZLSwipeableView, didSwipeAt index: Int, inDirection direction: ZLSwipeableViewDirection) {
        // 已在 didSwipe closure 中处理
    }
}

// MARK: - 完成视图 (复用)

struct CompletionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("今日学习完成！")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("正在生成学习报告...")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .transition(.opacity)
    }
}

// MARK: - 预览

struct ZLSwipeCardsView_Previews: PreviewProvider {
    static var previews: some View {
        ZLSwipeCardsView()
            .environmentObject(AppState(dashboard: .demo))
    }
}


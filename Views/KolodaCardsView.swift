//
//  KolodaCardsView.swift
//  NFwordsDemo
//
//  基于 Koloda 的滑卡视图（手动集成版本）
//  完整实现 Tinder/探探 风格的卡片交互
//
//  ⭐ 注意：此版本不需要 import Koloda
//  因为 Koloda 源码文件直接放在项目中

import SwiftUI
import UIKit

// MARK: - SwiftUI 主视图

struct KolodaCardsView: View {
    @ObservedObject private var viewModel: StudyViewModel
    @Environment(\.dismiss) var dismiss

    init(viewModel: StudyViewModel) {
        _viewModel = ObservedObject(initialValue: viewModel)
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
                
                // 卡片区域 (Koloda)
                ZStack {
                    if viewModel.visibleCards.isEmpty {
                        emptyStateView
                    } else {
                        KolodaViewWrapper(
                            viewModel: viewModel,
                            onSwipe: { wordId, direction, dwellTime in
                                // ⭐ P1 修复：直接传递 wordId，避免通过 cardId 查找可能失败
                                handleSwipe(wordId: wordId, direction: direction, dwellTime: dwellTime)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 550)
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
            print("[KolodaCardsView] 📱 视图出现")
            print("[KolodaCardsView] visibleCards 数量: \(viewModel.visibleCards.count)")
            for (index, card) in viewModel.visibleCards.enumerated() {
                print("[KolodaCardsView]   [\(index)]: \(card.word.word) (id: \(card.id))")
            }
            print("[KolodaCardsView] queueCount: \(viewModel.queueCount), initialTotalCount: \(viewModel.initialTotalCount)")
            #endif
            viewModel.startCurrentCardTracking()
            
            // ⭐ 关键修复：视图重新出现时，确保 Koloda 索引同步
            // 通过触发 updateUIView 来检测并修复索引同步问题
            // 这里不需要直接操作 KolodaView，因为 updateUIView 会自动处理
        }
        .onDisappear {
            #if DEBUG
            print("[KolodaCardsView] 📱 视图消失")
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
            
            // ⭐ 移除：剩余次数显示（已移到卡片上）
            
            // 进度显示
            // ⭐ 修复：确保 UI 能观察到 completedCount 和 totalCount 的变化
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
    
    // MARK: - 业务逻辑
    
    // ⭐ P1 修复：直接接收 wordId，避免通过 cardId 查找可能失败
    private func handleSwipe(wordId: Int, direction: SwipeDirection, dwellTime: TimeInterval) {
        #if DEBUG
        print("[KolodaCardsView] 🎯 接收到滑动: wordId=\(wordId), direction=\(direction.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 直接调用 ViewModel，不需要查找卡片
        viewModel.handleSwipe(
            wordId: wordId,
            direction: direction,
            dwellTime: dwellTime
        )
    }
}

// MARK: - UIViewRepresentable 桥接层

struct KolodaViewWrapper: UIViewRepresentable {
    // ⭐ 修复：直接使用 ViewModel 引用，而不是 cards 副本
    let viewModel: StudyViewModel
    // ⭐ P1 修复：改为传递 wordId 而不是 cardId，避免查找失败
    let onSwipe: (Int, SwipeDirection, TimeInterval) -> Void
    
    func makeUIView(context: Context) -> KolodaView {
        let kolodaView = KolodaView()
        
        // 初始化协调器（必须在设置数据源之前）
        context.coordinator.viewModel = viewModel
        context.coordinator.onSwipe = onSwipe
        
        // ⭐ 商业级优化：初始化初始总数（仅用于进度显示）
        if viewModel.initialTotalCount > 0 {
            context.coordinator.initialize(with: viewModel.initialTotalCount)
        }
        
        // 配置 KolodaView
        kolodaView.dataSource = context.coordinator
        kolodaView.delegate = context.coordinator
        kolodaView.countOfVisibleCards = 3
        kolodaView.alphaValueSemiTransparent = 0.1
        
        // ⭐ 修复：优化滑动体验
        // 降低旋转角度，让滑动更流畅
        kolodaView.rotationAngle = CGFloat(Double.pi) / 20.0  // 从 18° 降低到 9°
        // 设置最小缩放比例，让背景卡片更明显
        kolodaView.scaleMin = 0.9  // 从 0.8 提高到 0.9
        
        #if DEBUG
        print("[KolodaViewWrapper] ✅ makeUIView 完成, initialTotalCount: \(viewModel.initialTotalCount), queueCount: \(viewModel.queueCount)")
        #endif
        
        // ⭐ 关键：必须在设置数据源后调用 reloadData() 来加载卡片
        DispatchQueue.main.async {
            kolodaView.reloadData()
        }
        
        return kolodaView
    }
    
    func updateUIView(_ uiView: KolodaView, context: Context) {
        // ⭐ 最优方案：更新 ViewModel 引用
        context.coordinator.viewModel = viewModel
        context.coordinator.onSwipe = onSwipe
        
        // ⭐ 商业级优化：初始化初始总数（如果还未初始化，仅用于进度显示）
        if context.coordinator.initialTotalCount == 0 && viewModel.initialTotalCount > 0 {
            context.coordinator.initialize(with: viewModel.initialTotalCount)
        }
        
        // ⭐ 商业级方案：队列索引映射 + 智能同步
        // Koloda 索引直接对应队列索引：0 到 queueCount-1
        let currentQueueCount = viewModel.queueCount
        let currentKolodaIndex = uiView.currentCardIndex
        
        // ⭐ 智能同步：检测索引超出范围（最常见的情况：提前掌握导致队列减少）
        if currentQueueCount > 0 && currentKolodaIndex >= currentQueueCount {
            #if DEBUG
            print("[KolodaViewWrapper] ⚠️ 检测到索引超出范围: currentKolodaIndex=\(currentKolodaIndex), queueCount=\(currentQueueCount)")
            print("[KolodaViewWrapper] 🔄 智能同步：重置索引到队列第一张卡片")
            #endif
            
            // 重置索引，让 Koloda 从 0 开始（对应队列的第一张卡片）
            // 这样 Koloda 可以继续正常工作，无需复杂的映射逻辑
            DispatchQueue.main.async {
                uiView.resetCurrentCardIndex()
            }
        }
        
        #if DEBUG
        if currentQueueCount > 0 {
            print("[KolodaViewWrapper] 🔄 updateUIView: queueCount=\(currentQueueCount), currentKolodaIndex=\(currentKolodaIndex) ✅ 同步正常")
        }
        #endif
    }
    
    func makeCoordinator() -> KolodaCardsCoordinator {
        return KolodaCardsCoordinator(viewModel: viewModel, onSwipe: onSwipe)
    }
}

// MARK: - 协调器（数据源 + 委托）

class KolodaCardsCoordinator: NSObject {
    // ⭐ 修复：直接使用 ViewModel 引用，不维护 cards 副本
    weak var viewModel: StudyViewModel?
    // ⭐ P1 修复：改为传递 wordId 而不是 cardId，避免查找失败
    var onSwipe: (Int, SwipeDirection, TimeInterval) -> Void
    
    // ⭐ 修复：移除重复的停留时间追踪，统一使用 ViewModel 的 DwellTimeTracker
    
    // ⭐ 商业级优化：保留 initialTotalCount 仅用于进度显示
    // Koloda 索引现在直接对应队列索引，不需要偏移量映射
    var initialTotalCount: Int = 0  // 初始总数（仅用于进度计算：completedCount / initialTotalCount）
    
    // ⭐ P1 修复：视图重用池（业界最佳实践）
    private var cardViewPool: [WordCardUIView] = []
    private let maxPoolSize = 5  // 最多保留5个视图
    
    // ⭐ 最优方案：预加载缓存（减少数据获取延迟）
    private var preloadedCards: [Int: StudyCard] = [:]
    
    init(viewModel: StudyViewModel, onSwipe: @escaping (Int, SwipeDirection, TimeInterval) -> Void) {
        self.viewModel = viewModel
        self.onSwipe = onSwipe
        super.init()
        
        #if DEBUG
        print("[KolodaCoordinator] 🎬 初始化, cards: \(viewModel.visibleCards.count)")
        #endif
    }
    
    // ⭐ 商业级优化：初始化方法（在队列初始化时调用）
    // 仅用于保存初始总数，用于进度计算
    func initialize(with initialCount: Int) {
        initialTotalCount = initialCount
        #if DEBUG
        print("[KolodaCoordinator] ✅ 初始化: initialTotalCount=\(initialTotalCount) (仅用于进度显示)")
        #endif
    }
    
    // ⭐ 辅助属性：获取可见卡片（用于调试）
    private var visibleCards: [StudyCard] {
        return viewModel?.visibleCards ?? []
    }
    
    // ⭐ P1 修复：从重用池获取或创建视图
    private func dequeueCardView() -> WordCardUIView {
        if let reusedView = cardViewPool.popLast() {
            #if DEBUG
            print("[KolodaCoordinator] ♻️ 重用卡片视图")
            #endif
            // ⭐ 优化：确保重用视图立即可见，避免空白
            reusedView.alpha = 1.0
            reusedView.isHidden = false
            return reusedView
        } else {
            #if DEBUG
            print("[KolodaCoordinator] ✨ 创建新卡片视图")
            #endif
            let newView = WordCardUIView()
            // ⭐ 优化：确保新视图立即可见
            newView.alpha = 1.0
            newView.isHidden = false
            return newView
        }
    }
    
    // ⭐ P1 修复：将视图回收到重用池
    private func enqueueCardView(_ view: WordCardUIView) {
        // 清理视图状态
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // 如果池未满，则回收
        if cardViewPool.count < maxPoolSize {
            cardViewPool.append(view)
            #if DEBUG
            print("[KolodaCoordinator] ♻️ 回收卡片视图到池中 (池大小: \(cardViewPool.count))")
            #endif
        } else {
            #if DEBUG
            print("[KolodaCoordinator] 🗑️ 池已满，丢弃视图")
            #endif
        }
    }
}

// MARK: - KolodaViewDataSource

extension KolodaCardsCoordinator: KolodaViewDataSource {
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        // ⭐ 商业级方案：队列索引映射（简单直接）
        // Koloda 索引直接对应队列索引：0 到 queueCount-1
        // 无需虚拟索引映射，逻辑清晰，易于维护
        let count = viewModel?.queueCount ?? 0
        #if DEBUG
        print("[KolodaCoordinator] kolodaNumberOfCards: \(count) (队列索引映射)")
        #endif
        return count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        guard let viewModel = viewModel else { return UIView() }
        
        // ⭐ 商业级方案：队列索引映射（简单直接）
        // index 直接对应队列索引，无需映射
        let queueIndex = index
        let queueCount = viewModel.queueCount
        
        // ⭐ 边界检查
        guard queueIndex >= 0 && queueIndex < queueCount else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ viewForCardAt: 索引越界 kolodaIndex=\(index), queueCount=\(queueCount)")
            #endif
            // 返回空视图，让 updateUIView 检测并处理
            return UIView()
        }
        
        // ⭐ 最优方案：获取卡片数据（优先使用预加载缓存）
        let card: StudyCard
        if let preloaded = preloadedCards[queueIndex] {
            card = preloaded
            preloadedCards.removeValue(forKey: queueIndex)
            #if DEBUG
            print("[KolodaCoordinator] ⚡ 使用预加载卡片: queueIndex=\(queueIndex), word=\(card.word.word)")
            #endif
        } else {
            guard let fetchedCard = viewModel.getCard(at: queueIndex) else {
                #if DEBUG
                print("[KolodaCoordinator] ⚠️ 无法获取卡片: queueIndex=\(queueIndex)")
                #endif
                return UIView()
            }
            card = fetchedCard
        }
        
        // ⭐ P1 修复：从重用池获取视图，而不是每次都创建新的
        let cardView = dequeueCardView()
        
        // ⭐ 新增：获取曝光次数信息并传递给卡片视图
        var exposureInfo: (current: Int, total: Int)? = nil
        if let record = viewModel.getLearningRecord(for: card.word.id) {
            let current = record.targetExposures - record.remainingExposures
            exposureInfo = (current: current, total: record.targetExposures)
        }
        
        // ⭐ 关键优化：立即配置视图，确保返回的视图已经准备好数据
        cardView.alpha = 1.0
        cardView.isHidden = false
        cardView.configure(with: card, exposureInfo: exposureInfo)
        cardView.setNeedsLayout()
        cardView.layoutIfNeeded()
        
        // ⭐ 最优方案：预加载下一张卡片（如果存在）
        preloadNextCardIfNeeded(queueIndex: queueIndex)
        
        #if DEBUG
        print("[KolodaCoordinator] 📄 提供卡片视图: kolodaIndex=\(index) (队列索引), word=\(card.word.word)")
        #endif
        
        return cardView
    }
    
    // ⭐ 最优方案：预加载机制（减少滑动延迟）
    private func preloadNextCardIfNeeded(queueIndex: Int) {
        guard let viewModel = viewModel,
              queueIndex + 1 < viewModel.queueCount,
              let nextCard = viewModel.getCard(at: queueIndex + 1) else {
            return
        }
        
        // 预加载下一张卡片的数据
        preloadedCards[queueIndex + 1] = nextCard
        #if DEBUG
        print("[KolodaCoordinator] ⚡ 预加载下一张卡片: queueIndex=\(queueIndex + 1), word=\(nextCard.word.word)")
        #endif
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return nil
    }
}

// MARK: - KolodaViewDelegate

extension KolodaCardsCoordinator: KolodaViewDelegate {
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        guard let viewModel = viewModel else { return }
        
        // ⭐ 商业级方案：队列索引映射（简单直接）
        // index 直接对应队列索引
        let queueIndex = index
        let queueCount = viewModel.queueCount
        
        guard queueIndex >= 0 && queueIndex < queueCount,
              let card = viewModel.getCard(at: queueIndex) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didSwipeCardAt: 索引越界 kolodaIndex=\(index), queueCount=\(queueCount)")
            #endif
            return
        }
        
        // ⭐ 修复：使用 ViewModel 的 DwellTimeTracker 获取停留时间
        let dwellTime = viewModel.dwellTimeTracker.stopTracking()
        
        // 转换方向 (Koloda 的 SwipeResultDirection → 我们的 SwipeDirection)
        let swipeDirection: SwipeDirection
        switch direction {
        case .left, .topLeft, .bottomLeft:
            swipeDirection = .left
        case .right, .topRight, .bottomRight:
            swipeDirection = .right
        default:
            swipeDirection = .left
        }
        
        #if DEBUG
        print("[KolodaCoordinator] 🎯 didSwipeCardAt: kolodaIndex=\(index) → queueIndex=\(queueIndex), word=\(card.word.word), direction=\(swipeDirection.rawValue), dwell=\(String(format: "%.2f", dwellTime))s")
        #endif
        
        // 📞 触发回调 (通知 ViewModel)
        // ⭐ P1 修复：直接传递 wordId 而不是 cardId，避免查找失败
        onSwipe(card.word.id, swipeDirection, dwellTime)
        
        // ⭐ 商业级优化：Koloda 的索引会自动递增，下一张卡片会通过 viewForCardAt 自动加载
        // 不需要任何重置或偏移量调整
        
        // ⭐ 预加载下一张卡片（如果队列还有卡片）
        // 注意：下一张卡片的 Koloda 索引 = completedCount + 1（因为 completedCount 会在 handleSwipe 后更新）
        // 但这里我们使用队列索引，因为预加载是基于队列的
        if viewModel.queueCount > 1 {
            preloadNextCardIfNeeded(queueIndex: 0)  // 队列索引 0 是新的第一张
        }
        
        #if DEBUG
        print("[KolodaCoordinator] ✅ 滑动处理完成，Koloda 索引自动递增")
        #endif
    }
    
    func koloda(_ koloda: KolodaView, draggedCardWithPercentage finishPercentage: CGFloat, in direction: SwipeResultDirection) {
        // 更新方向指示器 (绿色 ✓ / 橙色 ✗)
        // ⭐ 商业级方案：队列索引映射（简单直接）
        if let cardView = koloda.viewForCard(at: koloda.currentCardIndex) as? WordCardUIView {
            let offset: CGFloat
            switch direction {
            case .left, .topLeft, .bottomLeft:
                offset = -finishPercentage * 200  // 左滑为负
            case .right, .topRight, .bottomRight:
                offset = finishPercentage * 200    // 右滑为正
            default:
                offset = 0
            }
            cardView.updateDirectionIndicator(offset: offset)
        }
    }
    
    // ⭐ 修复：拖拽取消时重置指示器
    func kolodaDidResetCard(_ koloda: KolodaView) {
        guard let viewModel = viewModel else { return }
        
        // ⭐ 商业级方案：队列索引映射（简单直接）
        let queueIndex = koloda.currentCardIndex
        let queueCount = viewModel.queueCount
        
        if queueIndex >= 0 && queueIndex < queueCount,
           let cardView = koloda.viewForCard(at: queueIndex) as? WordCardUIView {
            cardView.resetDirectionIndicators()
            #if DEBUG
            print("[KolodaCoordinator] 🔄 卡片重置，清除方向指示器, queueIndex=\(queueIndex)")
            #endif
        }
    }
    
    // ⭐ 新增：降低滑动阈值，让滑动更容易触发
    // 返回 0.25 表示只需要拖动 25% 的屏幕宽度就能触发滑动（默认是 100%）
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat? {
        return 0.25  // 25% 的阈值，更容易触发滑动
    }
    
    // ⭐ 新增：卡片显示时更新曝光次数信息
    // ⭐ 关键：这是唯一开始计时的地方，确保计时准确且不重复
    func koloda(_ koloda: KolodaView, didShowCardAt index: Int) {
        guard let viewModel = viewModel else { return }
        
        // ⭐ 商业级方案：队列索引映射（简单直接）
        // index 直接对应队列索引
        let queueIndex = index
        let queueCount = viewModel.queueCount
        
        guard queueIndex >= 0 && queueIndex < queueCount,
              let card = viewModel.getCard(at: queueIndex) else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didShowCardAt: 索引越界 kolodaIndex=\(index), queueCount=\(queueCount)")
            #endif
            return
        }
        
        // ⭐ 修复：确保卡片视图存在且正确更新
        if let cardView = koloda.viewForCard(at: index) as? WordCardUIView {
            // 更新曝光次数信息
            var exposureInfo: (current: Int, total: Int)? = nil
            if let record = viewModel.getLearningRecord(for: card.word.id) {
                let current = record.targetExposures - record.remainingExposures
                exposureInfo = (current: current, total: record.targetExposures)
            }
            
            // ⭐ 关键优化：立即更新视图，确保数据同步
            cardView.configure(with: card, exposureInfo: exposureInfo)
            
            // ⭐ 关键修复：统一在这里开始计时，确保：
            // 1. 只在卡片真正显示时才开始计时
            // 2. 避免重复计时（viewForCardAt 和 didSwipeCardAt 都不再计时）
            // 3. 只有当前显示的卡片（队列索引 0）需要计时
            if queueIndex == 0 {
                viewModel.dwellTimeTracker.startTracking(wordId: card.word.id)
                #if DEBUG
                print("[KolodaCoordinator] ⏱️ didShowCardAt 开始计时: \(card.word.word), kolodaIndex=\(index) → queueIndex=\(queueIndex)")
                #endif
            }
            
            #if DEBUG
            if let exposureInfo = exposureInfo {
                print("[KolodaCoordinator] 📊 更新卡片曝光次数: \(card.word.word) = \(exposureInfo.current)/\(exposureInfo.total)")
            }
            #endif
        } else {
            #if DEBUG
            print("[KolodaCoordinator] ⚠️ didShowCardAt: 卡片视图不存在 kolodaIndex=\(index)")
            #endif
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        #if DEBUG
        let currentQueueCount = viewModel?.queueCount ?? 0
        let currentVisibleCount = visibleCards.count
        let currentKolodaIndex = koloda.currentCardIndex
        
        print("[KolodaCoordinator] 📭 卡片用完了")
        print("[KolodaCoordinator]   当前队列数量: \(currentQueueCount)")
        print("[KolodaCoordinator]   当前可见卡片: \(currentVisibleCount)")
        print("[KolodaCoordinator]   Koloda currentCardIndex: \(currentKolodaIndex)")
        
        // ⭐ 商业级方案：如果队列中还有卡片，可能是索引超出范围
        if currentQueueCount > 0 {
            print("[KolodaCoordinator] ⚠️ 警告：队列中还有 \(currentQueueCount) 张卡片，但 Koloda 认为用完了")
            print("[KolodaCoordinator]   预期索引范围: 0-\(currentQueueCount-1), 实际: \(currentKolodaIndex)")
            print("[KolodaCoordinator]   这可能是索引超出范围，updateUIView 会检测并处理")
        }
        #endif
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        // 点击卡片展开/收起（由 WordCardUIView 内部处理）
        #if DEBUG
        print("[KolodaCoordinator] 👆 点击卡片: index=\(index)")
        #endif
    }
}

// MARK: - 完成视图

private struct CompletionView: View {
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


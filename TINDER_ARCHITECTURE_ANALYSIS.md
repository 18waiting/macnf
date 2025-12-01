# Tinder 类应用滑卡架构深度解析

> 本文档基于高级 iOS 开发视角，深度剖析 Tinder 类应用（大规模用户、无限滑动、高性能要求）的滑卡逻辑、数据结构与核心架构设计。这通常是业界实现此类功能的标准范式。

## 1. 核心交互逻辑 (Interaction Logic)

### 1.1 视图层级 (View Hierarchy)
不同于简单的 `ZStack` 堆叠，商业级应用通常采用 **"视图复用池" (View Recycling Pool)** 模式，类似 `UITableView` 的复用机制。

*   **Container View**: 容器视图，负责手势分发和子视图管理。
*   **Visible Stack**: 仅将当前可见的卡片（通常是 Top 3）加入视图层级。
    *   `Top Card`: 完全可交互，响应拖拽、点击。
    *   `Second Card`: 缩放/透明度降低，预备状态。
    *   `Third Card` (可选): 更小的缩放，仅作视觉深度暗示。
    *   *其余卡片*: 即使数据已加载，View 也不创建或不添加到 Window，以节省 GPU 资源。

### 1.2 物理动效 (Physics & Animation)
*   **插值计算 (Interpolation)**: 
    *   **位移 (Translation)**: 跟随手指 `x, y`。
    *   **旋转 (Rotation)**: `rotation = x / constant`。卡片中心点通常设在底部或手指接触点，以产生自然的甩动感。
    *   **缩放 (Scale)**: 后层卡片随着顶层卡片移出，线性插值放大至 1.0。
*   **弹簧动画 (Spring Animation)**: 松手复位时使用高阻尼弹簧动画，模拟真实物理质感。

---

## 2. 数据结构设计 (Data Structures)

### 2.1 双端队列与历史栈 (Deque & History Stack)
为了支持无限滑动（Infinite Scrolling）和"反悔"（Rewind/Undo）功能，通常使用双重数据结构。

```swift
struct CardStackState {
    // 1. 待展示队列 (双端队列，支持头部插入)
    // 使用双端队列是因为 Rewind 时需要将卡片插回头部
    var upcomingCards: Deque<CardModel> 
    
    // 2. 历史栈 (后进先出)
    // 用于存储已滑过的卡片，支持 Rewind
    var historyStack: Stack<HistoryItem>
    
    // 3. 预加载缓冲区
    // 后台线程正在处理的数据
    var prefetchBuffer: [CardModel]
}

struct HistoryItem {
    let card: CardModel
    let action: SwipeAction // 记录是左滑还是右滑，用于恢复状态或统计修正
    let timestamp: Date
}
```

### 2.2 状态机 (State Machine)
卡片的状态流转严谨，避免状态竞争。

*   **Idle**: 静止。
*   **Dragging**: 拖拽中，锁定自动轮播或其他干扰。
*   **AnimatingOut**: 正在飞出（此时数据层可能已经移除，但视图层还在动画）。
*   **Rewinding**: 反悔动画中。
*   **Loading**: 队列枯竭，等待网络请求。

---

## 3. 数据逻辑与流向 (Data Logic & Flow)

### 3.1 预加载机制 (Prefetching Strategy)
不能等到卡片滑完才请求，必须维护一个水位线 (Watermark)。

*   **阈值触发**: 当 `upcomingCards.count < 5` 时，触发下一页请求。
*   **去重逻辑**: 后端通常返回无序流，前端需维护 `Set<CardID>` 避免重复展示同一人。
*   **静默更新**: 新数据到达后，静默追加到 `upcomingCards` 尾部，不影响当前交互。

### 3.2 乐观 UI 更新 (Optimistic UI)
Tinder 的滑动是极速的，不能等待服务器响应。

1.  **用户滑动**: 立即触发 UI 飞出动画。
2.  **本地提交**: 
    *   将卡片移入 `historyStack`。
    *   从 `upcomingCards` 移除。
    *   UI 立即显示下一张。
3.  **异步请求**: 后台线程发送 API (`POST /swipe/like` 或 `pass`)。
4.  **失败处理**: 
    *   如果是网络错误，通常**静默失败**并缓存请求，网络恢复后重试（用户无感知）。
    *   如果是业务错误（如账号封禁），则弹窗阻断。

### 3.3 "反悔" (Rewind) 逻辑
这是付费功能的核心，逻辑如下：
1.  **检查**: `historyStack` 是否为空。
2.  **出栈**: Pop 最近一个 `HistoryItem`。
3.  **入队**: 将 `item.card` 插入 `upcomingCards` 的**头部** (Index 0)。
4.  **UI 动画**: 创建一个新 View，从屏幕边缘（根据 `item.action` 判断方向）逆向飞入屏幕中央。
5.  **API 修正**: 发送撤销请求，后端回滚之前的 Like/Pass 记录。

---

## 4. 性能优化 (Performance Optimization)

### 4.1 离屏渲染与光栅化
*   **问题**: 卡片通常包含圆角、阴影、多张高分辨率图片，混合图层多。
*   **优化**: 
    *   `layer.shouldRasterize = true`: 将静态卡片内容光栅化为位图，滑动时只移动位图，不重绘。
    *   **异步解码**: 图片在后台线程解码，避免主线程卡顿 (Hitch)。

### 4.2 媒体资源管理
*   **预加载**: 当前看第 1 张图时，预加载第 2 张图。当前看 Card A 时，预加载 Card B 的首图。
*   **优先级**: 
    *   Top Card 图片优先级: High
    *   Second Card 图片优先级: Low
    *   History Stack 图片: 立即释放内存。

---

## 5. 总结：与我们当前架构的对比

| 特性 | Tinder 标准架构 | 我们当前架构 (NFwords) | 建议 |
| :--- | :--- | :--- | :--- |
| **数据源** | 无限流 (Pagination) | 有限队列 (Session based) | 保持现状 (背单词场景适合有限队列) |
| **视图管理** | 复用池 (Recycling) | SwiftUI 声明式重建 | SwiftUI 机制已足够高效，暂无需复用池 |
| **反悔逻辑** | 历史栈 + API回滚 | 暂无 | **建议引入历史栈结构以支持撤销功能** |
| **网络同步** | 乐观更新 + 队列重试 | 实时/异步写入数据库 | 保持现状 (本地数据库足够快) |

### 核心洞察
Tinder 的架构是为了解决**海量数据**和**网络延迟**的矛盾。而我们的背单词应用是**本地数据优先**且**会话长度有限**（如一组 20 个词），因此目前的架构是合理的。但如果未来要加入"撤销"功能，必须引入 `HistoryStack` 数据结构。

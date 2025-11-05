//
//  LocalDatabaseModels.swift
//  NFwordsDemo
//
//  前端本地数据表模型（与《数据库表结构梳理.md》对齐）
//  Created by 虚拟助手 on 2025/11/4.
//

import Foundation

// MARK: - 本地词书记录 (对应 local_packs / user_packs 同步结构)
struct LocalPackRecord: Identifiable, Codable, Hashable {
    enum Status: String, Codable {
        case pending
        case learning
        case completed
    }
    
    var id: Int { packId }
    let packId: Int
    var title: String
    var description: String?
    var category: String?
    var level: String?
    var status: Status
    var progressPercent: Double
    var learnedCount: Int
    var totalCount: Int
    var completedAt: Date?
    var entries: [Int]
    var version: String?
    var hash: String?
}

// MARK: - 单词规划记录 (word_plans_local)
struct WordPlanRecord: Identifiable, Codable, Hashable {
    enum PlanType: String, Codable { case automatic, manual }
    enum PlanStatus: String, Codable { case pending, confirmed, started }
    enum SyncStatus: String, Codable { case pending, synced, failed }
    
    var id: UUID
    let packId: Int
    var planType: PlanType
    var planStatus: PlanStatus
    var plannedWordIds: [Int]
    var totalWords: Int
    var learnedWords: Int
    var remainingWords: Int
    var syncStatus: SyncStatus
    var lastSyncAttempt: Date?
    var syncError: String?
    var backendPlanId: Int?
    var wasOffline: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        packId: Int,
        planType: PlanType,
        planStatus: PlanStatus = .pending,
        plannedWordIds: [Int],
        totalWords: Int,
        learnedWords: Int = 0,
        remainingWords: Int,
        syncStatus: SyncStatus = .pending,
        lastSyncAttempt: Date? = nil,
        syncError: String? = nil,
        backendPlanId: Int? = nil,
        wasOffline: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.packId = packId
        self.planType = planType
        self.planStatus = planStatus
        self.plannedWordIds = plannedWordIds
        self.totalWords = totalWords
        self.learnedWords = learnedWords
        self.remainingWords = remainingWords
        self.syncStatus = syncStatus
        self.lastSyncAttempt = lastSyncAttempt
        self.syncError = syncError
        self.backendPlanId = backendPlanId
        self.wasOffline = wasOffline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 单词翻译/短语结构 (用于 WordCacheRecord / 内存缓存)
struct WordTranslationRecord: Codable, Hashable {
    let partOfSpeech: String
    let meaning: String
}

struct WordPhraseRecord: Codable, Hashable {
    let english: String
    let chinese: String
}

// MARK: - 单词缓存 (word_cache)
struct WordCacheRecord: Identifiable, Codable, Hashable {
    var id: Int { wid }
    let wid: Int
    let word: String
    let phonetic: String?
    let translations: [WordTranslationRecord]
    let phrases: [WordPhraseRecord]
    var frequency: Int?
    var lastAccessedAt: Date
    var accessCount: Int
    var cachedAt: Date
}

// MARK: - 单词曝光统计 (word_exposure)
struct WordExposureRecord: Identifiable, Codable, Hashable {
    enum LearningPhase: String, Codable {
        case initial
        case reinforcement
        case consolidation
        case maintenance
    }
    
    var id: UUID
    let packId: Int
    let wid: Int
    var totalExposureCount: Int
    var totalDwellTime: TimeInterval
    var avgDwellTime: TimeInterval
    var familiarity: Double
    var learningPhase: LearningPhase
    var easeFactor: Double
    var learned: Bool
    var firstExposedAt: Date?
    var lastExposedAt: Date?
    var nextExposureAt: Date?
    var inTodayPlan: Bool
    var planDate: Date?
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        packId: Int,
        wid: Int,
        totalExposureCount: Int = 0,
        totalDwellTime: TimeInterval = 0,
        avgDwellTime: TimeInterval = 0,
        familiarity: Double = 0,
        learningPhase: LearningPhase = .initial,
        easeFactor: Double = 2.5,
        learned: Bool = false,
        firstExposedAt: Date? = nil,
        lastExposedAt: Date? = nil,
        nextExposureAt: Date? = nil,
        inTodayPlan: Bool = false,
        planDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.packId = packId
        self.wid = wid
        self.totalExposureCount = totalExposureCount
        self.totalDwellTime = totalDwellTime
        self.avgDwellTime = avgDwellTime
        self.familiarity = familiarity
        self.learningPhase = learningPhase
        self.easeFactor = easeFactor
        self.learned = learned
        self.firstExposedAt = firstExposedAt
        self.lastExposedAt = lastExposedAt
        self.nextExposureAt = nextExposureAt
        self.inTodayPlan = inTodayPlan
        self.planDate = planDate
        self.updatedAt = updatedAt
    }
}

// MARK: - 每日学习计划 (daily_plans)
struct DailyPlanRecord: Identifiable, Codable, Hashable {
    enum Status: String, Codable { case active, completed, cancelled }
    
    var id: UUID
    let planDate: Date
    let packId: Int
    var plannedWordIds: [Int]
    var newWordsCount: Int
    var reviewWordsCount: Int
    var completedCount: Int
    var totalExposureTime: TimeInterval
    var status: Status
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        planDate: Date,
        packId: Int,
        plannedWordIds: [Int],
        newWordsCount: Int,
        reviewWordsCount: Int,
        completedCount: Int = 0,
        totalExposureTime: TimeInterval = 0,
        status: Status = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.planDate = planDate
        self.packId = packId
        self.plannedWordIds = plannedWordIds
        self.newWordsCount = newWordsCount
        self.reviewWordsCount = reviewWordsCount
        self.completedCount = completedCount
        self.totalExposureTime = totalExposureTime
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 曝光事件 (exposure_events_local)
struct ExposureEventRecord: Identifiable, Codable, Hashable {
    enum Interaction: String, Codable {
        case view
        case skip
        case click
        case favorite
    }
    
    var id: UUID
    let packId: Int
    let wid: Int
    let exposureType: String
    let dwellTimeSeconds: TimeInterval
    let interaction: Interaction
    let exposedAt: Date
    let sessionId: String
    let planDate: Date?
    var isReported: Bool
    var reportedAt: Date?
    
    init(
        id: UUID = UUID(),
        packId: Int,
        wid: Int,
        exposureType: String,
        dwellTimeSeconds: TimeInterval,
        interaction: Interaction,
        exposedAt: Date,
        sessionId: String,
        planDate: Date?,
        isReported: Bool = false,
        reportedAt: Date? = nil
    ) {
        self.id = id
        self.packId = packId
        self.wid = wid
        self.exposureType = exposureType
        self.dwellTimeSeconds = dwellTimeSeconds
        self.interaction = interaction
        self.exposedAt = exposedAt
        self.sessionId = sessionId
        self.planDate = planDate
        self.isReported = isReported
        self.reportedAt = reportedAt
    }
}

// MARK: - 内存数据库快照
struct LocalDatabaseSnapshot {
    var packs: [LocalPackRecord]
    var plans: [WordPlanRecord]
    var wordCaches: [Int: WordCacheRecord]
    var exposures: [UUID: WordExposureRecord]
    var dailyPlans: [UUID: DailyPlanRecord]
    var events: [UUID: ExposureEventRecord]
    var goals: [LearningGoal]
    var tasks: [DailyTask]
    var reports: [DailyReport]
    
    static let empty = LocalDatabaseSnapshot(
        packs: [],
        plans: [],
        wordCaches: [:],
        exposures: [:],
        dailyPlans: [:],
        events: [:],
        goals: [],
        tasks: [],
        reports: []
    )
}



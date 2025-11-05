//
//  DatabaseManager.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/5.
//
import Foundation
import SQLite

final class DatabaseManager {
    static let shared = DatabaseManager()
    let db: Connection

    // MARK: Tables
    // local_packs
    let packsTable = Table("local_packs")
    let packId = Expression<Int>("pack_id")
    let title = Expression<String>("title")
    let packDescription = Expression<String?>("description")
    let packCategory = Expression<String?>("category")
    let packLevel = Expression<String?>("level")
    let packStatus = Expression<String>("status")
    let progressPercent = Expression<Double>("progress_percent")
    let totalCount = Expression<Int>("total_count")
    let learnedCount = Expression<Int>("learned_count")
    let hashValue = Expression<String?>("hash")
    let version = Expression<String?>("version")
    let releasedAt = Expression<String?>("released_at")
    let entriesFile = Expression<String?>("entries_file")
    let entriesJSON = Expression<Data?>("entries_json")
    let completedAt = Expression<String?>("completed_at")

    // word_plans_local
    let wordPlansTable = Table("word_plans_local")
    let planId = Expression<String>("id")
    let planPackId = Expression<Int>("pack_id")
    let planType = Expression<String>("plan_type")
    let planStatus = Expression<String>("plan_status")
    let plannedWids = Expression<Data>("planned_wids")
    let planTotalWords = Expression<Int>("total_words")
    let planLearnedWords = Expression<Int>("learned_words")
    let planRemainingWords = Expression<Int>("remaining_words")
    let syncStatus = Expression<String>("sync_status")
    let backendPlanId = Expression<Int?>("backend_plan_id")
    let wasOffline = Expression<Bool>("was_offline")
    let lastSyncAttempt = Expression<String?>("last_sync_attempt")
    let syncError = Expression<String?>("sync_error")
    let createdAt = Expression<String>("created_at")
    let updatedAt = Expression<String>("updated_at")

    // word_exposure
    let wordExposureTable = Table("word_exposure")
    let exposureId = Expression<String>("id")
    let exposurePackId = Expression<Int>("pack_id")
    let wid = Expression<Int>("wid")
    let totalExposureCount = Expression<Int>("total_exposure_count")
    let totalDwellTime = Expression<Double>("total_dwell_time")
    let avgDwellTime = Expression<Double>("avg_dwell_time")
    let familiarity = Expression<Double>("familiarity")
    let learningPhase = Expression<String>("learning_phase")
    let easeFactor = Expression<Double>("ease_factor")
    let learned = Expression<Bool>("learned")
    let firstExposedAt = Expression<String?>("first_exposed_at")
    let lastExposedAt = Expression<String?>("last_exposed_at")
    let nextExposedAt = Expression<String?>("next_exposed_at")
    let inTodayPlan = Expression<Bool>("in_today_plan")
    let planDate = Expression<String?>("plan_date")
    let exposureUpdatedAt = Expression<String>("updated_at")

    // daily_plans
    let dailyPlansTable = Table("daily_plans")
    let dailyPlanId = Expression<String>("id")
    let dailyPlanDate = Expression<String>("plan_date")
    let dailyPlanPackId = Expression<Int>("pack_id")
    let dailyPlanEntries = Expression<Data>("planned_wids")
    let newWordsCount = Expression<Int>("new_words_count")
    let reviewWordsCount = Expression<Int>("review_words_count")
    let completedCount = Expression<Int>("completed_count")
    let totalExposureTime = Expression<Double>("total_exposure_time")
    let dailyStatus = Expression<String>("status")
    let dailyCreatedAt = Expression<String>("created_at")
    let dailyUpdatedAt = Expression<String>("updated_at")

    // exposure_events_local
    let exposureEventsTable = Table("exposure_events_local")
    let eventId = Expression<String>("id")
    let exposurePackIdForEvents = Expression<Int>("pack_id")
    let exposureWidForEvents = Expression<Int>("wid")
    let exposureType = Expression<String>("exposure_type")
    let dwellTimeSeconds = Expression<Double>("dwell_time_seconds")
    let interaction = Expression<String>("interaction")
    let exposedAt = Expression<String>("exposed_at")
    let sessionId = Expression<String>("session_id")
    let eventPlanDate = Expression<String?>("plan_date")
    let isReported = Expression<Bool>("is_reported")
    let reportedAt = Expression<String?>("reported_at")

    // word_cache
    let wordCacheTable = Table("word_cache")
    let cacheWid = Expression<Int>("wid")
    let cacheWord = Expression<String>("word")
    let cachePhonetic = Expression<String?>("phonetic")
    let cacheTranslations = Expression<Data>("translations")
    let cachePhrases = Expression<Data>("phrases")
    let cacheFrequency = Expression<Int?>("frequency")
    let cacheLastAccessed = Expression<String>("last_accessed_at")
    let cacheAccessCount = Expression<Int>("access_count")
    let cacheCreatedAt = Expression<String>("cached_at")

    // packs manifest cache
    let manifestTable = Table("packs_manifest")
    let manifestPackId = Expression<Int>("pack_id")
    let manifestTitle = Expression<String>("title")
    let manifestVersion = Expression<String>("version")
    let manifestHash = Expression<String>("hash")
    let manifestWordsCount = Expression<Int>("words_count")
    let manifestEntriesFile = Expression<String>("entries_file")
    let manifestReleasedAt = Expression<String?>("released_at")
    let manifestSource = Expression<String?>("source")
    let manifestTags = Expression<Data?>("tags_json")

    // learning_goals_local
    let learningGoalsTable = Table("learning_goals_local")
    let goalId = Expression<Int>("id")
    let goalPackId = Expression<Int>("pack_id")
    let goalPackName = Expression<String>("pack_name")
    let goalTotalWords = Expression<Int>("total_words")
    let goalDurationDays = Expression<Int>("duration_days")
    let goalDailyNewWords = Expression<Int>("daily_new_words")
    let goalStartDate = Expression<String>("start_date")
    let goalEndDate = Expression<String>("end_date")
    let goalStatus = Expression<String>("status")
    let goalCurrentDay = Expression<Int>("current_day")
    let goalCompletedWords = Expression<Int>("completed_words")
    let goalCompletedExposures = Expression<Int>("completed_exposures")

    // daily_tasks_local
    let dailyTasksTable = Table("daily_tasks_local")
    let taskId = Expression<Int>("id")
    let taskGoalId = Expression<Int>("goal_id")
    let taskDay = Expression<Int>("day")
    let taskDate = Expression<String>("date")
    let taskNewWords = Expression<Data>("new_words")
    let taskReviewWords = Expression<Data>("review_words")
    let taskTotalExposures = Expression<Int>("total_exposures")
    let taskCompletedExposures = Expression<Int>("completed_exposures")
    let taskStatus = Expression<String>("status")
    let taskStartTime = Expression<String?>("start_time")
    let taskEndTime = Expression<String?>("end_time")

    // daily_reports_local
    let dailyReportsTable = Table("daily_reports_local")
    let reportId = Expression<Int>("id")
    let reportGoalId = Expression<Int>("goal_id")
    let reportDate = Expression<String>("report_date")
    let reportDay = Expression<Int>("day")
    let reportTotalWordsStudied = Expression<Int>("total_words_studied")
    let reportTotalExposures = Expression<Int>("total_exposures")
    let reportStudyDuration = Expression<Double>("study_duration")
    let reportSwipeRightCount = Expression<Int>("swipe_right_count")
    let reportSwipeLeftCount = Expression<Int>("swipe_left_count")
    let reportAvgDwellTime = Expression<Double>("avg_dwell_time")
    let reportSortedByDwellTime = Expression<Data>("sorted_by_dwell_time")
    let reportFamiliarWords = Expression<Data>("familiar_words")
    let reportUnfamiliarWords = Expression<Data>("unfamiliar_words")

    // word_learning_records (补充到 word_exposure 的字段)
    let swipeRightCount = Expression<Int>("swipe_right_count")
    let swipeLeftCount = Expression<Int>("swipe_left_count")
    let remainingExposures = Expression<Int>("remaining_exposures")
    let targetExposures = Expression<Int>("target_exposures")

    private init() {
        let supportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dbURL = supportDir.appendingPathComponent("NFwords.sqlite")
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)

        db = try! Connection(dbURL.path)
        createTablesIfNeeded()
    }

    private func createTablesIfNeeded() {
        // local_packs
        try? db.run(packsTable.create(ifNotExists: true) { t in
            t.column(packId, primaryKey: true)
            t.column(title)
            t.column(packDescription)
            t.column(packCategory)
            t.column(packLevel)
            t.column(packStatus)
            t.column(progressPercent, defaultValue: 0)
            t.column(totalCount)
            t.column(learnedCount, defaultValue: 0)
            t.column(hashValue)
            t.column(version)
            t.column(releasedAt)
            t.column(entriesFile)
            t.column(entriesJSON)
            t.column(completedAt)
        })

        // word_plans_local
        try? db.run(wordPlansTable.create(ifNotExists: true) { t in
            t.column(planId, primaryKey: true)
            t.column(planPackId)
            t.column(planType)
            t.column(planStatus)
            t.column(plannedWids)
            t.column(planTotalWords)
            t.column(planLearnedWords, defaultValue: 0)
            t.column(planRemainingWords)
            t.column(syncStatus)
            t.column(backendPlanId)
            t.column(wasOffline, defaultValue: false)
            t.column(lastSyncAttempt)
            t.column(syncError)
            t.column(createdAt)
            t.column(updatedAt)
        })

        // word_exposure (包含 word_learning_records 的字段)
        try? db.run(wordExposureTable.create(ifNotExists: true) { t in
            t.column(exposureId, primaryKey: true)
            t.column(exposurePackId)
            t.column(wid)
            t.column(totalExposureCount, defaultValue: 0)
            t.column(totalDwellTime, defaultValue: 0)
            t.column(avgDwellTime, defaultValue: 0)
            t.column(familiarity, defaultValue: 0)
            t.column(learningPhase)
            t.column(easeFactor, defaultValue: 2.5)
            t.column(learned, defaultValue: false)
            t.column(firstExposedAt)
            t.column(lastExposedAt)
            t.column(nextExposedAt)
            t.column(inTodayPlan, defaultValue: false)
            t.column(planDate)
            t.column(exposureUpdatedAt)
            // word_learning_records 字段
            t.column(swipeRightCount, defaultValue: 0)
            t.column(swipeLeftCount, defaultValue: 0)
            t.column(remainingExposures, defaultValue: 10)
            t.column(targetExposures, defaultValue: 10)
        })

        // daily_plans
        try? db.run(dailyPlansTable.create(ifNotExists: true) { t in
            t.column(dailyPlanId, primaryKey: true)
            t.column(dailyPlanDate)
            t.column(dailyPlanPackId)
            t.column(dailyPlanEntries)
            t.column(newWordsCount)
            t.column(reviewWordsCount)
            t.column(completedCount, defaultValue: 0)
            t.column(totalExposureTime, defaultValue: 0)
            t.column(dailyStatus)
            t.column(dailyCreatedAt)
            t.column(dailyUpdatedAt)
        })

        // exposure_events_local
        try? db.run(exposureEventsTable.create(ifNotExists: true) { t in
            t.column(eventId, primaryKey: true)
            t.column(exposurePackIdForEvents)
            t.column(exposureWidForEvents)
            t.column(exposureType)
            t.column(dwellTimeSeconds)
            t.column(interaction)
            t.column(exposedAt)
            t.column(sessionId)
            t.column(eventPlanDate)
            t.column(isReported, defaultValue: false)
            t.column(reportedAt)
        })

        // word_cache
        try? db.run(wordCacheTable.create(ifNotExists: true) { t in
            t.column(cacheWid, primaryKey: true)
            t.column(cacheWord)
            t.column(cachePhonetic)
            t.column(cacheTranslations)
            t.column(cachePhrases)
            t.column(cacheFrequency)
            t.column(cacheLastAccessed)
            t.column(cacheAccessCount, defaultValue: 0)
            t.column(cacheCreatedAt)
        })

        // packs_manifest
        try? db.run(manifestTable.create(ifNotExists: true) { t in
            t.column(manifestPackId, primaryKey: true)
            t.column(manifestTitle)
            t.column(manifestVersion)
            t.column(manifestHash)
            t.column(manifestWordsCount)
            t.column(manifestEntriesFile)
            t.column(manifestReleasedAt)
            t.column(manifestSource)
            t.column(manifestTags)
        })

        // learning_goals_local
        try? db.run(learningGoalsTable.create(ifNotExists: true) { t in
            t.column(goalId, primaryKey: .autoincrement)
            t.column(goalPackId)
            t.column(goalPackName)
            t.column(goalTotalWords)
            t.column(goalDurationDays)
            t.column(goalDailyNewWords)
            t.column(goalStartDate)
            t.column(goalEndDate)
            t.column(goalStatus)
            t.column(goalCurrentDay, defaultValue: 1)
            t.column(goalCompletedWords, defaultValue: 0)
            t.column(goalCompletedExposures, defaultValue: 0)
        })

        // daily_tasks_local
        try? db.run(dailyTasksTable.create(ifNotExists: true) { t in
            t.column(taskId, primaryKey: .autoincrement)
            t.column(taskGoalId)
            t.column(taskDay)
            t.column(taskDate)
            t.column(taskNewWords)
            t.column(taskReviewWords)
            t.column(taskTotalExposures)
            t.column(taskCompletedExposures, defaultValue: 0)
            t.column(taskStatus)
            t.column(taskStartTime)
            t.column(taskEndTime)
        })

        // daily_reports_local
        try? db.run(dailyReportsTable.create(ifNotExists: true) { t in
            t.column(reportId, primaryKey: .autoincrement)
            t.column(reportGoalId)
            t.column(reportDate)
            t.column(reportDay)
            t.column(reportTotalWordsStudied)
            t.column(reportTotalExposures)
            t.column(reportStudyDuration)
            t.column(reportSwipeRightCount)
            t.column(reportSwipeLeftCount)
            t.column(reportAvgDwellTime)
            t.column(reportSortedByDwellTime)
            t.column(reportFamiliarWords)
            t.column(reportUnfamiliarWords)
        })
    }

    // MARK: - Public Helpers

    func localPacksCount() throws -> Int {
        try db.scalar(packsTable.count)
    }

    func upsertLocalPack(from entry: PackManifestEntry, status: String = "pending", entries: [Int]? = nil) throws {
        let entriesData = try entries.map { try JSONEncoder().encode($0) }
        let insert = packsTable.insert(or: .replace,
                                       packId <- entry.pid,
                                       title <- entry.title,
                                       packDescription <- entry.description,
                                       packCategory <- entry.category,
                                       packLevel <- entry.level,
                                       packStatus <- status,
                                       progressPercent <- 0,
                                       totalCount <- entry.wordsCount,
                                       learnedCount <- 0,
                                       hashValue <- entry.hash,
                                       version <- entry.version,
                                       releasedAt <- entry.releasedAt,
                                       entriesFile <- entry.entriesFile,
                                       entriesJSON <- entriesData,
                                       completedAt <- nil)
        try db.run(insert)
    }

    func upsertManifestCache(from entry: PackManifestEntry) throws {
        let tagsData = try entry.tags.map { try JSONEncoder().encode($0) }
        let insert = manifestTable.insert(or: .replace,
                                          manifestPackId <- entry.pid,
                                          manifestTitle <- entry.title,
                                          manifestVersion <- entry.version,
                                          manifestHash <- entry.hash,
                                          manifestWordsCount <- entry.wordsCount,
                                          manifestEntriesFile <- entry.entriesFile,
                                          manifestReleasedAt <- entry.releasedAt,
                                          manifestSource <- entry.source,
                                          manifestTags <- tagsData)
        try db.run(insert)
    }
}

// MARK: - Manifest DTO

struct PackManifestEntry: Codable {
    let pid: Int
    let title: String
    let version: String
    let description: String?
    let category: String?
    let level: String?
    let wordsCount: Int
    let hash: String
    let entriesFile: String
    let releasedAt: String?
    let source: String?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case pid
        case title
        case version
        case description
        case category
        case level
        case wordsCount = "words_count"
        case hash
        case entriesFile = "entries_file"
        case releasedAt = "released_at"
        case source
        case tags
    }
}

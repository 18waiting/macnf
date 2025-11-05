//
//  LocalDatabaseStorage.swift
//  NFwordsDemo
//
//  Typed accessors for SQLite tables defined in DatabaseManager.
//

import Foundation
import SQLite

enum LocalDatabaseError: Error {
    case invalidUUID(String)
    case decodingFailed(String)
    case encodingFailed(String)
}

enum DatabaseDateFormatter {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func string(from date: Date?) -> String? {
        guard let date else { return nil }
        return isoFormatter.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string else { return nil }
        return isoFormatter.date(from: string)
    }

    static func nowString() -> String {
        isoFormatter.string(from: Date())
    }

    static func stringOrNow(_ date: Date?) -> String {
        string(from: date) ?? nowString()
    }
}

// MARK: - Local Packs

final class LocalPackStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [LocalPackRecord] {
        let query = manager.packsTable.order(manager.title.asc)
        return try manager.db.prepare(query).map { row in
            let entriesData = row[manager.entriesJSON]
            let entries: [Int]
            if let entriesData {
                do {
                    entries = try decoder.decode([Int].self, from: entriesData)
                } catch {
                    throw LocalDatabaseError.decodingFailed("entries_json for pack #\(row[manager.packId])")
                }
            } else {
                entries = []
            }

            let statusRaw = row[manager.packStatus]
            let status = LocalPackRecord.Status(rawValue: statusRaw) ?? .pending

            return LocalPackRecord(
                packId: row[manager.packId],
                title: row[manager.title],
                description: row[manager.packDescription],
                category: row[manager.packCategory],
                level: row[manager.packLevel],
                status: status,
                progressPercent: row[manager.progressPercent],
                learnedCount: row[manager.learnedCount],
                totalCount: row[manager.totalCount],
                completedAt: DatabaseDateFormatter.date(from: row[manager.completedAt]),
                entries: entries,
                version: row[manager.version],
                hash: row[manager.hashValue]
            )
        }
    }

    func upsert(_ record: LocalPackRecord) throws {
        let entriesData = try encoder.encode(record.entries)
        let insert = manager.packsTable.insert(or: .replace,
                                               manager.packId <- record.packId,
                                               manager.title <- record.title,
                                               manager.packDescription <- record.description,
                                               manager.packCategory <- record.category,
                                               manager.packLevel <- record.level,
                                               manager.packStatus <- record.status.rawValue,
                                               manager.progressPercent <- record.progressPercent,
                                               manager.totalCount <- record.totalCount,
                                               manager.learnedCount <- record.learnedCount,
                                               manager.hashValue <- record.hash,
                                               manager.version <- record.version,
                                               manager.releasedAt <- nil,
                                               manager.entriesFile <- nil,
                                               manager.entriesJSON <- entriesData,
                                               manager.completedAt <- DatabaseDateFormatter.string(from: record.completedAt))
        try manager.db.run(insert)
    }

    func updateProgress(packId: Int, progress: Double, learnedCount: Int, status: LocalPackRecord.Status) throws {
        let pack = manager.packsTable.filter(manager.packId == packId)
        try manager.db.run(pack.update(manager.progressPercent <- progress,
                                       manager.learnedCount <- learnedCount,
                                       manager.packStatus <- status.rawValue))
    }
}

// MARK: - Word Plans

final class WordPlanStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [WordPlanRecord] {
        try manager.db.prepare(manager.wordPlansTable).map { row in
            let idString = row[manager.planId]
            guard let id = UUID(uuidString: idString) else {
                throw LocalDatabaseError.invalidUUID(idString)
            }

            let plannedIds: [Int]
            do {
                plannedIds = try decoder.decode([Int].self, from: row[manager.plannedWids])
            } catch {
                throw LocalDatabaseError.decodingFailed("planned_wids for plan #\(idString)")
            }

            return WordPlanRecord(
                id: id,
                packId: row[manager.planPackId],
                planType: WordPlanRecord.PlanType(rawValue: row[manager.planType]) ?? .automatic,
                planStatus: WordPlanRecord.PlanStatus(rawValue: row[manager.planStatus]) ?? .pending,
                plannedWordIds: plannedIds,
                totalWords: row[manager.planTotalWords],
                learnedWords: row[manager.planLearnedWords],
                remainingWords: row[manager.planRemainingWords],
                syncStatus: WordPlanRecord.SyncStatus(rawValue: row[manager.syncStatus]) ?? .pending,
                lastSyncAttempt: DatabaseDateFormatter.date(from: row[manager.lastSyncAttempt]),
                syncError: row[manager.syncError],
                backendPlanId: row[manager.backendPlanId],
                wasOffline: row[manager.wasOffline],
                createdAt: DatabaseDateFormatter.date(from: row[manager.createdAt]) ?? Date(),
                updatedAt: DatabaseDateFormatter.date(from: row[manager.updatedAt]) ?? Date()
            )
        }
    }

    func upsert(_ record: WordPlanRecord) throws {
        let idsData = try encoder.encode(record.plannedWordIds)
        let insert = manager.wordPlansTable.insert(or: .replace,
                                                   manager.planId <- record.id.uuidString,
                                                   manager.planPackId <- record.packId,
                                                   manager.planType <- record.planType.rawValue,
                                                   manager.planStatus <- record.planStatus.rawValue,
                                                   manager.plannedWids <- idsData,
                                                   manager.planTotalWords <- record.totalWords,
                                                   manager.planLearnedWords <- record.learnedWords,
                                                   manager.planRemainingWords <- record.remainingWords,
                                                   manager.syncStatus <- record.syncStatus.rawValue,
                                                   manager.backendPlanId <- record.backendPlanId,
                                                   manager.wasOffline <- record.wasOffline,
                                                   manager.lastSyncAttempt <- DatabaseDateFormatter.string(from: record.lastSyncAttempt),
                                                   manager.syncError <- record.syncError,
                                                   manager.createdAt <- DatabaseDateFormatter.stringOrNow(record.createdAt),
                                                   manager.updatedAt <- DatabaseDateFormatter.stringOrNow(record.updatedAt))
        try manager.db.run(insert)
    }
}

// MARK: - Word Exposure

final class WordExposureStorage {
    private let manager = DatabaseManager.shared

    func fetchAll() throws -> [WordExposureRecord] {
        try manager.db.prepare(manager.wordExposureTable).map { row in
            let idString = row[manager.exposureId]
            guard let id = UUID(uuidString: idString) else {
                throw LocalDatabaseError.invalidUUID(idString)
            }

            return WordExposureRecord(
                id: id,
                packId: row[manager.exposurePackId],
                wid: row[manager.wid],
                totalExposureCount: row[manager.totalExposureCount],
                totalDwellTime: row[manager.totalDwellTime],
                avgDwellTime: row[manager.avgDwellTime],
                familiarity: row[manager.familiarity],
                learningPhase: WordExposureRecord.LearningPhase(rawValue: row[manager.learningPhase]) ?? .initial,
                easeFactor: row[manager.easeFactor],
                learned: row[manager.learned],
                firstExposedAt: DatabaseDateFormatter.date(from: row[manager.firstExposedAt]),
                lastExposedAt: DatabaseDateFormatter.date(from: row[manager.lastExposedAt]),
                nextExposureAt: DatabaseDateFormatter.date(from: row[manager.nextExposedAt]),
                inTodayPlan: row[manager.inTodayPlan],
                planDate: DatabaseDateFormatter.date(from: row[manager.planDate]),
                updatedAt: DatabaseDateFormatter.date(from: row[manager.exposureUpdatedAt]) ?? Date()
            )
        }
    }
    
    func upsert(_ record: WordExposureRecord) throws {
        let insert = manager.wordExposureTable.insert(or: .replace,
            manager.exposureId <- record.id.uuidString,
            manager.exposurePackId <- record.packId,
            manager.wid <- record.wid,
            manager.totalExposureCount <- record.totalExposureCount,
            manager.totalDwellTime <- record.totalDwellTime,
            manager.avgDwellTime <- record.avgDwellTime,
            manager.familiarity <- record.familiarity,
            manager.learningPhase <- record.learningPhase.rawValue,
            manager.easeFactor <- record.easeFactor,
            manager.learned <- record.learned,
            manager.firstExposedAt <- DatabaseDateFormatter.string(from: record.firstExposedAt),
            manager.lastExposedAt <- DatabaseDateFormatter.string(from: record.lastExposedAt),
            manager.nextExposedAt <- DatabaseDateFormatter.string(from: record.nextExposureAt),
            manager.inTodayPlan <- record.inTodayPlan,
            manager.planDate <- DatabaseDateFormatter.string(from: record.planDate),
            manager.exposureUpdatedAt <- DatabaseDateFormatter.nowString(),
            // word_learning_records 字段（从 WordLearningRecord 转换）
            manager.swipeRightCount <- 0,  // 需要从 learningRecord 传入
            manager.swipeLeftCount <- 0,
            manager.remainingExposures <- 10,
            manager.targetExposures <- 10
        )
        try manager.db.run(insert)
    }
    
    func saveFromLearningRecord(packId: Int, learningRecord: WordLearningRecord) throws {
        let now = Date()
        let record = WordExposureRecord(
            id: UUID(),
            packId: packId,
            wid: learningRecord.id,
            totalExposureCount: learningRecord.totalExposureCount,
            totalDwellTime: learningRecord.totalDwellTime,
            avgDwellTime: learningRecord.avgDwellTime,
            familiarity: Double(learningRecord.familiarityScore) / 100.0,
            learningPhase: .initial,
            easeFactor: 2.5,
            learned: learningRecord.isMastered,
            firstExposedAt: learningRecord.totalExposureCount == 0 ? now : nil,
            lastExposedAt: now,
            nextExposureAt: nil,
            inTodayPlan: false,
            planDate: now,
            updatedAt: now
        )
        
        let insert = manager.wordExposureTable.insert(or: .replace,
            manager.exposureId <- record.id.uuidString,
            manager.exposurePackId <- record.packId,
            manager.wid <- record.wid,
            manager.totalExposureCount <- record.totalExposureCount,
            manager.totalDwellTime <- record.totalDwellTime,
            manager.avgDwellTime <- record.avgDwellTime,
            manager.familiarity <- record.familiarity,
            manager.learningPhase <- record.learningPhase.rawValue,
            manager.easeFactor <- record.easeFactor,
            manager.learned <- record.learned,
            manager.firstExposedAt <- DatabaseDateFormatter.string(from: record.firstExposedAt),
            manager.lastExposedAt <- DatabaseDateFormatter.stringOrNow(record.lastExposedAt),
            manager.nextExposedAt <- DatabaseDateFormatter.string(from: record.nextExposureAt),
            manager.inTodayPlan <- record.inTodayPlan,
            manager.planDate <- DatabaseDateFormatter.string(from: record.planDate),
            manager.exposureUpdatedAt <- DatabaseDateFormatter.nowString(),
            // word_learning_records 字段
            manager.swipeRightCount <- learningRecord.swipeRightCount,
            manager.swipeLeftCount <- learningRecord.swipeLeftCount,
            manager.remainingExposures <- learningRecord.remainingExposures,
            manager.targetExposures <- learningRecord.targetExposures
        )
        try manager.db.run(insert)
    }
    
    func batchSaveFromLearningRecords(packId: Int, records: [Int: WordLearningRecord]) throws {
        for (_, record) in records {
            try saveFromLearningRecord(packId: packId, learningRecord: record)
        }
    }
}

// MARK: - Daily Plans

final class DailyPlanStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [DailyPlanRecord] {
        try manager.db.prepare(manager.dailyPlansTable).map { row in
            let idString = row[manager.dailyPlanId]
            guard let id = UUID(uuidString: idString) else {
                throw LocalDatabaseError.invalidUUID(idString)
            }

            let plannedIds: [Int]
            do {
                plannedIds = try decoder.decode([Int].self, from: row[manager.dailyPlanEntries])
            } catch {
                throw LocalDatabaseError.decodingFailed("planned_wids for daily plan #\(idString)")
            }

            return DailyPlanRecord(
                id: id,
                planDate: DatabaseDateFormatter.date(from: row[manager.dailyPlanDate]) ?? Date(),
                packId: row[manager.dailyPlanPackId],
                plannedWordIds: plannedIds,
                newWordsCount: row[manager.newWordsCount],
                reviewWordsCount: row[manager.reviewWordsCount],
                completedCount: row[manager.completedCount],
                totalExposureTime: row[manager.totalExposureTime],
                status: DailyPlanRecord.Status(rawValue: row[manager.dailyStatus]) ?? .active,
                createdAt: DatabaseDateFormatter.date(from: row[manager.dailyCreatedAt]) ?? Date(),
                updatedAt: DatabaseDateFormatter.date(from: row[manager.dailyUpdatedAt]) ?? Date()
            )
        }
    }

    func upsert(_ record: DailyPlanRecord) throws {
        let plannedData = try encoder.encode(record.plannedWordIds)
        let insert = manager.dailyPlansTable.insert(or: .replace,
                                                   manager.dailyPlanId <- record.id.uuidString,
                                                   manager.dailyPlanDate <- DatabaseDateFormatter.stringOrNow(record.planDate),
                                                   manager.dailyPlanPackId <- record.packId,
                                                   manager.dailyPlanEntries <- plannedData,
                                                   manager.newWordsCount <- record.newWordsCount,
                                                   manager.reviewWordsCount <- record.reviewWordsCount,
                                                   manager.completedCount <- record.completedCount,
                                                   manager.totalExposureTime <- record.totalExposureTime,
                                                   manager.dailyStatus <- record.status.rawValue,
                                                   manager.dailyCreatedAt <- DatabaseDateFormatter.stringOrNow(record.createdAt),
                                                   manager.dailyUpdatedAt <- DatabaseDateFormatter.stringOrNow(record.updatedAt))
        try manager.db.run(insert)
    }
}

// MARK: - Exposure Events

final class ExposureEventStorage {
    private let manager = DatabaseManager.shared

    func fetchAll() throws -> [ExposureEventRecord] {
        try manager.db.prepare(manager.exposureEventsTable).map { row in
            let idString = row[manager.eventId]
            guard let id = UUID(uuidString: idString) else {
                throw LocalDatabaseError.invalidUUID(idString)
            }

            let interactionRaw = row[manager.interaction]
            let interaction = ExposureEventRecord.Interaction(rawValue: interactionRaw) ?? .view

            return ExposureEventRecord(
                id: id,
                packId: row[manager.exposurePackIdForEvents],
                wid: row[manager.exposureWidForEvents],
                exposureType: row[manager.exposureType],
                dwellTimeSeconds: row[manager.dwellTimeSeconds],
                interaction: interaction,
                exposedAt: DatabaseDateFormatter.date(from: row[manager.exposedAt]) ?? Date(),
                sessionId: row[manager.sessionId],
                planDate: DatabaseDateFormatter.date(from: row[manager.eventPlanDate]),
                isReported: row[manager.isReported],
                reportedAt: DatabaseDateFormatter.date(from: row[manager.reportedAt])
            )
        }
    }
    
    func insert(_ event: ExposureEventRecord) throws -> Int64 {
        let insert = manager.exposureEventsTable.insert(
            manager.eventId <- event.id.uuidString,
            manager.exposurePackIdForEvents <- event.packId,
            manager.exposureWidForEvents <- event.wid,
            manager.exposureType <- event.exposureType,
            manager.dwellTimeSeconds <- event.dwellTimeSeconds,
            manager.interaction <- event.interaction.rawValue,
            manager.exposedAt <- DatabaseDateFormatter.stringOrNow(event.exposedAt),
            manager.sessionId <- event.sessionId,
            manager.eventPlanDate <- DatabaseDateFormatter.string(from: event.planDate),
            manager.isReported <- event.isReported,
            manager.reportedAt <- DatabaseDateFormatter.string(from: event.reportedAt)
        )
        return try manager.db.run(insert)
    }
    
    func recordSwipe(packId: Int, wid: Int, direction: SwipeDirection, dwellTime: TimeInterval, sessionId: String) throws {
        let event = ExposureEventRecord(
            id: UUID(),
            packId: packId,
            wid: wid,
            exposureType: "flashcard",
            dwellTimeSeconds: dwellTime,
            interaction: .view,
            exposedAt: Date(),
            sessionId: sessionId,
            planDate: Date(),
            isReported: false,
            reportedAt: nil
        )
        _ = try insert(event)
    }
}

// MARK: - Learning Goals

final class LearningGoalStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [LearningGoal] {
        try manager.db.prepare(manager.learningGoalsTable).map { row in
            LearningGoal(
                id: row[manager.goalId],
                packId: row[manager.goalPackId],
                packName: row[manager.goalPackName],
                totalWords: row[manager.goalTotalWords],
                durationDays: row[manager.goalDurationDays],
                dailyNewWords: row[manager.goalDailyNewWords],
                startDate: DatabaseDateFormatter.date(from: row[manager.goalStartDate]) ?? Date(),
                endDate: DatabaseDateFormatter.date(from: row[manager.goalEndDate]) ?? Date(),
                status: GoalStatus(rawValue: row[manager.goalStatus]) ?? .inProgress,
                currentDay: row[manager.goalCurrentDay],
                completedWords: row[manager.goalCompletedWords],
                completedExposures: row[manager.goalCompletedExposures]
            )
        }
    }

    func fetchCurrent() throws -> LearningGoal? {
        let query = manager.learningGoalsTable
            .filter(manager.goalStatus == GoalStatus.inProgress.rawValue)
            .order(manager.goalId.desc)
            .limit(1)
        return try manager.db.prepare(query).map { row in
            LearningGoal(
                id: row[manager.goalId],
                packId: row[manager.goalPackId],
                packName: row[manager.goalPackName],
                totalWords: row[manager.goalTotalWords],
                durationDays: row[manager.goalDurationDays],
                dailyNewWords: row[manager.goalDailyNewWords],
                startDate: DatabaseDateFormatter.date(from: row[manager.goalStartDate]) ?? Date(),
                endDate: DatabaseDateFormatter.date(from: row[manager.goalEndDate]) ?? Date(),
                status: GoalStatus(rawValue: row[manager.goalStatus]) ?? .inProgress,
                currentDay: row[manager.goalCurrentDay],
                completedWords: row[manager.goalCompletedWords],
                completedExposures: row[manager.goalCompletedExposures]
            )
        }.first
    }

    func insert(_ goal: LearningGoal) throws -> Int64 {
        let insert = manager.learningGoalsTable.insert(
            manager.goalPackId <- goal.packId,
            manager.goalPackName <- goal.packName,
            manager.goalTotalWords <- goal.totalWords,
            manager.goalDurationDays <- goal.durationDays,
            manager.goalDailyNewWords <- goal.dailyNewWords,
            manager.goalStartDate <- DatabaseDateFormatter.stringOrNow(goal.startDate),
            manager.goalEndDate <- DatabaseDateFormatter.stringOrNow(goal.endDate),
            manager.goalStatus <- goal.status.rawValue,
            manager.goalCurrentDay <- goal.currentDay,
            manager.goalCompletedWords <- goal.completedWords,
            manager.goalCompletedExposures <- goal.completedExposures
        )
        return try manager.db.run(insert)
    }

    func update(_ goal: LearningGoal) throws {
        let record = manager.learningGoalsTable.filter(manager.goalId == goal.id)
        try manager.db.run(record.update(
            manager.goalStatus <- goal.status.rawValue,
            manager.goalCurrentDay <- goal.currentDay,
            manager.goalCompletedWords <- goal.completedWords,
            manager.goalCompletedExposures <- goal.completedExposures
        ))
    }
}

// MARK: - Daily Tasks

final class DailyTaskStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [DailyTask] {
        try manager.db.prepare(manager.dailyTasksTable).map { row in
            let newWords = try decoder.decode([Int].self, from: row[manager.taskNewWords])
            let reviewWords = try decoder.decode([Int].self, from: row[manager.taskReviewWords])
            
            return DailyTask(
                id: row[manager.taskId],
                goalId: row[manager.taskGoalId],
                day: row[manager.taskDay],
                date: DatabaseDateFormatter.date(from: row[manager.taskDate]) ?? Date(),
                newWords: newWords,
                reviewWords: reviewWords,
                totalExposures: row[manager.taskTotalExposures],
                completedExposures: row[manager.taskCompletedExposures],
                status: TaskStatus(rawValue: row[manager.taskStatus]) ?? .pending,
                startTime: DatabaseDateFormatter.date(from: row[manager.taskStartTime]),
                endTime: DatabaseDateFormatter.date(from: row[manager.taskEndTime])
            )
        }
    }

    func fetchToday() throws -> DailyTask? {
        let todayStr = DatabaseDateFormatter.string(from: Date()) ?? ""
        let query = manager.dailyTasksTable
            .filter(manager.taskDate == todayStr)
            .limit(1)
        return try manager.db.prepare(query).compactMap { row in
            let newWords = try? decoder.decode([Int].self, from: row[manager.taskNewWords])
            let reviewWords = try? decoder.decode([Int].self, from: row[manager.taskReviewWords])
            
            return DailyTask(
                id: row[manager.taskId],
                goalId: row[manager.taskGoalId],
                day: row[manager.taskDay],
                date: DatabaseDateFormatter.date(from: row[manager.taskDate]) ?? Date(),
                newWords: newWords ?? [],
                reviewWords: reviewWords ?? [],
                totalExposures: row[manager.taskTotalExposures],
                completedExposures: row[manager.taskCompletedExposures],
                status: TaskStatus(rawValue: row[manager.taskStatus]) ?? .pending,
                startTime: DatabaseDateFormatter.date(from: row[manager.taskStartTime]),
                endTime: DatabaseDateFormatter.date(from: row[manager.taskEndTime])
            )
        }.first
    }

    func insert(_ task: DailyTask) throws -> Int64 {
        let newWordsData = try encoder.encode(task.newWords)
        let reviewWordsData = try encoder.encode(task.reviewWords)
        
        let insert = manager.dailyTasksTable.insert(
            manager.taskGoalId <- task.goalId,
            manager.taskDay <- task.day,
            manager.taskDate <- DatabaseDateFormatter.stringOrNow(task.date),
            manager.taskNewWords <- newWordsData,
            manager.taskReviewWords <- reviewWordsData,
            manager.taskTotalExposures <- task.totalExposures,
            manager.taskCompletedExposures <- task.completedExposures,
            manager.taskStatus <- task.status.rawValue,
            manager.taskStartTime <- DatabaseDateFormatter.string(from: task.startTime),
            manager.taskEndTime <- DatabaseDateFormatter.string(from: task.endTime)
        )
        return try manager.db.run(insert)
    }

    func update(_ task: DailyTask) throws {
        let record = manager.dailyTasksTable.filter(manager.taskId == task.id)
        try manager.db.run(record.update(
            manager.taskCompletedExposures <- task.completedExposures,
            manager.taskStatus <- task.status.rawValue,
            manager.taskStartTime <- DatabaseDateFormatter.string(from: task.startTime),
            manager.taskEndTime <- DatabaseDateFormatter.string(from: task.endTime)
        ))
    }
}

// MARK: - Daily Reports

final class DailyReportStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [DailyReport] {
        try manager.db.prepare(manager.dailyReportsTable).map { row in
            let sortedWords = try decoder.decode([WordSummary].self, from: row[manager.reportSortedByDwellTime])
            let familiarWords = try decoder.decode([Int].self, from: row[manager.reportFamiliarWords])
            let unfamiliarWords = try decoder.decode([Int].self, from: row[manager.reportUnfamiliarWords])
            
            return DailyReport(
                id: row[manager.reportId],
                goalId: row[manager.reportGoalId],
                reportDate: DatabaseDateFormatter.date(from: row[manager.reportDate]) ?? Date(),
                day: row[manager.reportDay],
                totalWordsStudied: row[manager.reportTotalWordsStudied],
                totalExposures: row[manager.reportTotalExposures],
                studyDuration: row[manager.reportStudyDuration],
                swipeRightCount: row[manager.reportSwipeRightCount],
                swipeLeftCount: row[manager.reportSwipeLeftCount],
                avgDwellTime: row[manager.reportAvgDwellTime],
                sortedByDwellTime: sortedWords,
                familiarWords: familiarWords,
                unfamiliarWords: unfamiliarWords
            )
        }
    }

    func fetchLatest() throws -> DailyReport? {
        let query = manager.dailyReportsTable
            .order(manager.reportId.desc)
            .limit(1)
        return try manager.db.prepare(query).compactMap { row in
            let sortedWords = try? decoder.decode([WordSummary].self, from: row[manager.reportSortedByDwellTime])
            let familiarWords = try? decoder.decode([Int].self, from: row[manager.reportFamiliarWords])
            let unfamiliarWords = try? decoder.decode([Int].self, from: row[manager.reportUnfamiliarWords])
            
            return DailyReport(
                id: row[manager.reportId],
                goalId: row[manager.reportGoalId],
                reportDate: DatabaseDateFormatter.date(from: row[manager.reportDate]) ?? Date(),
                day: row[manager.reportDay],
                totalWordsStudied: row[manager.reportTotalWordsStudied],
                totalExposures: row[manager.reportTotalExposures],
                studyDuration: row[manager.reportStudyDuration],
                swipeRightCount: row[manager.reportSwipeRightCount],
                swipeLeftCount: row[manager.reportSwipeLeftCount],
                avgDwellTime: row[manager.reportAvgDwellTime],
                sortedByDwellTime: sortedWords ?? [],
                familiarWords: familiarWords ?? [],
                unfamiliarWords: unfamiliarWords ?? []
            )
        }.first
    }

    func insert(_ report: DailyReport) throws -> Int64 {
        let sortedData = try encoder.encode(report.sortedByDwellTime)
        let familiarData = try encoder.encode(report.familiarWords)
        let unfamiliarData = try encoder.encode(report.unfamiliarWords)
        
        let insert = manager.dailyReportsTable.insert(
            manager.reportGoalId <- report.goalId,
            manager.reportDate <- DatabaseDateFormatter.stringOrNow(report.reportDate),
            manager.reportDay <- report.day,
            manager.reportTotalWordsStudied <- report.totalWordsStudied,
            manager.reportTotalExposures <- report.totalExposures,
            manager.reportStudyDuration <- report.studyDuration,
            manager.reportSwipeRightCount <- report.swipeRightCount,
            manager.reportSwipeLeftCount <- report.swipeLeftCount,
            manager.reportAvgDwellTime <- report.avgDwellTime,
            manager.reportSortedByDwellTime <- sortedData,
            manager.reportFamiliarWords <- familiarData,
            manager.reportUnfamiliarWords <- unfamiliarData
        )
        return try manager.db.run(insert)
    }
}

// MARK: - Word Cache

final class WordCacheStorage {
    private let manager = DatabaseManager.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchAll() throws -> [WordCacheRecord] {
        try manager.db.prepare(manager.wordCacheTable).map { row in
            let translations: [WordTranslationRecord]
            let phrases: [WordPhraseRecord]
            do {
                translations = try decoder.decode([WordTranslationRecord].self, from: row[manager.cacheTranslations])
                phrases = try decoder.decode([WordPhraseRecord].self, from: row[manager.cachePhrases])
            } catch {
                throw LocalDatabaseError.decodingFailed("word_cache blob for wid #\(row[manager.cacheWid])")
            }

            return WordCacheRecord(
                wid: row[manager.cacheWid],
                word: row[manager.cacheWord],
                phonetic: row[manager.cachePhonetic],
                translations: translations,
                phrases: phrases,
                frequency: row[manager.cacheFrequency],
                lastAccessedAt: DatabaseDateFormatter.date(from: row[manager.cacheLastAccessed]) ?? Date(),
                accessCount: row[manager.cacheAccessCount],
                cachedAt: DatabaseDateFormatter.date(from: row[manager.cacheCreatedAt]) ?? Date()
            )
        }
    }

    func upsert(_ record: WordCacheRecord) throws {
        do {
            let translationsData = try encoder.encode(record.translations)
            let phrasesData = try encoder.encode(record.phrases)
            let insert = manager.wordCacheTable.insert(or: .replace,
                                                      manager.cacheWid <- record.wid,
                                                      manager.cacheWord <- record.word,
                                                      manager.cachePhonetic <- record.phonetic,
                                                      manager.cacheTranslations <- translationsData,
                                                      manager.cachePhrases <- phrasesData,
                                                      manager.cacheFrequency <- record.frequency,
                                                      manager.cacheLastAccessed <- DatabaseDateFormatter.stringOrNow(record.lastAccessedAt),
                                                      manager.cacheAccessCount <- record.accessCount,
                                                      manager.cacheCreatedAt <- DatabaseDateFormatter.stringOrNow(record.cachedAt))
            try manager.db.run(insert)
        } catch {
            throw LocalDatabaseError.encodingFailed("word_cache upsert for wid #\(record.wid)")
        }
    }
}


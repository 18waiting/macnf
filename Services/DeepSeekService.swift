//
//  DeepSeekService.swift
//  NFwordsDemo
//
//  DeepSeek AI服务 - 微场景和考研短文生成
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

// MARK: - DeepSeek AI服务
class DeepSeekService {
    static let shared = DeepSeekService()
    
    private let session: URLSession
    private var requestCount = 0
    private var lastResetDate = Date()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = DeepSeekConfig.timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 生成微场景
    func generateMicroScene(for word: String) async throws -> String {
        // 检查限额
        guard canMakeRequest() else {
            throw DeepSeekError.quotaExceeded
        }
        
        let prompt = DeepSeekConfig.microScenePrompt(for: word)
        
        let request = DeepSeekRequest(
            model: DeepSeekConfig.model,
            messages: [
                .init(role: "system", content: "You are an English learning assistant that creates immersive micro-scenarios."),
                .init(role: "user", content: prompt)
            ],
            temperature: DeepSeekConfig.MicroSceneConfig.temperature,
            maxTokens: DeepSeekConfig.MicroSceneConfig.maxTokens
        )
        
        let response = try await callAPI(request: request)
        requestCount += 1
        
        return response.choices.first?.message.content ?? ""
    }
    
    // MARK: - 生成考研风格短文 ⭐ 核心功能
    func generateReadingPassage(difficultWords: [String], topic: Topic = .auto) async throws -> ReadingPassage {
        // 检查限额
        guard canMakeRequest() else {
            throw DeepSeekError.quotaExceeded
        }
        
        let prompt = DeepSeekConfig.articlePrompt(with: difficultWords)
        
        let request = DeepSeekRequest(
            model: DeepSeekConfig.model,
            messages: [
                .init(role: "system", content: "You are an expert at creating academic English passages suitable for Chinese postgraduate entrance exams."),
                .init(role: "user", content: prompt)
            ],
            temperature: DeepSeekConfig.ArticleConfig.temperature,
            maxTokens: DeepSeekConfig.ArticleConfig.maxTokens
        )
        
        let response = try await callAPI(request: request)
        requestCount += 1
        
        let content = response.choices.first?.message.content ?? ""
        
        // 创建ReadingPassage对象
        let passage = ReadingPassage(
            id: UUID(),
            content: content,
            targetWords: difficultWords,
            targetWordIds: [],  // 实际应用中需要传入wordIds
            wordCount: countWords(content),
            difficulty: .postgraduate,
            topic: topic == .auto ? detectTopic(content) : topic,
            createdAt: Date(),
            isFavorite: false
        )
        
        return passage
    }
    
    // MARK: - API调用
    private func callAPI(request: DeepSeekRequest) async throws -> DeepSeekResponse {
        guard let url = URL(string: DeepSeekConfig.baseURL) else {
            throw DeepSeekError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(DeepSeekConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)
        
        print("🤖 调用DeepSeek API...")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw DeepSeekError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let deepSeekResponse = try decoder.decode(DeepSeekResponse.self, from: data)
        
        print("✅ DeepSeek响应成功")
        print("📝 Tokens使用: \(deepSeekResponse.usage.totalTokens)")
        
        return deepSeekResponse
    }
    
    // MARK: - 限额检查
    private func canMakeRequest() -> Bool {
        // 检查是否需要重置计数器
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: Date()) {
            requestCount = 0
            lastResetDate = Date()
        }
        
        return requestCount < DeepSeekConfig.maxRequestsPerDay
    }
    
    // MARK: - 辅助方法
    
    /// 统计单词数
    private func countWords(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    /// 检测主题（简单实现）
    private func detectTopic(_ text: String) -> Topic {
        let lowerText = text.lowercased()
        
        if lowerText.contains("economy") || lowerText.contains("business") || lowerText.contains("market") {
            return .economy
        } else if lowerText.contains("technology") || lowerText.contains("digital") || lowerText.contains("innovation") {
            return .technology
        } else if lowerText.contains("education") || lowerText.contains("student") || lowerText.contains("learning") {
            return .education
        } else if lowerText.contains("environment") || lowerText.contains("climate") || lowerText.contains("pollution") {
            return .environment
        } else if lowerText.contains("society") || lowerText.contains("social") || lowerText.contains("community") {
            return .social
        } else {
            return .culture
        }
    }
}

// MARK: - DeepSeek错误类型
enum DeepSeekError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case quotaExceeded
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .quotaExceeded:
            return "今日请求次数已达上限"
        case .decodingError:
            return "解析响应失败"
        }
    }
}


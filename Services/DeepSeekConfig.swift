//
//  DeepSeekConfig.swift
//  NFwordsDemo
//
//  DeepSeek API配置
//  Created by 甘名杨 on 2025/11/3.
//

import Foundation

struct DeepSeekConfig {
    // MARK: - API配置
    
    /// DeepSeek API Key
    static let apiKey = "sk-ca514461699d4d39bd03936acfaa6616"
    
    /// API基础URL
    static let baseURL = "https://api.deepseek.com/v1/chat/completions"
    
    /// 使用的模型
    static let model = "deepseek-chat"
    
    /// 请求超时时间（秒）
    static let timeout: TimeInterval = 30.0
    
    // MARK: - 限流配置
    
    /// 每天最多请求次数
    static let maxRequestsPerDay = 100
    
    /// 每天最多生成微场景次数
    static let maxMicroScenesPerDay = 20
    
    /// 每天最多生成短文次数
    static let maxArticlesPerDay = 10
    
    // MARK: - 缓存配置
    
    /// 缓存有效期（天）
    static let cacheExpirationDays = 7
    
    // MARK: - Prompt模板
    
    /// 微场景生成Prompt
    static func microScenePrompt(for word: String) -> String {
        return """
        Generate a micro-scene sentence (80-120 characters) for the word "\(word)".
        Requirements:
        - Use second person ("You...")
        - Create an immersive scenario
        - Natural, conversational English
        - NO Chinese, NO explanation
        
        Example: "You stand on the platform in absolute silence; the announcement is barely audible."
        
        Word: \(word)
        Micro-scene:
        """
    }
    
    /// 考研短文生成Prompt
    static func articlePrompt(with words: [String]) -> String {
        let wordList = words.joined(separator: ", ")
        return """
        Create an English reading passage suitable for Chinese postgraduate entrance exam (考研).
        
        Requirements:
        1. Length: 300-400 words
        2. Style: Academic, formal, similar to The Economist or Scientific American
        3. Topic: Choose from - social issues, technology, economy, education, environment
        4. Structure: Introduction → Development → Discussion → Conclusion
        5. Must naturally include these words: \(wordList)
        6. Difficulty level: CET-6 to postgraduate level
        7. Use complex sentences and academic vocabulary
        8. Include logical connectors
        9. NO Chinese translation, English only
        
        The passage should present a clear argument or phenomenon suitable for comprehension questions.
        
        Generate the passage:
        """
    }
    
    // MARK: - 环境变量支持（生产环境）
    
    /// 从环境变量获取API Key（生产环境推荐）
    static var apiKeyFromEnv: String {
        return ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? apiKey
    }
    
    // MARK: - API请求配置
    
    /// 微场景生成配置
    struct MicroSceneConfig {
        static let temperature: Double = 0.7
        static let maxTokens: Int = 100
    }
    
    /// 短文生成配置
    struct ArticleConfig {
        static let temperature: Double = 0.7
        static let maxTokens: Int = 600
    }
}

// MARK: - 请求体结构

struct DeepSeekRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

// MARK: - 响应体结构

struct DeepSeekResponse: Codable {
    let id: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}


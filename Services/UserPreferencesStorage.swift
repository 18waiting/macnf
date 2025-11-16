//
//  UserPreferencesStorage.swift
//  NFwordsDemo
//
//  用户偏好设置存储服务
//  Created by AI Assistant on 2025-01-XX.
//

import Foundation

// MARK: - 用户偏好设置存储
final class UserPreferencesStorage {
    static let shared = UserPreferencesStorage()
    
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "com.nfwords.userPreferences"
    
    private init() {}
    
    // MARK: - 存储和读取
    
    /// 保存用户偏好设置
    func save(_ preferences: UserPreferences) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)
        userDefaults.set(data, forKey: preferencesKey)
        userDefaults.synchronize()
        
        #if DEBUG
        print("[UserPreferencesStorage] ✅ 偏好设置已保存")
        #endif
    }
    
    /// 读取用户偏好设置
    func load() -> UserPreferences {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            #if DEBUG
            print("[UserPreferencesStorage] 使用默认偏好设置")
            #endif
            return UserPreferences.default
        }
        
        do {
            let decoder = JSONDecoder()
            let preferences = try decoder.decode(UserPreferences.self, from: data)
            #if DEBUG
            print("[UserPreferencesStorage] ✅ 偏好设置已加载")
            #endif
            return preferences
        } catch {
            #if DEBUG
            print("[UserPreferencesStorage] ⚠️ 加载偏好设置失败: \(error)，使用默认设置")
            #endif
            return UserPreferences.default
        }
    }
    
    /// 重置为默认设置
    func reset() throws {
        userDefaults.removeObject(forKey: preferencesKey)
        userDefaults.synchronize()
        #if DEBUG
        print("[UserPreferencesStorage] ✅ 偏好设置已重置")
        #endif
    }
    
    /// 更新部分偏好设置
    func update(_ updateBlock: (inout UserPreferences) -> Void) throws {
        var preferences = load()
        updateBlock(&preferences)
        try save(preferences)
    }
}


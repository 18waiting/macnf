//
//  Word.swift
//  NFwordsDemo
//
//  Created by 甘名杨 on 2025/11/1.
//

//
//  Word.swift
//  NFwords Demo
//
//  单词数据模型
//

import Foundation

// MARK: - 单词模型
struct Word: Identifiable, Codable {
    let id: Int  // wid
    let word: String
    let phonetic: String?
    let translations: [Translation]
    let phrases: [Phrase]
    let scenes: [Scene]
    let frequency: Int?
    
    var wid: Int { id }
}

// MARK: - 翻译
struct Translation: Codable, Hashable {
    let partOfSpeech: String  // n, v, adj, adv
    let meaning: String
    
    var displayPartOfSpeech: String {
        switch partOfSpeech {
        case "n": return "名词"
        case "v": return "动词"
        case "adj": return "形容词"
        case "adv": return "副词"
        default: return partOfSpeech
        }
    }
}

// MARK: - 短语
struct Phrase: Codable, Hashable {
    let english: String
    let chinese: String
}

// MARK: - 场景
struct Scene: Codable, Hashable {
    let english: String
    let chinese: String?
}

// MARK: - 示例数据
extension Word {
    static let examples: [Word] = [
        Word(
            id: 1,
            word: "abandonment",
            phonetic: "/əˈbændənmənt/",
            translations: [
                Translation(partOfSpeech: "n", meaning: "放弃"),
                Translation(partOfSpeech: "n", meaning: "遗弃")
            ],
            phrases: [
                Phrase(english: "abandonment of responsibility", chinese: "放弃责任"),
                Phrase(english: "emotional abandonment", chinese: "情感上的遗弃")
            ],
            scenes: [
                Scene(
                    english: "You stand on the beach, the concept of abandonment slowly settling in your mind. The waves crash against the shore, each one whispering stories of things left behind.",
                    chinese: "你站在海滩上，放弃的概念慢慢在你脑海中沉淀。海浪拍打着海岸，每一朵浪花都在诉说着被遗弃的故事。"
                )
            ],
            frequency: 2800
        ),
        Word(
            id: 2,
            word: "resilient",
            phonetic: "/rɪˈzɪliənt/",
            translations: [
                Translation(partOfSpeech: "adj", meaning: "有韧性的"),
                Translation(partOfSpeech: "adj", meaning: "能恢复的")
            ],
            phrases: [
                Phrase(english: "resilient spirit", chinese: "坚韧的精神"),
                Phrase(english: "resilient economy", chinese: "有韧性的经济")
            ],
            scenes: [
                Scene(
                    english: "Despite facing countless setbacks, her resilient nature kept pushing her forward. She was like a tree bending in the storm but never breaking.",
                    chinese: "尽管面临无数挫折，她坚韧的性格让她不断前进。她就像暴风雨中弯曲但永不折断的树。"
                )
            ],
            frequency: 5200
        ),
        Word(
            id: 3,
            word: "elaborate",
            phonetic: "/ɪˈlæbərət/",
            translations: [
                Translation(partOfSpeech: "adj", meaning: "精心制作的"),
                Translation(partOfSpeech: "v", meaning: "详细说明")
            ],
            phrases: [
                Phrase(english: "elaborate plan", chinese: "精心策划的计划"),
                Phrase(english: "elaborate on details", chinese: "详细说明细节")
            ],
            scenes: [
                Scene(
                    english: "The architect presented an elaborate design for the new museum. Every detail was carefully considered, from the grand entrance to the smallest window.",
                    chinese: "建筑师展示了新博物馆的精心设计。每个细节都经过仔细考虑，从宏伟的入口到最小的窗户。"
                )
            ],
            frequency: 4100
        ),
        Word(
            id: 4,
            word: "abolish",
            phonetic: "/əˈbɑːlɪʃ/",
            translations: [
                Translation(partOfSpeech: "v", meaning: "废除"),
                Translation(partOfSpeech: "v", meaning: "废止")
            ],
            phrases: [
                Phrase(english: "abolish slavery", chinese: "废除奴隶制"),
                Phrase(english: "abolish the death penalty", chinese: "废除死刑")
            ],
            scenes: [
                Scene(
                    english: "The government decided to abolish the outdated law. It was a historic moment that marked the beginning of a new era of justice.",
                    chinese: "政府决定废除这项过时的法律。这是标志着正义新时代开始的历史性时刻。"
                )
            ],
            frequency: 3500
        ),
        Word(
            id: 5,
            word: "accomplish",
            phonetic: "/əˈkɑːmplɪʃ/",
            translations: [
                Translation(partOfSpeech: "v", meaning: "完成"),
                Translation(partOfSpeech: "v", meaning: "实现")
            ],
            phrases: [
                Phrase(english: "accomplish a goal", chinese: "实现目标"),
                Phrase(english: "accomplish a task", chinese: "完成任务")
            ],
            scenes: [
                Scene(
                    english: "After years of hard work, she finally accomplished her dream of becoming a doctor. The journey was difficult, but the reward was worth it.",
                    chinese: "经过多年的努力，她终于实现了成为医生的梦想。旅程很艰难，但回报是值得的。"
                )
            ],
            frequency: 2100
        )
    ]
}


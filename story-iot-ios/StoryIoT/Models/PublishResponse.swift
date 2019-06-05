//
//  PublishResponse.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/5/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

// MARK: - PublishResponse
public struct PublishResponse: Codable {
    let path: String?
    let topic: String?
    let metadata: Metadata?
    let hash: String?
    let lenght: Int?
    let id: String?
    let ticks: Double?
    
    enum CodingKeys: String, CodingKey {
        case path = "Path"
        case topic = "Topic"
        case metadata = "Metadata"
        case hash = "Hash"
        case lenght = "Lenght"
        case id = "Id"
        case ticks = "Ticks"
    }
    
}


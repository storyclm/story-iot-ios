//
//  SIOTPublishResponse.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/5/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

// MARK: - PublishResponse

public struct SIOTPublishResponse: Codable {
    public let path: String?
    public let topic: String?
    public let metadata: SIOTMetadataModel?
    public let hash: String?
    public let lenght: Int?
    public let id: String?
    public let ticks: Double?

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

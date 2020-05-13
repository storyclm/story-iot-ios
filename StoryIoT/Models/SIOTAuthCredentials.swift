//
//  SIOTAuthCredentials.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

public struct SIOTAuthCredentials {
    let endpoint: String
    let hub: String
    let key: String
    let secret: String
    let expirationTimeInterval: TimeInterval

    public init(endpoint: String, hub: String, key: String, secret: String, expiration: TimeInterval = 180) {
        self.endpoint = endpoint
        self.hub = hub
        self.key = key
        self.secret = secret
        self.expirationTimeInterval = expiration
    }
}

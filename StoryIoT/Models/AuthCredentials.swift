//
//  AuthCredentials.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

struct AuthCredentials {
    let endpoint: String
    let hub: String
    let key: String
    let secret: String
    let expirationTimeInterval: TimeInterval
}

//
//  SIOTError.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/5/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

final class SIOTError: NSError {
    class func make(description: String, reason: String?) -> NSError {
        print(description)
        return NSError(domain: "APIManager", code: 9999, userInfo: [NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: reason ?? ""])
    }
    
    class func make(code: Int, description: String, reason: String?) -> NSError {
        print(description)
        return NSError(domain: "APIManager", code: code, userInfo: [NSLocalizedDescriptionKey: description, NSLocalizedFailureReasonErrorKey: reason ?? ""])
    }
}

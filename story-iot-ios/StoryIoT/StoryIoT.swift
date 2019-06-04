//
//  StoryIoT.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation

public class StoryIoT {
    
    private let authCredentials: AuthCredentials
    
    public init(authCredentialsPlistName: String) {
        guard let plistURL = Bundle.main.url(forResource: authCredentialsPlistName, withExtension: "plist"), let dict = NSDictionary(contentsOf: plistURL),
            let endpoint = dict["endpoint"] as? String,
            let hub = dict["hub"] as? String,
            let key = dict["key"] as? String,
            let secret = dict["secret"] as? String,
            let expirationTimeInterval = dict["expirationTimeInterval"] as? Int else {
                
                fatalError("You don't have AuthCredentials.plist or it has wrong data")
        }
        
        authCredentials = AuthCredentials(endpoint: endpoint, hub: hub, key: key, secret: secret, expirationTimeInterval: expirationTimeInterval)
        
    }
    
    public func fo() {
        print("fo")
    }
    
}

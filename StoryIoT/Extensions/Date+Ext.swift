//
//  Date+Ext.swift
//  StoryIoT
//
//  Created by Sergey Ryazanov on 05.03.2021.
//  Copyright © 2021 Breffi. All rights reserved.
//

import Foundation

extension Date {

    func iotServerTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        return dateFormatter.string(from: self)
    }
}

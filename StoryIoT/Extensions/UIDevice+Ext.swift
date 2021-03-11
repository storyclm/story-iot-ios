//
//  UIDevice+Ext.swift
//  StoryIoT
//
//  Created by Sergey Ryazanov on 11.03.2021.
//  Copyright © 2021 Breffi. All rights reserved.
//

import Foundation

extension UIDevice {

    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

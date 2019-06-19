//
//  MetadataModels.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

public struct Metadata: Codable {
    ///EventId. Поле определяет тип события. Должен быть ассоциирован с конкретной моделью. Пример: clm.session.
    var eid: String?
    /// DeviceId. Идентификатор устройства, если поддерживается устройством. Пример: FDF5DA02-419E-465E-ADA6-A26B87097627.
    var did: String? = UIDevice.current.identifierForVendor?.uuidString
    /// UserId. Идентификатор пользователя, если таковой имеется. Пример: 71529FCA-3154-44F5-A462-66323E464F23.
    var uid: String?
    /// CorrelationToken. Идентификатор цепочки действий. Если события происходят одно за другим и выстраиваются в цепочку, то при возникновении первого события (событие верхнего уровня) ему присваивается токен корреляции и все дочернии события получают его. Так можно отследить последовательность действий от верхнего уровня и ниже. Пример: 96529FCA-6666-44F5-A462-66323E464444.
    var ct: String?
    /// уникальный идентификатор. Если в теле передается сущность у которой есть уникальный идентификатор (например у сущности сессии есть sessionId), то он записывается в это поле. Пример: “32”.
    var id: String?
    /// тип операции. Может быть “c” - create, “u” - update, “d” - delete.  Если передается сущность над которой выполнили операцию создания, редактирования или удаления то заполняется этот параметр. Пример: “с”.
    var cud: String?
    /// Model. Модель устройства, если таковую можно выявить. Пример: “iPad Air (WiFi/Cellular)”.
    var m: String? = UIDevice.current.name
    /// SerialNumber. Серийный номер устройства или сетевой карты, если возможно получить.
    var sn: String?
    /// Название операционной системы. Если возможно определить. Пример: “iPhone OS”.
    var os: String? = UIDevice.current.systemName
    /// версия операционной системы. Если возможно определить. Пример: “9.1”.
    var osv: String? = UIDevice.current.systemVersion
    /// AppName. Название приложения. Пример: “TestApp”.
    var an: String? = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
    /// AppVersion. Название приложения. Пример: “0.1.1”.
    var av: String? = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
    /// локальное время в формате ISO 8601. Время возникновения события на устройстве. Пример: “2020-05-28T09:02:49.5754586” без часового пояса и без “Z”.
    var lt: String? = ISO8601DateFormatter.init().string(from: Date())
    /// Time Zone. Часовой пояс. Пример: “+3”.
    var tz: String? = String(TimeZone.current.secondsFromGMT() / 3600)
    /// геолокация. Если включена. Пример: “on;-34.8799074,174.7565664” или “off”.
    var geo: String?
    
    var ip: String?
    var mt: String?
    

    init(eventId: String?, userId: String?, entityId: String?, location: CLLocation?) {
        self.eid = eventId
        self.uid = userId
        self.id = entityId
        
        if let location = location {
            self.geo = "on;\(location.coordinate.latitude),\(location.coordinate.longitude)"
        } else {
            self.geo = "off"
        }
    }
    
    func asDictionary() -> [String: String] {
        var dict = [String: String]()
        if let eid = eid { dict["s-m-eid"] = eid }
        if let did = did { dict["s-m-did"] = did }
        if let uid = uid { dict["s-m-uid"] = uid }
        if let ct = ct { dict["s-m-ct"] = ct }
        if let id = id { dict["s-m-id"] = id }
        if let cud = cud { dict["s-m-cud"] = cud }
        if let m = m { dict["s-m-m"] = m }
        if let sn = sn { dict["s-m-sn"] = sn }
        if let os = os { dict["s-m-os"] = os }
        if let osv = osv { dict["s-m-osv"] = osv }
        if let an = an { dict["s-m-an"] = an }
        if let av = av { dict["s-m-av"] = av }
        if let lt = lt { dict["s-m-lt"] = lt }
        if let tz = tz { dict["s-m-tz"] = tz }
        if let geo = geo { dict["s-m-geo"] = geo }
        
        return dict
    }
    
}



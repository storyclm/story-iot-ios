//
//  SIOTMetadataModel.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation
import CoreLocation

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

// MARK: - SIOTMetadataModel

public struct SIOTMetadataModel: Codable {
    /// EventId. Поле определяет тип события. Должен быть ассоциирован с конкретной моделью. Пример: clm.session.
    var eid: String?
    /// DeviceId. Идентификатор устройства, если поддерживается устройством. Пример: FDF5DA02-419E-465E-ADA6-A26B87097627.
    var did: String? = SIOTMetadataModel.identifierForVendor()
    /// UserId. Идентификатор пользователя, если таковой имеется. Пример: 71529FCA-3154-44F5-A462-66323E464F23.
    var uid: String?
    /// CorrelationToken. Идентификатор цепочки действий. Если события происходят одно за другим и выстраиваются в цепочку, то при возникновении первого события (событие верхнего уровня) ему присваивается токен корреляции и все дочернии события получают его. Так можно отследить последовательность действий от верхнего уровня и ниже. Пример: 96529FCA-6666-44F5-A462-66323E464444.
    var ct: String?
    /// Уникальный идентификатор. Если в теле передается сущность у которой есть уникальный идентификатор (например у сущности сессии есть sessionId), то он записывается в это поле. Пример: “32”.
    var id: String?
    /// Тип операции. Может быть “c” - create, “u” - update, “d” - delete.  Если передается сущность над которой выполнили операцию создания, редактирования или удаления то заполняется этот параметр. Пример: “с”.
    var cud: String?
    /// Model. Модель устройства, если таковую можно выявить. Пример: “iPad Air (WiFi/Cellular)”.
    var m: String? = SIOTMetadataModel.deviceModelName()
    /// SerialNumber. Серийный номер устройства или сетевой карты, если возможно получить.
    var sn: String?
    /// Название операционной системы. Если возможно определить. Пример: “iPhone OS”.
    var os: String? = SIOTMetadataModel.systemName()
    /// Версия операционной системы. Если возможно определить. Пример: “9.1”.
    var osv: String? = SIOTMetadataModel.systemVersion()
    /// AppName. Название приложения. Пример: “TestApp”.
    var an: String? = SIOTMetadataModel.appName()
    /// AppVersion. Версия приложения. Пример: “0.1.1”.
    var av: String? = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
    /// LocalTime. Локальное время в формате ISO 8601. Время возникновения события на устройстве. Пример: “2020-05-28T09:02:49.5754586” без часового пояса и без “Z”.
    var lt: String?
    /// Time Zone. Часовой пояс. Пример: “+3”.
    var tz: String? = String(TimeZone.current.secondsFromGMT() / 3600)
    /// Геолокация. Если включена. Пример: “on;-34.8799074,174.7565664” или “off”.
    var geo: String?
    /// Network status. Статус сети, как устройство подключено к сети(wifi, bt, lan ...);
    var ns: String?
    /// Язык приложения.
    var lng: String?
    var ip: String?
    var mt: String?

    public init(message: SIOTMessageModel) {
        self.eid = message.eventId
        self.uid = message.userId
        self.id = message.entityId

        self.cud = message.operationType?.rawValue
        self.lng = message.language
        self.lt = message.created?.iotServerTimeString()
        self.geo = self.geoString(from: message.coordinate)
        self.ns = message.networkStatus
    }

    public func asDictionary() -> [String: String] {
        var dict = [String: String]()
        if let eid = eid?.transliterate() { dict["s-m-eid"] = eid }
        if let did = did?.transliterate() { dict["s-m-did"] = did }
        if let uid = uid?.transliterate() { dict["s-m-uid"] = uid }
        if let ct = ct?.transliterate() { dict["s-m-ct"] = ct }
        if let id = id?.transliterate() { dict["s-m-id"] = id }
        if let cud = cud?.transliterate() { dict["s-m-cud"] = cud }
        if let m = m?.transliterate() { dict["s-m-m"] = m }
        if let sn = sn?.transliterate() { dict["s-m-sn"] = sn }
        if let os = os?.transliterate() { dict["s-m-os"] = os }
        if let osv = osv?.transliterate() { dict["s-m-osv"] = osv }
        if let an = an?.transliterate() { dict["s-m-an"] = an }
        if let av = av?.transliterate() { dict["s-m-av"] = av }
        if let lt = lt?.transliterate() { dict["s-m-lt"] = lt }
        if let tz = tz?.transliterate() { dict["s-m-tz"] = tz }
        if let geo = geo?.transliterate() { dict["s-m-geo"] = geo }
        if let lng = lng?.transliterate() { dict["s-m-lng"] = lng }
        if let ns = ns?.transliterate() { dict["s-m-ns"] = ns }

        return dict
    }

    // MARK: - Helpers

    private func geoString(from coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate = coordinate else { return "off" }
        return "on;\(coordinate.latitude),\(coordinate.longitude)"
    }
}

private extension String {
    func transliterate() -> String {
        return self.applyingTransform(.toLatin, reverse: false)?.applyingTransform(.stripDiacritics, reverse: false) ?? self
    }
}

private extension SIOTMetadataModel {

    static func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    static func systemName() -> String {
        #if os(iOS)
            return "iOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(macOS)
            return "macOS"
        #else
            return "Unknown OS"
        #endif
    }

    static func appName() -> String? {
        let bund = Bundle.main
        if let displayName = bund.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            if displayName.isEmpty == false {
                return displayName
            }
        }

        if let name = bund.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String {
            return name
        }
        return nil
    }

    static func systemVersion() -> String? {
        #if os(iOS) || os(tvOS) || os(watchOS)
            return UIDevice.current.systemVersion
        #else
            return nil
        #endif
    }

    static func identifierForVendor() -> String? {
        #if os(iOS) || os(tvOS) || os(watchOS)
            UIDevice.current.identifierForVendor?.uuidString
        #else
            return nil
        #endif
    }
}

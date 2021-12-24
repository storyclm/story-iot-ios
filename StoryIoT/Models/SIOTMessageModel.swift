//
//  SIOTMessageModel.swift
//  StoryIoT
//
//  Created by Sergey Ryazanov on 12.02.2020.
//  Copyright © 2020 Breffi. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire

// MARK: - SIOTMessageModel

public class SIOTMessageModel {

    enum BodyModel {
        case json([String: Any])
        case data(Data)
    }

    public enum SIOTOperationType: String {
        case create = "c"
        case update = "u"
        case delete = "d"
    }

    /// Поле определяет тип события. Должен быть ассоциирован с конкретной моделью. Пример: clm.session.
    public var eventId: String?

    /// Идентификатор пользователя, если таковой имеется. Пример: 71529FCA-3154-44F5-A462-66323E464F23
    public var userId: String?

    /// Уникальный идентификатор. Если в теле передается сущность у которой есть уникальный идентификатор
    /// (например у сущности сессии есть sessionId), то он записывается в это поле. Пример: "32"
    public var entityId: String?

    /// Тип операции. Может быть "c" - create, "u" - update, "d" - delete.
    /// Если передается сущность над которой выполнили операцию создания, редактирования или удаления то заполняется этот параметр.
    /// Пример: "с"
    public var operationType: SIOTOperationType?

    /// Статус сети, как устройство подключено к сети(wifi, bt, lan ...);
    /// Во время инициализации присваивается одно из трех значений: _none_, _Cellular_, _Wi-Fi_
    public var networkStatus: String?

    /// Язык приложения
    ///
    /// Во врменя инициализации выставляется язык приложение: `Locale.current.languageCode`
    public var language: String?

    public var coordinate: CLLocationCoordinate2D?

    public var created: Date?

    var body: BodyModel

    // MARK: - Init

    public init(body: [String: Any]) {
        self.body = BodyModel.json(body)
        self.setup()
    }

    public init(data: Data) {
        self.body = BodyModel.data(data)
        self.setup()
    }

    private func setup() {
        self.networkStatus = self.appNetworkStatus()
        self.language = self.appLanguage
    }
}

extension SIOTMessageModel {
    private var appLanguage: String? {
        return Locale.current.languageCode
    }

    private func appNetworkStatus() -> String {
        guard let reachabilityManager = NetworkReachabilityManager() else { return "none" }

        let status = reachabilityManager.status
        if case let NetworkReachabilityManager.NetworkReachabilityStatus.reachable(type) = status {
            switch type {
            case .cellular:
                return "Cellular"
            case .ethernetOrWiFi:
                return "Wi-Fi"
            }
        } else {
            return "none"
        }
    }
}

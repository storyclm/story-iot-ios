//
//  SIOTMessageModel.swift
//  StoryIoT
//
//  Created by Sergey Ryazanov on 12.02.2020.
//  Copyright © 2020 Breffi. All rights reserved.
//

import Foundation
import CoreLocation

public class SIOTMessageModel {

    enum BodyModel {
        case json ([String: Any])
        case data (Data)
    }

    public enum OperationType: String {
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
    public var operationType: OperationType?

    /// Статус сети, как устройство подключено к сети(wifi, bt, lan ...);
    public var networkStatus: String?

    public var language: String?

    public var coordinate: CLLocationCoordinate2D?

    public var create: Date?

    var body: BodyModel

    // MARK: - Init

    public init(body: [String: Any]) {
        self.body = BodyModel.json(body)
    }

    public init(data: Data) {
        self.body = BodyModel.data(data)
    }
}

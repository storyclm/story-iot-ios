//
//  SIOTSignBuilder.swift
//  StoryIoT
//
//  Created by Sergey Ryazanov on 04.02.2020.
//  Copyright © 2020 Breffi. All rights reserved.
//

import Foundation

public final class SIOTSignBuilder {

    private typealias Value = (key: String, value: String)

    private let privateKey: String
    private var values: [Value] = []

    public init(privateKey: String) {
        self.privateKey = privateKey
    }

    public func add(key: String, value: String) {
        values.append(Value(key: key, value: value))
    }

    ///
    /// Сигнатура параметров запроса создается путем конкатенации требуемых параметров в строку в виде: "Название параметра" + "=" + "Значение параметра". Очередность параметров должна соответствовать очередности в списке параметров, за исключением параметра signature . Этот параметр должен быть исключен. Так же должны быть исключены необязательные параметры не требуемые настройками хаба. В результате должна получиться строка:
    ///
    /// key=df94b12c3355425eb4efa406f09e8b9fexpiration=2020-05-28T09:02:49.5754586Z
    ///
    /// Если настройки хаба не требуют некоторые параметры, то их необходимо исключить.
    ///
    /// Строка должна быть в кодировке UTF-8. Из получившийся строки создается сигнатура по секретному ключу, при  этом используется алгоритм HMAC-SHA512. Секретный ключ хранится на устройстве. В результате кодирование должен быть получен массив зашифрованных байт. Чтобы получить строку, массив байт нужно закодировать в base64 и заменить символы “/” на “_” и “+” на “-”. Должна получится строка:
    ///
    /// ZQ6Zxtuy9DGhHjneAepq8NJovZMW0KLNwffhND_-ng1xuxFJSclYcpGUJSGxniM8IqV6nhWdWclsIdTE2n6X2Q==
    ///
    
    public func result() -> String? {
        let valuesStrings: [String] = values.map { "\($0.key)=\($0.value)"}
        let input = valuesStrings.reduce("") { $0 + $1 }

        if let hmac = input.data(using: String.Encoding.utf8)?.digest(.sha512, key: self.privateKey) {
            let result = hmac.base64EncodedString()
            return result.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        }
        return nil
    }

    public func resultIfNoNull() -> String? {
        if values.isEmpty { return nil }
        return result()
    }
}

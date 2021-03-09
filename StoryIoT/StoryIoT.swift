//
//  StoryIoT.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

let timeoutInterval: TimeInterval = 120

public enum SIOTFeedDirection: String {
    case forward
    case backward
}

public class StoryIoT {

    private let authCredentials: SIOTAuthCredentials
    private let manager = Alamofire.SessionManager.default

    public init(credentials: SIOTAuthCredentials) {
        self.authCredentials = credentials

        self.manager.session.configuration.timeoutIntervalForRequest = timeoutInterval
    }

    public init?(raw input: String) {
        let items = input.components(separatedBy: "=")
        guard items.count > 4 else { return nil }

        let endpoint = items[0]
        let hub = items[1]
        let key = items[2]
        let secret = items[3]
        var expirationTimeInterval: TimeInterval = 180

        if items.count > 5 {
            if let timeInterval = TimeInterval(items[4]) {
                expirationTimeInterval = timeInterval
            }
        }
        self.authCredentials = SIOTAuthCredentials(endpoint: endpoint, hub: hub, key: key, secret: secret, expiration: expirationTimeInterval)

        self.manager.session.configuration.timeoutIntervalForRequest = timeoutInterval
    }

    // MARK: - Publish

    public func publish(message: SIOTMessageModel,
                        success: @escaping (_ publishResponse: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                        failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        switch message.body {
        case .json:
            self.internalPublishSmall(message: message, success: success, failure: failure)
        case .data:
            self.internalPublishLarge(message: message, success: success, failure: failure)
        }
    }

    // MARK: * Small

    @available(*, deprecated, renamed: "publish")
    public func publishSmall(message: SIOTMessageModel,
                             success: @escaping (_ response: SIOTPublishResponse) -> Void,
                             failure: @escaping (_ error: NSError) -> Void)
    {
        self.internalPublishSmall(message: message) { publishResponse, _ in
            success(publishResponse)
        } failure: { error, _ in
            failure(error)
        }
    }

    func internalPublishSmall(message: SIOTMessageModel,
                              success: @escaping (_ response: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                              failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        guard case SIOTMessageModel.BodyModel.json(let jsonBody) = message.body else {
            let err = SIOTError.make(description: "Wrong body type of SIOTMessageModel for publishSmall", reason: nil)
            failure(err, nil)
            return
        }

        let metadata = SIOTMetadataModel(message: message)
        var headers: HTTPHeaders = metadata.asDictionary()
        headers["Content-Type"] = "application/json"

        var jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
        } catch {
            let err = SIOTError.make(description: "Can't serialize body to jsonData", reason: error.localizedDescription)
            failure(err, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData

        Alamofire.request(request).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let jsonResponse = try JSONDecoder().decode(SIOTPublishResponse.self, from: data)
                        success(jsonResponse, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: nil)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, nil)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    // MARK: * Large

    /// Большие данные. Этот тип сообщения позволяет загружать сообщения размер которых ограничивается только реализацией хранилища сообщений. Стандартное хранилище позволяет хранить сообщения размером до 2TB каждое. Публикация сообщений этого типа существенно отличается от публикации маленького сообщения.
    /// Публикация сообщения возможна только по протоколу HTTPS. Процесс выглядит следующим образом:
    /// Издатель публикует сообщение в конечную точку с пустым телом. Если авторизация и валидация сообщения прошла успешно, сервер присваивает сообщению уникальный идентификатор, извлекает метаданные из сообщения и создает пустой объект в хранилище сообщений. Это сообщение не будет видно в ленте.

    @available(*, deprecated, renamed: "publish")
    public func publishLarge(message: SIOTMessageModel, success: @escaping (_ response: SIOTPublishResponse) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        self.internalPublishLarge(message: message) { publishResponse, _ in
            success(publishResponse)
        } failure: { error, _ in
            failure(error)
        }
    }

    func internalPublishLarge(message: SIOTMessageModel,
                              success: @escaping (_ response: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                              failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        guard case SIOTMessageModel.BodyModel.data(let bodyData) = message.body else {
            let error = SIOTError.make(description: "Wrong body type of SIOTMessageModel for publishLarge", reason: nil)
            failure(error, nil)
            return
        }

        let metadata = SIOTMetadataModel(message: message)
        var headers: HTTPHeaders = metadata.asDictionary()
        headers["Content-Type"] = "application/json"

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers

        Alamofire.request(request).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {
                    let utf8Text = String(data: data, encoding: .utf8)
                    print("Data: \(String(describing: utf8Text))")

                    do {
                        let jsonResponse = try JSONDecoder().decode(SIOTPublishResponse.self, from: data)

                        /// В ответе клиенту отдается сообщение, которое имеет поле Path. Это поле содержит URL по которому методом PUT необходимо выполнить загрузку. Перед загрузкой необходимо сделать хэш sha512 и закодировать байт массив в base64 (без замены символов “/” и “+”). Результат нужно упаковать в строку вида:

                        /// “base64;sha512;{полученный хэш}”.
                        /// Пример:
                        /// “base64;sha512;mLnMEO1f1+ox0Aom+a+clb9T2V9bVxAlVDl4vtaIUY8nLPtHUc3RXHCEQMdaxIFOLMrpdqGkbjSdoVVLStTCZg==”

                        /// При запросе необходимо добавить два заголовка один их которых - это получившийся хэш:
                        /// x-ms-blob-type: BlockBlob
                        /// x-ms-meta-hash: base64;sha512;BR0anYfPZHNYQofX2pojuATumdKOziOmW3Ad0j7FNiNgM1zuPUPu9s7rQRDMFLvSQddrdwbQtj9nonHlKk8ggg==

                        /// Ссылка будет рабочей 24 часа, после чего нужно запросить новую ссылку, в случае неудачи и повторять этот процесс до успешной загрузки большого сообщения.

                        if let messageId = jsonResponse.id, let path = jsonResponse.path, let url = URL(string: path) {
                            self.uploadLargeData(bodyData, url: url) { uploadDataResponse in
                                self.confirmLarge(messageId: messageId) { confirmPublishResponse, confirmDataResponse in
                                    success(confirmPublishResponse, confirmDataResponse)
                                } failure: { confirmError, confirmDataResponse in
                                    failure(confirmError, confirmDataResponse)
                                }
                            } failure: { uploadError, uploadDataResponse in
                                failure(uploadError, uploadDataResponse)
                            }
                        } else {
                            let error = SIOTError.make(description: "response.path is nil or can't get url from path", reason: nil)
                            failure(error, response)
                        }

                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, nil)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    private func uploadLargeData(_ data: Data, url: URL,
                                 success: @escaping (_ dataResponse: DataResponse<Any>) -> Void,
                                 failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        let hash = data.digest(.sha512).base64EncodedString()
        let hashResult = "base64;sha512;\(hash)"

        let headers: HTTPHeaders = [
            "x-ms-blob-type": "BlockBlob",
            "x-ms-meta-hash": hashResult
        ]

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.put.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = data

        Alamofire.request(request).responseJSON { response in
            if let statusCode = response.response?.statusCode, statusCode == 201 {
                success(response)
            } else {
                if let error = response.error {
                    failure(error as NSError, response)
                } else {
                    let error = SIOTError.make(description: "Error while uploadLargeData", reason: nil)
                    failure(error, response)
                }
            }
        }
    }

    private func confirmLarge(messageId: String,
                              success: @escaping (_ publishResponse: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                              failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        guard let url = getConfirmLargeUrl(messageId: messageId) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        manager.request(url, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let jsonResponse = try jsonDecoder.decode(SIOTPublishResponse.self, from: data)
                        success(jsonResponse, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, response)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    // MARK: - Storage

    /// Хранилище сообщений позволяет получать сообщение по идентификатору и управлять его мета данными.
    ///
    public func getMessage(withMessgaeId messageId: String,
                           success: @escaping (_ publishResponse: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                           failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {
        guard let url = getStorageRequestUrl(withMessageId: messageId) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        self.manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let jsonResponse = try jsonDecoder.decode(SIOTPublishResponse.self, from: data)
                        success(jsonResponse, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, response)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    /// Метаданные можно изменять - задавать или удалять поля. Метод PUT позволяет задать значение. Если до этого такого значения не было то оно будет создано иначе значение заменяется новым.
    ///
    public func updateMeta(metaName: String,
                           withNewValue newValue: String,
                           inMessageWithId messageId: String,
                           success: @escaping (_ publishResponse: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                           failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {

        guard let url = updateStorageRequestUrl(withMessageId: messageId, metaName: metaName) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.put.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = newValue.data(using: .utf8)

        Alamofire.request(request).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let jsonResponse = try jsonDecoder.decode(SIOTPublishResponse.self, from: data)
                        success(jsonResponse, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, response)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    /// Для того, чтобы удалить метаданные необходимо использовать метод DELETE и указать название поля которое надо удалить. Если поле существует то оно будет удалено иначе операция будет проигнорирована без возникновения ошибки.
    ///
    public func deleteMeta(metaName: String, inMessageWithId messageId: String,
                           success: @escaping (_ publishResponse: SIOTPublishResponse, _ dataResponse: DataResponse<Any>) -> Void,
                           failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {

        guard let url = deleteStorageRequestUrl(withMessageId: messageId, metaName: metaName) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        self.manager.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {

                    let jsonDecoder = JSONDecoder()
                    do {
                        let jsonResponse = try jsonDecoder.decode(SIOTPublishResponse.self, from: data)
                        success(jsonResponse, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, response)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }

    // MARK: - Feed

    /// Лента сообщений предоставляет доступ к хранилищу сообщения представляя его в виде последовательного набора сообщений отсортированных по дате добавления сообщений в хранилище в порядке возрастания. В ленте отображаются только подтвержденные сообщения.

    /// В ленте сообщения расположены по порядку одно за другим в том порядке в котором они публикуются издателями. По этому, ленту можно обойти выбирая сообщения страницами в двух направлениях - от начала в конец и наоборот.

    /// Обход ленты сообщений осуществляется посредством токена продолжения. Вместе со страницей в заголовке ответа передается токен продолжение. Чтобы получить следующую страницу необходимо в следующий запрос передать токен продолженя и будет возвращена следующая страница. Таким образом, при первом запросе сервером устанавливается курсор и при каждом последующем запросе курсор смещается. Таким образом можно обойти все летнту сообщений в двух направления, указывая токен продолжения из предыдущего запроса и направление обхода ленты.

    /// Если токен не указан, то курсор устанавливается на первое сообщение в хранилище. После того, как будет произведена выборка первых записей в заголовке будет возвращен токен продолжения. Так начинается обход ленты.

    /// Токен продолжения можно сохранять и в любой момент продолжить получать новые сообщения для обработки.

    public func getFeed(token: String?,
                        direction: SIOTFeedDirection,
                        size: Int,
                        success: @escaping (_ publishResponses: [SIOTPublishResponse], _ token: String?, _ dataResponse: DataResponse<Any>) -> Void,
                        failure: @escaping (_ error: NSError, _ dataResponse: DataResponse<Any>?) -> Void)
    {

        guard let url = getFeedRequestUrl(token: token, direction: direction, size: size) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err, nil)
            return
        }

        self.manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { response in

            switch response.result {
            case .success:
                if let data = response.data {

                    let token = response.response?.allHeaderFields["cursor-position"] as? String

                    let jsonDecoder = JSONDecoder()
                    do {
                        let jsonResponse = try jsonDecoder.decode([SIOTPublishResponse].self, from: data)
                        success(jsonResponse, token, response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode SIOTPublishResponse data", reason: err.localizedDescription)
                        failure(err, response)
                    }

                } else {
                    let err = SIOTError.make(description: "SIOTPublishResponse data is nil", reason: nil)
                    failure(err, response)
                }

            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError, response)
            }
        }
    }
}

// MARK: - URLs

fileprivate extension StoryIoT {

    ///
    /// Каждый запрос к серверу имеет URL типа:
    /// {{endpoint}}/{{hub}}/feed/?key={{key}}&expiration={{expiration}}&signature={{signature}}.
    ///
    private func publishRequestUrl() -> URL? {
        guard let signatureInfo = self.generateSignatureInfo() else { return nil }

        let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/publish/?key=\(authCredentials.key)&expiration=\(signatureInfo.expiration)&signature=\(signatureInfo.signature)"
        return URL(string: requestString)
    }

    private func getStorageRequestUrl(withMessageId messageId: String) -> URL? {
        guard let signatureInfo = self.generateSignatureInfo() else { return nil }

        let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/storage/\(messageId)/?key=\(authCredentials.key)&expiration=\(signatureInfo.expiration)&signature=\(signatureInfo.signature)"
        return URL(string: requestString)
    }

    private func updateStorageRequestUrl(withMessageId messageId: String, metaName: String) -> URL? {
        guard let signatureInfo = self.generateSignatureInfo() else { return nil }

        let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/storage/\(messageId)/meta/\(metaName)/?key=\(authCredentials.key)&expiration=\(signatureInfo.expiration)&signature=\(signatureInfo.signature)"
        return URL(string: requestString)
    }

    private func deleteStorageRequestUrl(withMessageId messageId: String, metaName: String) -> URL? {
        return updateStorageRequestUrl(withMessageId: messageId, metaName: metaName)
    }

    private func getFeedRequestUrl(token: String?, direction: SIOTFeedDirection, size: Int) -> URL? {
        guard let signatureInfo = self.generateSignatureInfo() else { return nil }

        var requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/feed/?key=\(authCredentials.key)&expiration=\(signatureInfo.expiration)&signature=\(signatureInfo.signature)&direction=\(direction.rawValue)&size=\(size)"

        if let token = token {
            requestString = requestString + "&token=\(token)"
        }

        return URL(string: requestString)
    }

    private func getConfirmLargeUrl(messageId: String) -> URL? {
        guard let signatureInfo = self.generateSignatureInfo() else { return nil }

        let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/publish/\(messageId)/confirm/?key=\(authCredentials.key)&expiration=\(signatureInfo.expiration)&signature=\(signatureInfo.signature)"
        return URL(string: requestString)
    }

    // MARK: * Signature

    private func buildSignature(expiration: String) -> String? {
        let signBuilder = SIOTSignBuilder(privateKey: self.authCredentials.secret)
        signBuilder.add(key: "key", value: self.authCredentials.key)
        signBuilder.add(key: "expiration", value: expiration)

        return signBuilder.result()
    }

    private func generateSignatureInfo() -> (expiration: String, signature: String)? {
        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: self.authCredentials.expirationTimeInterval))
        guard let signature = self.buildSignature(expiration: expirationString) else { return nil }

        return (expiration: expirationString, signature: signature)
    }
}

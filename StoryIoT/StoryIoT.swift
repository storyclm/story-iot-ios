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

public enum FeedDirection: String {
    case forward = "forward"
    case backward = "backward"
}


public class StoryIoT {
    
    private let authCredentials: AuthCredentials
    private let manager = Alamofire.SessionManager.default
    
    public init(credentials: String) {
        let items = credentials.components(separatedBy: "=")
        if items.count == 5 {
            let endpoint = items[0]
            let hub = items[1]
            let key = items[2]
            let secret = items[3]
            var expirationTimeInterval: TimeInterval = 180
            if let timeInterval = TimeInterval(items[4]) {
                expirationTimeInterval = timeInterval
            }
            
            authCredentials = AuthCredentials(endpoint: endpoint, hub: hub, key: key, secret: secret, expirationTimeInterval: expirationTimeInterval)
        } else {
            fatalError("Credentials string has wrong format")
        }

        manager.session.configuration.timeoutIntervalForRequest = timeoutInterval
        
    }
    
    // MARK: - Auth
    
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
    private func buildSignature(forKey publicKey: String, privateKey: String, expiration: String) -> String? {
        let string = "key=\(publicKey)expiration=\(expiration)"
        if let hmac = string.data(using: .utf8)?.digest(.sha512, key: privateKey) {
            let result = hmac.base64EncodedString()
            return result.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        }
        return nil
    }
    
    // MARK: - Helpers
    
    ///
    /// Каждый запрос к серверу имеет URL типа:
    /// {{endpoint}}/{{hub}}/feed/?key={{key}}&expiration={{expiration}}&signature={{signature}}.
    ///
    private func publishRequestUrl() -> URL? {

        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: authCredentials.expirationTimeInterval))
        
        if let signature = buildSignature(forKey: authCredentials.key, privateKey: authCredentials.secret, expiration: expirationString) {
            
            let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/publish/?key=\(authCredentials.key)&expiration=\(expirationString)&signature=\(signature)"
            
            return URL(string: requestString)
            
        }
        
        return nil
    }
    
    private func getStorageRequestUrl(withMessageId messageId: String) -> URL? {
        
        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: authCredentials.expirationTimeInterval))
        
        if let signature = buildSignature(forKey: authCredentials.key, privateKey: authCredentials.secret, expiration: expirationString) {
            
            let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/storage/\(messageId)/?key=\(authCredentials.key)&expiration=\(expirationString)&signature=\(signature)"
            
            return URL(string: requestString)
            
        }
        
        return nil
    }
    
    private func updateStorageRequestUrl(withMessageId messageId: String, metaName: String) -> URL? {
        
        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: authCredentials.expirationTimeInterval))
        
        if let signature = buildSignature(forKey: authCredentials.key, privateKey: authCredentials.secret, expiration: expirationString) {
            
            let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/storage/\(messageId)/meta/\(metaName)/?key=\(authCredentials.key)&expiration=\(expirationString)&signature=\(signature)"
            
            return URL(string: requestString)
            
        }
        
        return nil
        
    }
    
    private func deleteStorageRequestUrl(withMessageId messageId: String, metaName: String) -> URL? {
        return updateStorageRequestUrl(withMessageId: messageId, metaName: metaName)

    }
    
    private func getFeedRequestUrl(token: String?,
                                   direction: FeedDirection,
                                   size: Int) -> URL? {
        
        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: authCredentials.expirationTimeInterval))
        
        if let signature = buildSignature(forKey: authCredentials.key, privateKey: authCredentials.secret, expiration: expirationString) {
            
            var requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/feed/?key=\(authCredentials.key)&expiration=\(expirationString)&signature=\(signature)&direction=\(direction.rawValue)&size=\(size)"
            
            if let token = token {
                requestString = requestString + "&token=\(token)"
            }
            
            return URL(string: requestString)
            
        }
        
        return nil
    }
    
    private func getConfirmLargeUrl(messageId: String) -> URL? {
        
        let expirationString = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: authCredentials.expirationTimeInterval))
        
        if let signature = buildSignature(forKey: authCredentials.key, privateKey: authCredentials.secret, expiration: expirationString) {
            
            let requestString = "\(authCredentials.endpoint)/\(authCredentials.hub)/publish/\(messageId)/confirm/?key=\(authCredentials.key)&expiration=\(expirationString)&signature=\(signature)"
            
            return URL(string: requestString)
            
        }
        
        return nil
    }
    
    // MARK: - Publish
    
    public func publishSmall(body: [String: Any],
                             eventId: String?,
                             userId: String?,
                             entityId: String?,
                             location: CLLocation?,
                             success: @escaping (_ response: PublishResponse) -> Void,
                             failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
    
        let metadata = Metadata(eventId: eventId, userId: userId, entityId: entityId, location: location)
        var headers: HTTPHeaders = metadata.asDictionary()
        headers["Content-Type"] = "application/json"
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted) else {
            let err = SIOTError.make(description: "Can't serialize body to jsonData", reason: nil)
            failure(err)
            return
        }
        
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        
        Alamofire.request(request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        success(response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
    // MARK: Large
    
    /// Большие данные. Этот тип сообщения позволяет загружать сообщения размер которых ограничивается только реализацией хранилища сообщений. Стандартное хранилище позволяет хранить сообщения размером до 2TB каждое. Публикация сообщений этого типа существенно отличается от публикации маленького сообщения.
    /// Публикация сообщения возможна только по протоколу HTTPS. Процесс выглядит следующим образом:
    /// Издатель публикует сообщение в конечную точку с пустым телом. Если авторизация и валидация сообщения прошла успешно, сервер присваивает сообщению уникальный идентификатор, извлекает метаданные из сообщения и создает пустой объект в хранилище сообщений. Это сообщение не будет видно в ленте.

    public func publishLarge(data: Data,
                             eventId: String,
                             userId: String,
                             entityId: String?,
                             location: CLLocation?,
                             success: @escaping (_ response: PublishResponse) -> Void,
                             failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        
        let metadata = Metadata(eventId: eventId, userId: userId, entityId: entityId, location: location)
        var headers: HTTPHeaders = metadata.asDictionary()
        headers["Content-Type"] = "application/json"
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
     
        Alamofire.request(request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
                    let utf8Text = String(data: data, encoding: .utf8)
                    print("Data: \(String(describing: utf8Text))")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        
                        /// В ответе клиенту отдается сообщение, которое имеет поле Path. Это поле содержит URL по которому методом PUT необходимо выполнить загрузку. Перед загрузкой необходимо сделать хэш sha512 и закодировать байт массив в base64 (без замены символов “/” и “+”). Результат нужно упаковать в строку вида:
                        
                        /// “base64;sha512;{полученный хэш}”.
                        /// Пример:
                        /// “base64;sha512;mLnMEO1f1+ox0Aom+a+clb9T2V9bVxAlVDl4vtaIUY8nLPtHUc3RXHCEQMdaxIFOLMrpdqGkbjSdoVVLStTCZg==”
                        
                        /// При запросе необходимо добавить два заголовка один их которых - это получившийся хэш:
                        /// x-ms-blob-type: BlockBlob
                        /// x-ms-meta-hash: base64;sha512;BR0anYfPZHNYQofX2pojuATumdKOziOmW3Ad0j7FNiNgM1zuPUPu9s7rQRDMFLvSQddrdwbQtj9nonHlKk8ggg==
                        
                        /// Ссылка будет рабочей 24 часа, после чего нужно запросить новую ссылку, в случае неудачи и повторять этот процесс до успешной загрузки большого сообщения.

                        if let id = response.id, let path = response.path, let url = URL(string: path) {
                            self.uploadLargeData(data, url: url, success: {
                                self.confirmLarge(messageId: id, success: { (response) in
                                    success(response)
                                    
                                }, failure: { (error) in
                                    failure(error)
                                    
                                })
                                
                            }, failure: { (error) in
                                failure(error)
                            })
                            
                            
                        } else {
                            let error = SIOTError.make(description: "response.path is nil or can't get url from path", reason: nil)
                            failure(error)
                        }
                        
                        
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
    private func uploadLargeData(_ data: Data,
                                 url: URL,
                                 success: @escaping () -> Void,
                                 failure: @escaping (_ error: NSError) -> Void) {
        
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
        
        
        Alamofire.request(request).responseJSON { (response) in
            
            if let statusCode = response.response?.statusCode, statusCode == 201 {
                success()
            } else {
                if let error = response.error {
                    failure(error as NSError)
                } else {
                    let error = SIOTError.make(description: "Error while uploadLargeData", reason: nil)
                    failure(error)
                }
            }
            
        }

        
    }
    
    private func confirmLarge(messageId: String,
                              success: @escaping (_ response: PublishResponse) -> Void,
                              failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = getConfirmLargeUrl(messageId: messageId) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        manager.request(url, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        success(response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
    // MARK: - Storage
    
    /// Хранилище сообщений позволяет получать сообщение по идентификатору и управлять его мета данными.
    ///
    public func getMessage(withMessgaeId messageId: String,
                           success: @escaping (_ response: PublishResponse) -> Void,
                           failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = getStorageRequestUrl(withMessageId: messageId) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        self.manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        success(response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
    
    /// Метаданные можно изменять - задавать или удалять поля. Метод PUT позволяет задать значение. Если до этого такого значения не было то оно будет создано иначе значение заменяется новым.
    ///
    public func updateMeta(metaName: String,
                           withNewValue newValue: String,
                           inMessageWithId messageId: String,
                           success: @escaping (_ response: PublishResponse) -> Void,
                           failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = updateStorageRequestUrl(withMessageId: messageId, metaName: metaName) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.put.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = newValue.data(using: .utf8)
        
        
        Alamofire.request(request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        success(response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
    
    /// Для того, чтобы удалить метаданные необходимо использовать метод DELETE и указать название поля которое надо удалить. Если поле существует то оно будет удалено иначе операция будет проигнорирована без возникновения ошибки.
    ///
    public func deleteMeta(metaName: String, inMessageWithId messageId: String,
                                  success: @escaping (_ response: PublishResponse) -> Void,
                                  failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = deleteStorageRequestUrl(withMessageId: messageId, metaName: metaName) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        self.manager.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode(PublishResponse.self, from: data)
                        success(response)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
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
                          direction: FeedDirection,
                          size: Int,
                          success: @escaping (_ response: [PublishResponse], _ token: String?) -> Void,
                          failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = getFeedRequestUrl(token: token, direction: direction, size: size) else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        self.manager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            switch response.result {
                
            case .success(_):
                if let data = response.data {
//                    let utf8Text = String(data: data, encoding: .utf8)
//                    print("Data: \(utf8Text)")
                    
                    let token = response.response?.allHeaderFields["cursor-position"] as? String
                    
                    let jsonDecoder = JSONDecoder()
                    do {
                        let response = try jsonDecoder.decode([PublishResponse].self, from: data)
                        success(response, token)
                    } catch (let err) {
                        print(err.localizedDescription)
                        let err = SIOTError.make(description: "Can't decode PublishResponse data", reason: nil)
                        failure(err)
                    }
                    
                } else {
                    let err = SIOTError.make(description: "PublishResponse data is nil", reason: nil)
                    failure(err)
                    
                }
                
            case .failure(let error):
                print(error.localizedDescription)
                failure(error as NSError)
            }
            
        }
        
    }
    
}

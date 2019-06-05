//
//  StoryIoT.swift
//  StoryIoT
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import Foundation
import Alamofire

let timeoutInterval: TimeInterval = 120

public enum FeedDirection: String {
    case forward = "forward"
    case backward = "backward"
}


public class StoryIoT {
    
    private let authCredentials: AuthCredentials
    private let manager = Alamofire.SessionManager.default
    
    public init(authCredentialsPlistName: String) {
        guard let plistURL = Bundle.main.url(forResource: authCredentialsPlistName, withExtension: "plist"), let dict = NSDictionary(contentsOf: plistURL),
            let endpoint = dict["endpoint"] as? String,
            let hub = dict["hub"] as? String,
            let key = dict["key"] as? String,
            let secret = dict["secret"] as? String,
            let expirationTimeInterval = dict["expirationTimeInterval"] as? TimeInterval else {
                
                fatalError("You don't have AuthCredentials.plist or it has wrong data")
        }
        
        authCredentials = AuthCredentials(endpoint: endpoint, hub: hub, key: key, secret: secret, expirationTimeInterval: expirationTimeInterval)
        
        manager.session.configuration.timeoutIntervalForRequest = timeoutInterval
        
    }
    
    public func fo() {
        print("fo")
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
    
    // MARK: - Publish
    
    public func publishSmall(body: [String: String],
                             success: @escaping (_ response: PublishResponse) -> Void,
                             failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
    
        let metadata = Metadata()
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
    
    public func publishLarge(data: Data,
                             success: @escaping (_ response: PublishResponse) -> Void,
                             failure: @escaping (_ error: NSError) -> Void) {
        
        guard let url = publishRequestUrl() else {
            let err = SIOTError.make(description: "Can't get requestUrl", reason: nil)
            failure(err)
            return
        }
        
        
        let metadata = Metadata()
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
                    print("Data: \(utf8Text)")
                    
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

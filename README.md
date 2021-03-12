[![Pod License](https://img.shields.io/cocoapods/l/StoryIoT?color=orange)](https://github.com/storyclm/story-iot-ios/blob/master/LICENSE)
[![Pod Version](https://img.shields.io/cocoapods/v/StoryIoT)](https://cocoapods.org/pods/StoryIoT)
![Pod Platforms](https://img.shields.io/cocoapods/p/StoryIoT)
[![Swift 5.0](https://img.shields.io/badge/swift-5.0-red.svg?style=flat)](https://developer.apple.com/swift)

# story-iot-ios

## Требования

- iOS 11.0+
- Swift 5.0+
- XCode 11+

## Установка

### [CocoaPods](https://cocoapods.org)

```ruby
pod 'StoryIoT', '~> 1.6'
```

### Вручную

Скопировать содержимое папки **StoryIoT** в свой проект.
И подключить зависимость Alamofire версии 4.9.

## Использование

### Инициализация StoryIoT

#### Инициализация StoryIoT через *SIOTAuthCredentials*

```swift
let credentials = SIOTAuthCredentials(endpoint: "storyIoTEndpoint", hub: "storyIoTHub", key: "storyIoTKey", secret: "storyIoTSecret")
let storyIoT = StoryIoT(credentials: credentials)
```

#### Инициализация StoryIoT через строку

**Note**: При инициализации через строку используется [проваливающийся инициализатор](https://developer.apple.com/swift/blog/?id=17)

```swift
let rawString = "https://storyIoTEndpoint=storyIoTHub=storyIoTKey=storyIoTSecret=storyIoTexpirationTimeInterval"
let storyIoT = StoryIoT(raw: rawString)
```



---

### Публикация

#### Публикация маленьких сообщений (команд, событий)

Сервер на прямую может принять сообщение с телом до 256Kb (один чанк). Сообщение с телом большего размера будет отклонено ответом 500. При публикации сообщения, тело и метаданные записываются в хранилище и только после успешного завершения операции потребителям будет отправлено сообщение-уведомление о поступлении нового сообщения.

```swift
 let body: [String: Any] = [
	"testKey": "testValue",
	"created": Date().iotServerTimeString(),
]

let message = SIOTMessageModel(body: body)
message.eventId = "myEventId"
message.userId = self.randomTestUUID()
message.entityId = self.randomTestUUID()
message.created = Date()
message.operationType = .create

self.storyIoT.publish(message: message, success: { response, dataResponse in

}, failure: { error, dataResponse in

})
```

### Публикация больших сообщений

Большие данные. Этот тип сообщения позволяет загружать сообщения размер которых ограничивается только реализацией хранилища сообщений.

Стандартное хранилище позволяет хранить сообщения размером до 2TB каждое.

```swift
guard let data = self.messageData else { return }

let message = SIOTMessageModel(data: data)
message.eventId = "myEventId"
message.userId = self.randomTestUUID()
message.entityId = self.randomTestUUID()
message.created = Date()
message.operationType = .update

self.storyIoT.publish(message: message, success: { response, dataResponse in

}, failure: { error, dataResponse in

})
```

---

### Хранилище сообщений

Хранилище сообщений позволяет получать сообщение по идентификатору и управлять его мета данными.

#### Получение сообщения

Получение сообщения по идентификатору.

```swift
let messageId = "messageID"
self.storyIoT.getMessage(withMessgaeId: messageId, success: { response, dataResponse in

}, failure: { error, dataResponse in
	
})
```

#### Изменение метаданных

Если до этого такого значения не было то оно будет создано иначе значение заменяется новым.

```swift
let messageId = "messageID"
self.storyIoT.updateMeta(metaName: "metaName", withNewValue: "newValue", inMessageWithId: messageId, success: { response, dataResponse in

}, failure: { error, dataResponse in

})
```

#### Удаление метаданных

Для того, чтобы удалить метаданные необходимо указать название поля которое надо удалить. Если поле существует то оно будет удалено иначе операция будет проигнорирована без возникновения ошибки.

```swift
let messageId = "messageID"
self.storyIoT.deleteMeta(metaName: "metaName", inMessageWithId: messageId, success: { response, dataResponse in

}, failure: { error, dataResponse in

})
```

---

### Лента событий

Лента сообщений предоставляет доступ к хранилищу сообщения представляя его в виде последовательного набора сообщений отсортированных по дате добавления сообщений в хранилище в порядке возрастания. В ленте отображаются только подтвержденные сообщения.

В ленте сообщения расположены по порядку одно за другим в том порядке в котором они публикуются издателями. По этому, ленту можно обойти выбирая сообщения страницами в двух направлениях - от начала в конец и наоборот.

Обход ленты сообщений осуществляется посредством токена продолжения. Вместе со страницей в заголовке ответа передается токен продолжение. Чтобы получить следующую страницу необходимо в следующий запрос передать токен продолженя и будет возвращена следующая страница. Таким образом, при первом запросе сервером устанавливается курсор и при каждом последующем запросе курсор смещается. Таким образом можно обойти все летнту сообщений в двух направления, указывая токен продолжения из предыдущего запроса и направление обхода ленты.

Если токен не указан, то курсор устанавливается на первое сообщение в хранилище. После того, как будет произведена выборка первых записей в заголовке будет возвращен токен продолжения. Так начинается обход ленты. 

Токен продолжения можно сохранять и в любой момент продолжить получать новые сообщения для обработки.

#### Получение первой страницы ленты

Для того, чтобы начать обход ленты нужно выполнить запрос.

**Note:** *size* - размер страницы, от 1 до 1000.

```swift
self.storyIoT.getFeed(token: nil, direction: SIOTFeedDirection.forward, size: 100, success: { response, newToken, dataResponse in

}, failure: { error, dataResponse in

})
```

#### Получение следующей страницы ленты

Чтобы получить следующую страницу необходимо извлечь токен и передать в следующем запросе.
Будет получена следующая страница или пустой список если сообщений больше нет. 

**Note:** *size* - размер страницы, от 1 до 1000.

```swift
let token = previousToken
self.storyIoT.getFeed(token: token, direction: SIOTFeedDirection.forward, size: 100, success: { response, newToken, dataResponse in

}, failure: { error, dataResponse in

})
```

---

### Лицензия

StoryIoT распространяется под лицензией MIT. [См. Подробности](https://github.com/storyclm/story-iot-ios/blob/master/LICENSE)


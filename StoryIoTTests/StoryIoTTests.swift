//
//  StoryIoTTests.swift
//  StoryIoTTests
//
//  Created by Oleksandr Yolkin on 6/4/19.
//  Copyright © 2019 Breffi. All rights reserved.
//

import XCTest
@testable import StoryIoT

class StoryIoTTests: XCTestCase {

    private var storyIoT: StoryIoT?

    override func setUp() {
        super.setUp()

        if let credentials = self.parseCredentials() {
            self.storyIoT = StoryIoT(credentials: credentials)
        } else {
            XCTFail("Error while parse AuthCredentials.plist file")
        }
    }

    override func tearDown() {
        super.tearDown()

        self.storyIoT = nil
    }

    func testRawInit() {
        let expectation = self.expectation(description: "StoryIoT.RawInit")

        guard nil != StoryIoT(raw: "https://staging-iot.storychannels.app=b47bbc659eb344888f9f92ed3261d8dc=df94b12c3355425eb4efa406f09e8b9f=163af6783ae14d5f829288d1ca44950e=180") else {
            XCTFail("\(expectation.description) - Init failed")
            return
        }

        expectation.fulfill()
        
        self.waitForExpectations(timeout: 2) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Publish

    func testPublishSmall() {

        let expectation = self.expectation(description: "StoryIoT.PublishSmall")

        let body: [String: Any] = [
            "testKey": "testValue",
            "created": Date().iotServerTimeString(),
        ]

        let message = SIOTMessageModel(body: body)
        message.eventId = "storyiot.test.publishSmall"
        message.userId = self.randomTestUUID()
        message.entityId = self.randomTestUUID()
        message.created = Date()
        message.operationType = (arc4random() % 2 == 0) ? .update : .create

        self.storyIoT?.publish(message: message, success: { response, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 10.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    func testPublishLarge() {
        let expectation = self.expectation(description: "StoryIoT.PublishLarge")

        guard let data = self.blankImageData() else {
            XCTFail("Error converting testImage.png to Data")
            return
        }

        let message = SIOTMessageModel(data: data)
        message.eventId = "storyiot.test.publishLarge"
        message.userId = self.randomTestUUID()
        message.entityId = self.randomTestUUID()
        message.created = Date()
        message.operationType = (arc4random() % 2 == 0) ? .update : .create

        self.storyIoT?.publish(message: message, success: { response, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 15.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Message

    func testGetMessage() {
        let expectation = self.expectation(description: "StoryIoT.GetMessage")

        let messageId = "274820d9b5d546048f0e5989f3a7ebc9"
        self.storyIoT?.getMessage(withMessgaeId: messageId, success: { response, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 15.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    func testUpdateMetadata() {
        let expectation = self.expectation(description: "StoryIoT.UpdateMetadata")

        let messageId = "274820d9b5d546048f0e5989f3a7ebc9"
        self.storyIoT?.updateMeta(metaName: "m", withNewValue: "iphone11,4", inMessageWithId: messageId, success: { response, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 15.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    func testDeleteMetadata() {
        let expectation = self.expectation(description: "StoryIoT.DeleteMetadata")

        let messageId = "274820d9b5d546048f0e5989f3a7ebc9"
        self.storyIoT?.deleteMeta(metaName: "m", inMessageWithId: messageId, success: { response, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 15.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Feed

    func testGetFeed() {
        let expectation = self.expectation(description: "StoryIoT.GetFeed")

        self.storyIoT?.getFeed(token: nil, direction: SIOTFeedDirection.forward, size: 100, success: { response, token, dataResponse in
            expectation.fulfill()
        }, failure: { error, dataResponse in
            XCTFail("\(expectation.description) - \(error.localizedDescription)")
        })

        self.waitForExpectations(timeout: 15.0) { error in
            if let error = error {
                XCTFail("\(expectation.description) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    private func parseCredentials() -> SIOTAuthCredentials? {
        guard let plistURL = Bundle(for: type(of: self)).url(forResource: "AuthCredentials", withExtension: "plist"), let dict = NSDictionary(contentsOf: plistURL) else { return nil }

        guard let endpoint = dict["endpoint"] as? String else { return nil }
        guard let hub = dict["hub"] as? String else { return nil }
        guard let key = dict["key"] as? String else { return nil }
        guard let secret = dict["secret"] as? String else { return nil }

        let expiration = (dict["expirationTimeInterval"] as? TimeInterval) ?? 180

        return SIOTAuthCredentials(endpoint: endpoint, hub: hub, key: key, secret: secret, expiration: expiration)
    }

    private func blankImageData() -> Data? {
        guard let imageURL = Bundle(for: type(of: self)).url(forResource: "testImage", withExtension: "png"), let data = try? Data(contentsOf: imageURL) else { return nil }
        return data
    }

    private func randomTestUUID() -> String {
        return "test.\(UUID().uuidString)"
    }
}

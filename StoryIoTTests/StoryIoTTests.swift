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

    func testPublishSmall() {

        let expectation = self.expectation(description: "StoryIoT.PublishSmall")

        let body: [String: Any] = [
            "testKey": "testValue"
        ]

        let message = SIOTMessageModel(body: body)
        message.eventId = "storyiot.test.publishSmall"
        message.userId = self.randomTestUUID()
        message.entityId = self.randomTestUUID()
        message.created = Date()
        message.operationType = (arc4random() % 2 == 0) ? .update : .create

        self.storyIoT?.publishSmall(message: message, success: { response in
            expectation.fulfill()
        }, failure: { error in
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

        guard let data = self.testImageData() else {
            XCTFail("Error converting testImage.png to Data")
            return
        }

        let message = SIOTMessageModel(data: data)
        message.eventId = "storyiot.test.publishLarge"
        message.userId = self.randomTestUUID()
        message.entityId = self.randomTestUUID()
        message.created = Date()
        message.operationType = (arc4random() % 2 == 0) ? .update : .create

        self.storyIoT?.publishLarge(message: message, success: { response in
            expectation.fulfill()
        }, failure: { error in
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

    private func testImageData() -> Data? {
        guard let imageURL = Bundle(for: type(of: self)).url(forResource: "testImage", withExtension: "png"), let data = try? Data(contentsOf: imageURL) else { return nil }
        return data
    }

    func randomTestUUID() -> String {
        return "test.\(UUID().uuidString)"
    }
}

//
//  AssetManagerTest.swift
//  RavencoinTests
//
//  Created by Austin Hill on 5/17/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import XCTest
import Foundation

@testable import Ravencoin

class CoreDatabaseTest: XCTestCase {
    
    var db: CoreDatabase!
    let dbLock = DispatchSemaphore(value: 1)

    override func setUpWithError() throws {
        db = CoreDatabase()
        
        dbLock.wait()
        db.clearBlacklist {
            self.dbLock.signal()
        }
        
        dbLock.wait()
        db.clearWhitelist {
            self.dbLock.signal()
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        db.close()
        db = nil
    }

    func testDbWhitelist() throws {
        let loadExpectation = self.expectation(description: "Load empty whitelist")
        dbLock.wait()
        db.loadWhitelist { whitelist in
            XCTAssertEqual(whitelist.count, 0, "whitelist should be empty")
            self.dbLock.signal()
            loadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        var whitelist = ["Test", "Test2", "Test3"]
        for asset in whitelist {
            dbLock.wait()
            db.addToWhitelist(assetName: asset) { _ in
                self.dbLock.signal()
            }
        }
        
        let reloadExpectation = self.expectation(description: "Load populated whitelist")
        dbLock.wait()
        db.loadWhitelist { returnList in
            XCTAssertEqual(returnList.count, whitelist.count, "whitelist should have \(whitelist.count) values")
            let sortedReturnList = returnList.sorted()
            whitelist.sort()
            
            for (index, value) in whitelist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            reloadExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        
        let noRemoveExpectation = self.expectation(description: "Wait for removal operation")
        dbLock.wait()
        db.addToWhitelist(assetName: "Test3") { success in
            XCTAssertFalse(success, "Duplicate assets should not be added")
            self.dbLock.signal()
            noRemoveExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let recountExpectation = self.expectation(description: "Load whitelist again to see if there are changes")
        dbLock.wait()
        db.loadWhitelist { returnList in
            XCTAssertEqual(returnList.count, whitelist.count, "Last whitelist addition should not have made it into the db")
            let sortedReturnList = returnList.sorted()
            whitelist.sort()
            
            for (index, value) in whitelist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            recountExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let assetToRemove = "Test3"
        whitelist.removeAll(where: {$0 == assetToRemove})
        let removeExpectation = self.expectation(description: "Wait for removal operation")
        dbLock.wait()
        db.removeFromWhitelist(assetName: assetToRemove) {
            self.dbLock.signal()
            removeExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let removedExpectation = self.expectation(description: "Wait for reload of whitelist")
        dbLock.wait()
        db.loadWhitelist { returnList in
            XCTAssertEqual(returnList.count, whitelist.count, "Whitelist removal should have committed in the db")
            let sortedReturnList = returnList.sorted()
            whitelist.sort()
            
            for (index, value) in whitelist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            removedExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testDbBlacklist() throws {
        let loadExpectation = self.expectation(description: "Load empty blacklist")
        db.loadBlacklist { blacklist in
            XCTAssertEqual(blacklist.count, 0, "blacklist should be empty")
            loadExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        var blacklist = ["Test", "Test2", "Test3"]
        for asset in blacklist {
            dbLock.wait()
            db.addToBlacklist(assetName: asset) { _ in
                self.dbLock.signal()
            }
        }
        
        let reloadExpectation = self.expectation(description: "Load populated blacklist")
        dbLock.wait()
        db.loadBlacklist { returnList in
            XCTAssertEqual(returnList.count, blacklist.count, "blacklist should have \(blacklist.count) values")
            let sortedReturnList = returnList.sorted()
            blacklist.sort()
            
            for (index, value) in blacklist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            reloadExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        
        let noRemoveExpectation = self.expectation(description: "Wait for removal operation")
        dbLock.wait()
        db.addToBlacklist(assetName: "Test3") { success in
            XCTAssertFalse(success, "Duplicate assets should not be added")
            self.dbLock.signal()
            noRemoveExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let recountExpectation = self.expectation(description: "Load blacklist again to see if there are changes")
        dbLock.wait()
        db.loadBlacklist { returnList in
            XCTAssertEqual(returnList.count, blacklist.count, "Last blacklist addition should not have made it into the db")
            let sortedReturnList = returnList.sorted()
            blacklist.sort()
            
            for (index, value) in blacklist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            recountExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let assetToRemove = "Test3"
        blacklist.removeAll(where: {$0 == assetToRemove})
        let removeExpectation = self.expectation(description: "Wait for removal operation")
        dbLock.wait()
        db.removeFromBlacklist(assetName: assetToRemove) {
            self.dbLock.signal()
            removeExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let removedExpectation = self.expectation(description: "Wait for reload of blacklist")
        dbLock.wait()
        db.loadBlacklist { returnList in
            XCTAssertEqual(returnList.count, blacklist.count, "blacklist removal should have committed in the db")
            let sortedReturnList = returnList.sorted()
            blacklist.sort()
            
            for (index, value) in blacklist.enumerated() {
                XCTAssertEqual(value, sortedReturnList[index])
            }
            self.dbLock.signal()
            removedExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}

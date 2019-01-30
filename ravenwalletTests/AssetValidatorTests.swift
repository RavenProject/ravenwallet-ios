//
//  AssetValidatorTests.swift
//  RavencoinTests
//
//  Created by Ben on 10/13/18.
//  Copyright © 2018 Medici Ventures. All rights reserved.
//

import XCTest
@testable import Ravencoin

class AssetValidatorTests: XCTestCase {
    
    let assetValidator = AssetValidator()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
       
        // regular ALLOWED
        XCTAssert(assetValidator.IsAssetNameValid(name: "MIN").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "MIN").1 == AssetType.ROOT)
        XCTAssert(assetValidator.IsAssetNameValid(name: "MAX_ASSET_IS_30_CHARACTERS_LNG").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "MAX_ASSET_IS_31_CHARACTERS_LONG").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "MAX_ASSET_IS_31_CHARACTERS_LONG").1 == AssetType.INVALID)
        XCTAssert(assetValidator.IsAssetNameValid(name: "A_BCDEFGHIJKLMNOPQRSTUVWXY.Z").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "0_12345678.9").0 == true)
        
        //NOT ALLOWED
        XCTAssert(assetValidator.IsAssetNameValid(name: "NO").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "nolower").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "NO SPACE").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "(#&$(&*^%$))").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "_ABC").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "ABC_").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "(“.ABC").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "(“ABC.").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "(“AB..C").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "(“A__BC").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "A._BC").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "AB_.C").0 == false)
        
        //- Versions of RAVENCOIN NOT allowed
        XCTAssert(assetValidator.IsAssetNameValid(name: "RVN").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "RAVEN").0 == false)
        XCTAssert(assetValidator.IsAssetNameValid(name: "RAVENCOIN").0 == false)
        
        //- Versions of RAVENCOIN ALLOWED
        XCTAssert(assetValidator.IsAssetNameValid(name: "RAVEN.COIN").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "RAVEN_COIN").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "RVNSPYDER").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "SPYDERRVN").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "RAVENSPYDER").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "SPYDERAVEN").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "BLACK_RAVENS").0 == true)
        XCTAssert(assetValidator.IsAssetNameValid(name: "SERVNOT").0 == true)


    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

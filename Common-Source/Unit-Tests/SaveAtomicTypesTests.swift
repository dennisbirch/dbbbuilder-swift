//
//  SaveAtomicTypesTests.swift
//  DBBBuilder-Demo-OSXTests
//
//  Created by Dennis Birch on 2/15/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder
#if os(iOS)
@testable import DBBBuilder_Demo_iOS
#else
@testable import DBBBuilder_Demo_OSX
#endif


class SaveAtomicTypesTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }

    
    func testSaveAllTypes() {
        dbManager = CommonTestTask.defaultTestManager(tables: [AllTypesTestClass.self])
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let testBool = true
        let testBool2 = true
        let testBool3 = false
        let testInt = 43
        let testInt2 = 53
        let testInt3 = 91
        let testFloat = 33.67
        let testFloat2 = 53232.9
        let testFloat3 = 324.23098431
        let testString = "testing all types"
        let testStr2 = "unit tests are great"
        let testStr3 = "especially when they pass"
        let testDate = Date.init(timeIntervalSinceReferenceDate: testFloat)
        let testDate2 = Date.init(timeIntervalSinceReferenceDate: testFloat2)
        let testDate3 = Date.init(timeIntervalSinceReferenceDate: testFloat3)
        let testBinaryString = "\(testString)-\(testStr2): \(testStr3)"
        
        let tester = AllTypesTestClass(dbManager: manager)
        tester.boolTestVar = testBool
        tester.intTestVar = testInt
        tester.floatTestVar = testFloat
        tester.dateTestVar = testDate
        tester.stringTestVar = testString
        if let testBinaryData = testBinaryString.data(using: .utf8) {
            tester.binaryTestVar = testBinaryData
        } else {
            XCTFail()
        }
        tester.boolArrayTestVar = [testBool, testBool2, testBool3]
        tester.intArrayTestVar = [testInt, testInt2, testInt3]
        tester.floatArrayTestVar = [testFloat, testFloat2, testFloat3]
        tester.stringArrayTestVar = [testString, testStr2, testStr3]
        tester.dateArrayTestVar = [testDate, testDate2, testDate3]
        
        let success = tester.saveToDB()
        XCTAssertTrue(success)
        
        let newID = tester.idNum
        guard let newInstance = AllTypesTestClass.instanceWithIDNumber(newID, manager: manager) as? AllTypesTestClass else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(newInstance.boolTestVar, testBool)
        XCTAssertEqual(newInstance.intTestVar, testInt)
        XCTAssertEqual(newInstance.floatTestVar, testFloat)
        XCTAssertEqual(newInstance.dateTestVar, testDate)
        XCTAssertEqual(newInstance.boolArrayTestVar, [testBool, testBool2, testBool3])
        XCTAssertEqual(newInstance.intArrayTestVar, [testInt, testInt2, testInt3])
        XCTAssertEqual(newInstance.floatArrayTestVar, [testFloat, testFloat2, testFloat3])
        guard let binaryTestString = String(data: newInstance.binaryTestVar, encoding: .utf8) else {
            XCTFail()
            return
        }
        XCTAssertEqual(binaryTestString, testBinaryString)
    }

    func testSaveAllTypesWithCustomColumnNames() {
        dbManager = CommonTestTask.defaultTestManager(tables: [AllTypesCustomColumnsTestClass.self])
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let testBool = true
        let testBool2 = true
        let testBool3 = false
        let testInt = 43
        let testInt2 = 53
        let testInt3 = 91
        let testFloat = 33.67
        let testFloat2 = 53232.9
        let testFloat3 = 324.23098431
        let testString = "testing all types"
        let testStr2 = "unit tests are great"
        let testStr3 = "especially when they pass"
        let testDate = Date.init(timeIntervalSinceReferenceDate: testFloat)
        let testDate2 = Date.init(timeIntervalSinceReferenceDate: testFloat2)
        let testDate3 = Date.init(timeIntervalSinceReferenceDate: testFloat3)
        let testBinaryString = "\(testString)-\(testStr2): \(testStr3)"
        
        let tester = AllTypesCustomColumnsTestClass(dbManager: manager)
        tester.boolTestVar = testBool
        tester.intTestVar = testInt
        tester.stringTestVar = testString
        tester.floatTestVar = testFloat
        tester.dateTestVar = testDate
        if let testBinaryData = testBinaryString.data(using: .utf8) {
            tester.binaryTestVar = testBinaryData
        } else {
            XCTFail()
        }
        tester.boolArrayTestVar = [testBool, testBool2, testBool3]
        tester.intArrayTestVar = [testInt, testInt2, testInt3]
        tester.floatArrayTestVar = [testFloat, testFloat2, testFloat3]
        tester.stringArrayTestVar = [testString, testStr2, testStr3]
        tester.dateArrayTestVar = [testDate, testDate2, testDate3]
        
        let success = tester.saveToDB()
        XCTAssertTrue(success)
        
        let newID = tester.idNum
        guard let newInstance = AllTypesCustomColumnsTestClass.instanceWithIDNumber(newID, manager: manager) as? AllTypesCustomColumnsTestClass else {
            XCTFail()
            return
        }
        
        // test that retrieved values are equal to saved object's values
        XCTAssertEqual(newInstance.boolTestVar, testBool)
        XCTAssertEqual(newInstance.intTestVar, testInt)
        XCTAssertEqual(newInstance.floatTestVar, testFloat)
        XCTAssertEqual(newInstance.dateTestVar, testDate)
        XCTAssertEqual(newInstance.boolArrayTestVar, [testBool, testBool2, testBool3])
        XCTAssertEqual(newInstance.intArrayTestVar, [testInt, testInt2, testInt3])
        XCTAssertEqual(newInstance.floatArrayTestVar, [testFloat, testFloat2, testFloat3])
        guard let binaryTestString = String(data: newInstance.binaryTestVar, encoding: .utf8) else {
            XCTFail()
            return
        }
        XCTAssertEqual(binaryTestString, testBinaryString)
        
        guard let tableColumns = CommonTestTask.tableColumnsDict(manager: manager)?[newInstance.shortName] else {
            XCTFail()
            return
        }
        
        // check schema for correct custom column names
        XCTAssertTrue(tableColumns.contains("\(AllTypesCustomColumnsTestClass.CustomColumnKeys.boolTestCustom) Boolean"))
        XCTAssertTrue(tableColumns.contains("\(AllTypesCustomColumnsTestClass.CustomColumnKeys.intTestCustom) Integer"))
        XCTAssertTrue(tableColumns.contains("\(AllTypesCustomColumnsTestClass.CustomColumnKeys.floatTestCustom) Real"))
        XCTAssertTrue(tableColumns.contains("\(AllTypesCustomColumnsTestClass.CustomColumnKeys.stringTestCustom) Text"))
        XCTAssertTrue(tableColumns.contains("\(AllTypesCustomColumnsTestClass.CustomColumnKeys.dateTestCustom) Real"))
        XCTAssertFalse(tableColumns.contains("\(AllTypesCustomColumnsTestClass.Keys.boolTestVar) Boolean"))
        XCTAssertFalse(tableColumns.contains("\(AllTypesCustomColumnsTestClass.Keys.intTestVar) Integer"))
        XCTAssertFalse(tableColumns.contains("\(AllTypesCustomColumnsTestClass.Keys.floatTestVar) Real"))
        XCTAssertFalse(tableColumns.contains("\(AllTypesCustomColumnsTestClass.Keys.stringTestVar) Text"))
        XCTAssertFalse(tableColumns.contains("\(AllTypesCustomColumnsTestClass.Keys.dateTestVar) Real"))
    }

}

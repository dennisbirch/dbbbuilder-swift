//
//  DBBTableBuilderTests.swift
//  DBBBuilderTests
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder

import os.log

class DBBTableBuilderTests: XCTestCase {

    func testTableCreationString() {
        guard let dbMgr = CommonTestTask.defaultTestManager(tables: [Person.self]) else {
            XCTFail()
            return
        }
        let donalddock = Person(firstName: "Donald", lastName: "Dock", age: 41, dbManager: dbMgr)
        XCTAssertNotNil(donalddock)
        
        let tableCreationString = donalddock.tableCreationString
        XCTAssertTrue(tableCreationString.isEmpty == false)
        
        XCTAssertTrue(tableCreationString.contains("CREATE TABLE IF NOT EXISTS Person"))
        XCTAssertTrue(tableCreationString.contains("modifiedTime Real"))
        XCTAssertTrue(tableCreationString.contains("age Integer"))
        XCTAssertTrue(tableCreationString.contains("createdTime Real"))
        XCTAssertTrue(tableCreationString.contains("lastName Text"))
        XCTAssertTrue(tableCreationString.contains("id Integer PRIMARY KEY AUTOINCREMENT"))
        XCTAssertTrue(tableCreationString.contains("firstName Text NOT NULL"))
    }


}

//
//  DBBManagerExecuteSQLTests.swift
//  DBBBuilderTests
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder
#if os(iOS)
@testable import DBBBuilder_Demo_iOS
#else
@testable import DBBBuilder_Demo_OSX
#endif

class DBBBuilderTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()

        dbManager = CommonTestTask.defaultTestManager(tables: [Testing.self])
    }
    
    
    override func tearDown() {
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testExecuteSQL() {
        guard let dbMgr = dbManager else {
            XCTFail()
            return
        }
        
        let tableName = Testing(dbManager: dbMgr).shortName

        var count = dbMgr.countForTable(tableName)
        XCTAssertEqual(count, 0)
        
        let joeSchmo = "Joe Schmo"
        let joeAge = 47
        let bettySchmo = "Betty Schmo"
        let bettyAge = 43
        // insert with arguments array
        var insertSQL = "INSERT INTO \(tableName) (Name, Age) VALUES (?,?)"
        let executor = DBBDatabaseExecutor(manager: dbMgr)
        do {
            try executor.executeUpdate(sql: insertSQL, withArgumentsIn: [joeSchmo, joeAge])
        } catch {
            XCTFail()
        }

        // insert with "embedded" arguments
        insertSQL = "INSERT INTO \(tableName) (Name, Age) VALUES ('\(bettySchmo)', \(bettyAge))"
        let success = executor.executeStatements(insertSQL)
        XCTAssertTrue(success)

        count = dbMgr.countForTable(tableName)
        XCTAssertEqual(count, 2)
    }

}


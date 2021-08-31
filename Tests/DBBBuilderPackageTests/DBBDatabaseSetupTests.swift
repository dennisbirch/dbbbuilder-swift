//
//  DBBDatabaseSetupTests.swift
//  DBBBuilderTests
//
//  Created by Dennis Birch on 1/10/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder

class DBBDatabaseSetupTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
    }
    
    func testCreateTableStrings() {
        deleteFile()
        
        // create a manager which will force creation of new file with new "create table" statements
        createManager()
        
        guard let manager = dbManager, let savedTableNames = CommonTestTask.tableColumnsDict(manager: manager) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(savedTableNames.keys.contains("Company"))
        XCTAssertTrue(savedTableNames.keys.contains("Person"))
        
        let originalTableNames = savedTableNames
        
        // create a new manager which validates current file -- should not change anything now
        createManager()
        
        XCTAssertEqual(savedTableNames, originalTableNames)
        XCTAssertTrue(savedTableNames.keys.contains("Company"))
        XCTAssertTrue(savedTableNames.keys.contains("Person"))
        
        deleteFile()
    }
    
    func testAlterTable() {
        deleteFile()
        createManager()

        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        manager.addTableClasses([AlterTableTest.self])
        
        guard let savedTableNames = CommonTestTask.tableColumnsDict(manager: manager) else {
            XCTFail()
            return
        }
        
        let alterTableName = AlterTableTest.tableName()
        XCTAssertTrue(savedTableNames.keys.contains(alterTableName))
        guard let columns = CommonTestTask.tableColumnsDict(manager: manager) else {
            XCTFail()
            return
        }
        
        guard let persistenceMapColumns = columns[AlterTableTest.tableName()] else {
            XCTFail()
            return
        }

        XCTAssertTrue(persistenceMapColumns.contains("name Text"))
        XCTAssertTrue(persistenceMapColumns.contains("date Real"))
        XCTAssertTrue(persistenceMapColumns.contains("count Integer"))
        XCTAssertFalse(persistenceMapColumns.contains("testRun Integer"))
        XCTAssertFalse(persistenceMapColumns.contains("output Text"))

        let map: [String : DBBPropertyPersistence] = ["testRun" : DBBPropertyPersistence(type: .int),
                                                      "result" : DBBPropertyPersistence(type: .string, columnName: "output")]
        
        // add new properties to the persistenceMap
        let instance = AlterTableTest.init(dbManager: manager)
        let db = manager.database
        guard let url = db.databaseURL else {
            XCTFail()
            return
        }
        let alterManager = DBBManager(databaseURL: url)
        alterManager.addPersistenceMapping(map, for: instance)
        alterManager.addTableClasses([AlterTableTest.self])
        guard let alteredColumns = CommonTestTask.tableColumnsDict(manager: alterManager) else {
            XCTFail()
            return
        }
        guard let alteredPersistenceMapColumns = alteredColumns["AlterTableTest"] else {
            XCTFail()
            return
        }

        XCTAssertTrue(alteredPersistenceMapColumns.contains("name Text"))
        XCTAssertTrue(alteredPersistenceMapColumns.contains("date Real"))
        XCTAssertTrue(alteredPersistenceMapColumns.contains("count Integer"))
        XCTAssertTrue(alteredPersistenceMapColumns.contains("testRun Integer"))
        XCTAssertTrue(alteredPersistenceMapColumns.contains("output Text"))
        
        deleteFile()
    }
    
    func testSQLifyString() {
        let testString1 = "Buds"
        let testString2 = "Bud's"
        let sqlify1 = testString1.dbb_SQLEscaped()
        let sqlify2 = testString2.dbb_SQLEscaped()
        
        XCTAssertEqual(sqlify1, "'Buds'")
        XCTAssertEqual(sqlify2, "'Bud''s'")
    }
    
    // MARK: - Helpers
        
    private func deleteFile() {
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    private func createManager() {
        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self])
    }

}


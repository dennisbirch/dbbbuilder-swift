//
//  CommonTestTask.swift
//  DBBBuilderTests
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
@testable import DBBBuilder
import os.log

struct CommonTestTask {
    
    static func docsURL() -> URL? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsURL = urls.first
        assert(docsURL != nil)
        let fileURL = docsURL?.appendingPathComponent("DBBTests-Data.sqlite")
        os_log("File URL for test file: %@", fileURL?.absoluteString ?? "")
        return fileURL
    }
    

    static func deleteDBFile(dbManager: DBBManager?) {
        guard let url = dbManager?.database.databaseURL else {
            return
        }
        
        dbManager?.database.close()
        
        do {
            try FileManager.default.removeItem(at: url)
        }
        catch {
            os_log("Failed to remove test database file in teardown")
        }
    }
    
    static func defaultTestManager(tables: [DBBTableObject.Type]) -> DBBManager? {
        guard let url = docsURL() else {
            return nil
        }
        
        let dbMgr = DBBManager(databaseURL: url)
        dbMgr.addTableClasses(tables)
        return dbMgr
    }
    
    private static func savedTables(manager: DBBManager) -> FMResultSet? {
        let sql = "SELECT name, sql FROM sqlite_master WHERE type = 'table'"
        let executor = DBBDatabaseExecutor(db: manager.database)
        guard let result = executor.runQuery(sql) else {
            return nil
        }
        
        return result
    }
    
    static func tableColumnsDict(manager: DBBManager) -> [String : [String]]? {
        var savedTableNames = [String : [String]]()
        guard let result = savedTables(manager: manager) else {
            return nil
        }
        
        while result.next() == true {
            let resultDict = result.resultDictionary
            guard let unwrappedDict = resultDict else {
                return nil
            }
            if let table = unwrappedDict["name"] as? String, let sql = unwrappedDict["sql"] as? String {
                let columns = sql.replacingOccurrences(of: "CREATE TABLE \(table) (", with: "").replacingOccurrences(of: ")", with: "")
                savedTableNames[table] = columns.components(separatedBy: ", ")
            }
        }
        
        return savedTableNames
    }

}

// a class for use with the testExecuteSQL function
final class Testing: DBBTableObject {
    @objc var name: String = ""
    @objc var age: Int = 0
    
    required init(dbManager: DBBManager) {
        // for DBBManager initialization
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = ["name" : DBBPropertyPersistence(type: .string),
                                                      "age" : DBBPropertyPersistence(type: .int)]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }    
}

// a class for use with the testAlterTable function
final class AlterTableTest: DBBTableObject {
    @objc var name = ""
    @objc var date = Date()
    @objc var count = 0
    @objc var testRun = 0
    @objc var result = ""
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        let map: [String : DBBPropertyPersistence] = ["name" : DBBPropertyPersistence(type: .string),
                                                      "date" : DBBPropertyPersistence(type: .date),
                                                      "count" : DBBPropertyPersistence(type: .int)]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
}

// a class for use with the testAlterTable function
final class AlterJoinTest: DBBTableObject {
    @objc var name = ""
    @objc var date = Date()
    @objc var count = 0
    @objc var testRuns = [Int]()
    @objc var result = ""
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        let map: [String : DBBPropertyPersistence] = ["name" : DBBPropertyPersistence(type: .string),
                                                      "date" : DBBPropertyPersistence(type: .date),
                                                      "count" : DBBPropertyPersistence(type: .int)]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
}

// a class for testing persistence of all basic types
final class AllTypesTestClass: DBBTableObject {
    struct Keys {
        static let boolTestVar = "boolTestVar"
        static let intTestVar = "intTestVar"
        static let floatTestVar = "floatTestVar"
        static let stringTestVar = "stringTestVar"
        static let dateTestVar = "dateTestVar"
        static let binaryTestVar = "binaryTestVar"
        static let boolArrayTestVar = "boolArrayTestVar"
        static let intArrayTestVar = "intArrayTestVar"
        static let floatArrayTestVar = "floatArrayTestVar"
        static let stringArrayTestVar = "stringArrayTestVar"
        static let dateArrayTestVar = "dateArrayTestVar"
    }
    
    @objc var boolTestVar = false
    @objc var intTestVar = 0
    @objc var floatTestVar = 0.0
    @objc var stringTestVar = ""
    @objc var dateTestVar = Date()
    @objc var binaryTestVar = Data()
    @objc var boolArrayTestVar = [Bool]()
    @objc var intArrayTestVar = [Int]()
    @objc var floatArrayTestVar = [Double]()
    @objc var stringArrayTestVar = [String]()
    @objc var dateArrayTestVar = [Date]()
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map = [Keys.boolTestVar : DBBPropertyPersistence(type: .bool),
                   Keys.intTestVar : DBBPropertyPersistence(type: .int),
                   Keys.floatTestVar : DBBPropertyPersistence(type: .float),
                   Keys.stringTestVar : DBBPropertyPersistence(type: .string),
                   Keys.dateTestVar : DBBPropertyPersistence(type: .date),
                   Keys.binaryTestVar : DBBPropertyPersistence(type: .binary),
                   Keys.boolArrayTestVar : DBBPropertyPersistence(type: .boolArray),
                   Keys.intArrayTestVar : DBBPropertyPersistence(type: .intArray),
                   Keys.floatArrayTestVar : DBBPropertyPersistence(type: .floatArray),
                   Keys.stringArrayTestVar : DBBPropertyPersistence(type: .stringArray),
                   Keys.dateArrayTestVar : DBBPropertyPersistence(type: .dateArray)]
        
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
}


// a class for testing persistence of all basic types with custom column names
class AllTypesCustomColumnsTestClass: DBBTableObject {
    struct Keys {
        static let boolTestVar = "boolTestVar"
        static let intTestVar = "intTestVar"
        static let floatTestVar = "floatTestVar"
        static let stringTestVar = "stringTestVar"
        static let dateTestVar = "dateTestVar"
        static let binaryTestVar = "binaryTestVar"
        static let boolArrayTestVar = "boolArrayTestVar"
        static let intArrayTestVar = "intArrayTestVar"
        static let floatArrayTestVar = "floatArrayTestVar"
        static let stringArrayTestVar = "stringArrayTestVar"
        static let dateArrayTestVar = "dateArrayTestVar"
    }
    
    struct CustomColumnKeys {
        static let boolTestCustom = "boolTestColumn"
        static let intTestCustom = "intTestColumn"
        static let floatTestCustom = "floatTestColumn"
        static let stringTestCustom = "stringTestColumn"
        static let dateTestCustom = "dateTestColumn"
        static let binaryTestCustom = "binaryTestColumn"
        static let boolArrayTestCustom = "boolArrayTestColumn"
        static let intArrayTestCustom = "intArrayTestColumn"
        static let floatArrayTestCustom = "floatArrayTestColumn"
        static let stringArrayTestCustom = "stringArrayTestColumn"
        static let dateArrayTestCustom = "dateArrayTestColumn"
    }
    
    @objc var boolTestVar = false
    @objc var intTestVar = 0
    @objc var floatTestVar = 0.0
    @objc var stringTestVar = ""
    @objc var dateTestVar = Date()
    @objc var binaryTestVar = Data()
    @objc var boolArrayTestVar = [Bool]()
    @objc var intArrayTestVar = [Int]()
    @objc var floatArrayTestVar = [Double]()
    @objc var stringArrayTestVar = [String]()
    @objc var dateArrayTestVar = [Date]()
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map = [Keys.boolTestVar : DBBPropertyPersistence(type: .bool, columnName: CustomColumnKeys.boolTestCustom),
                   Keys.intTestVar : DBBPropertyPersistence(type: .int, columnName: CustomColumnKeys.intTestCustom),
                   Keys.floatTestVar : DBBPropertyPersistence(type: .float, columnName: CustomColumnKeys.floatTestCustom),
                   Keys.stringTestVar : DBBPropertyPersistence(type: .string, columnName: CustomColumnKeys.stringTestCustom),
                   Keys.dateTestVar : DBBPropertyPersistence(type: .date, columnName: CustomColumnKeys.dateTestCustom),
                   Keys.binaryTestVar : DBBPropertyPersistence(type: .binary, columnName: CustomColumnKeys.binaryTestCustom),
                   Keys.boolArrayTestVar : DBBPropertyPersistence(type: .boolArray, columnName: CustomColumnKeys.boolArrayTestCustom),
                   Keys.intArrayTestVar : DBBPropertyPersistence(type: .intArray, columnName: CustomColumnKeys.intArrayTestCustom),
                   Keys.floatArrayTestVar : DBBPropertyPersistence(type: .floatArray, columnName: CustomColumnKeys.floatArrayTestCustom),
                   Keys.stringArrayTestVar : DBBPropertyPersistence(type: .stringArray, columnName: CustomColumnKeys.stringArrayTestCustom),
                   Keys.dateArrayTestVar : DBBPropertyPersistence(type: .dateArray, columnName: CustomColumnKeys.dateArrayTestCustom)]
        
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
}

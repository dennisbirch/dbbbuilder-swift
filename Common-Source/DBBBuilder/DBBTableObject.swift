//
//  DBBTableObject.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

typealias ValueTuple = (label: String, value: String)
typealias ParamsAndValues = (params: [String], values: [String])

@objc open class DBBTableObject: NSObject {
    /**
     A struct with DBBTableObject property name definitions for use in constructing the peristenceMap. These keys are also used elsewhere in the DBBBuilder framework, and can be used in an app to avoid hard-coding lookup terms.
     
     - Note: DBBBuilder framework makes use of Key Value Observing to set property values for its DBBTableObject subclasses. As such, properties that you want to persist in your subclasses must be marked with the `@objc` attribute. They must also be added to the subclass's persistenceMap property. See documentation of the persistenceMap property below for more information.
     */
    public struct Keys {
        public static let createdTime = "createdTime"
        public static let modifiedTime = "modifiedTime"
        public static let id = "id"
    }
    
    // MARK: - Properties
    /**
    A publicly accessible property that mirrors the internal `id` property. This is a workaround to maintain read-only status for the `id` property outside the framework. (Declaring a property as `@obj public private(set) var foo: Type` causes a Swift build error.)
     */
    public var idNum: Int64 = 0
    /**
     A date/time stamp set on each DBBTableObject instance when it is first saved to its SQLite file.
     */
    @objc public var createdTime: Date?
    /**
     A date/time stamp set on each DBBTableObject instance when it is first saved to its SQLite file and on every subsequent save.
 */
    @objc public var modifiedTime: Date?
    /**
     A unique primary key automatically added to each DBBTableObject instance when it is first written to its SQLite file. This property is used internally, but is not available outside the framework. To get the `id` property outside the framework (e.g. for fetches or checking uniqueness), refer to the `idNum` property which is publicly accessible.
 */
    @objc var id: Int64 = 0 {
        didSet {
            idNum = id
        }
    }

    /**
     An optional [String : String] dictionary that lets you define column attributes for individual properties. The key for each entry should be the property name, and the value for each entry should be one of the members of the `ColumnAttribute` struct defined in the DBBBuilder.swift file. Currently supported attributes are:
     -  NOT NULL
     -  UNIQUE
 */
    public var attributesDictionary: [String : String]?
    
    /**
     A public property you can use to track the `dirty` state of any DBTableObject subclass instance.
     */
    public var isDirty = false
    
    lazy var tableCreationString: String = {
        let builder = DBBTableBuilder(table: self)
        return builder.createTableString()
    }()
    
    /**
     A public property you can use to get the class name without hard-coding it
     */
    public lazy var shortName: String = {
        let cName = class_getName(type(of: self))
        let fullName = String.init(cString: cName)
        let components = fullName.split(separator: ".")
        return String(components.last ?? "")
    }()
    
    /**
     A public property you can get to set properties and call functions on the class's DBManager.
     */
    public var dbManager: DBBManager
    
    let logger = DBBBuilder.logger(withCategory: "DBBTableObject")

    static let defaultPropertiesMap: [String : DBBPropertyPersistence] = [Keys.id : DBBPropertyPersistence(type: .int),
                                                   Keys.createdTime : DBBPropertyPersistence(type: .date),
                                                   Keys.modifiedTime : DBBPropertyPersistence(type: .date)]

    // MARK: - Initializers
    /**
     Init method used to instantiate an instance. All subclasses must override this method.
     - Parameters:
        - dbManager: The DBBManager instance that 'owns' this class.
     */
    public required init(dbManager: DBBManager) {
        self.dbManager = dbManager
        
        super.init()
        
        if dbManager.persistenceMap[shortName] != nil {
            return
        }
        dbManager.initializePersistenceContents(DBBTableObject.defaultPropertiesMap, forTableNamed: shortName)
    }
    
    /**
     A static method to delete an instance of a DBBTableObject subclass.
     
     - Parameters:
        - instance: The object you want to delete.
        - manager: The instance of the DBBManager that owns the FMDatabase instance and SQLite file containing the object to be deleted.
     
     - Returns: A Bool value indicating successful completion.
     
     An example of using this method:
     ```
    let success = Player.deleteInstance(retiringPlayer, manager: myManager)
     ```
 */
    public static func deleteInstance(_ instance: DBBTableObject, manager: DBBManager) -> Bool {
        let idNum = instance.id
        let instance = self.init(dbManager: manager)
        let tableName = instance.shortName
        var sql = "DELETE FROM \(tableName) WHERE \(Keys.id) = ?"
        let executor = DBBDatabaseExecutor(manager: manager)
        let success = executor.executeUpdate(sql: sql, withArgumentsIn: [idNum])
        let logger = DBBBuilder.logger(withCategory: "DBBTableObject")
        os_log("Executed DELETE statement with SQL: %@ – success: %@", log: logger, type: defaultLogType, sql, (success == true) ? "true" : "false")
        if success == false {
            os_log("Error deleting instance: %@", log: logger, type: defaultLogType, manager.errorMessage())
        }
        
        // check join tables
        if let joinMap = manager.joinMapDict[tableName] {
            let keys = joinMap.keys
            for key in keys {
                if let propertyMap = joinMap[key] {
                    let joinTable = propertyMap.joinTableName
                    let parentColumn = propertyMap.parentJoinColumn
                    sql = "DELETE FROM \(joinTable) WHERE \(parentColumn) = ?"
                    let _ = executor.executeUpdate(sql: sql, withArgumentsIn: [idNum])
                }
            }
        }
        
        return success
    }
    
    /**
     A static method to delete multiple instances of a DBBTableObject subclass.
     
     - Parameters:
         - instances: Array containing the objects you want to delete.
         - manager: The instance of the DBBManager that owns the FMDatabase instance and SQLite file containing the object to be deleted.
     
     - Returns: A Bool value indicating successful completion.
     
     An example of using this method:
     ```
    let success = deleteMultipleInstances(retiringPlayers, manager: myManager)
     ```
     */
    public static func deleteMultipleInstances(_ instances: [DBBTableObject], manager: DBBManager) -> Bool {
        var success = true
        for instance in instances {
            let instanceSuccess = self.deleteInstance(instance, manager: manager)
            if instanceSuccess == false {
                os_log("Deleting instance of %@ with idNum %@ failed.", log: DBBBuilder.logger(withCategory: "DBBTableObject"), type: defaultLogType, self.init(dbManager: manager).shortName, String(instance.id))
                success = false
            }
        }
        
        return success
    }
    
    /**
     A static method to delete all instances of a DBBTableObject subclass.
     
     - Parameters:
        - manager: The instance of the DBBManager that owns the FMDatabase instance and SQLite file containing the object to be deleted.
     
     - Returns: A Bool value indicating successful completion.
     */
    public static func deleteAllInstances(manager: DBBManager) -> Bool {
        let instance = self.init(dbManager: manager)
        let tableName = instance.shortName
        let executor = DBBDatabaseExecutor(manager: manager)

        // delete join columns
        if let joinMap = manager.joinMapDict[tableName] {
            for (column, map) in joinMap {
                let joinSQL = "DELETE FROM \(map.joinTableName)"
                var success = executor.executeStatements(joinSQL)
                if success == false {
                    os_log("Error deleting join table: %@", log: DBBBuilder.logger(withCategory: "DBBTableOject"), type: defaultLogType, manager.errorMessage())
                }
                let indexName = "\(tableName)_\(column)_idx"
                success = manager.dropIndex(named: indexName)
                if success == false {
                    os_log("Error deleting index: %@: %@", log: DBBBuilder.logger(withCategory: "DBBTableOject"), type: defaultLogType, indexName, manager.errorMessage())
                }
            }
        }

        // and drop indexes
        guard let persistenceMap = manager.persistenceMap[tableName] else {
            os_log("Can't get persistenceMap for %@", tableName)
            return false
        }
        if let indexer = persistenceMap.indexer {
            let columnNames = indexer.columns
            for columnName in columnNames {
                let idxName = "\(tableName)_\(columnName)"
                let success = manager.dropIndex(named: idxName)
                if success == false {
                    os_log("Error deleting index: %@: %@", log: DBBBuilder.logger(withCategory: "DBBTableOject"), type: defaultLogType, idxName, manager.errorMessage())
                }
            }
        }

        // delete primary table
        let sql = "DELETE FROM \(tableName)"
        let success = executor.executeStatements(sql)
        
        manager.vacuumDB()
        
        return success
    }
    
    /**
     A public method that allows setting the dirty state of a DBBTableObject subclass instance.
 */
    public func makeDirty(_ dirty: Bool) {
        isDirty = dirty
    }
    
    static public func tableName() -> String {
        let dbMgr = DBBManager(databaseURL: URL(fileURLWithPath: NSTemporaryDirectory()))
        let instance = self.init(dbManager: dbMgr)
        return instance.shortName
    }
}


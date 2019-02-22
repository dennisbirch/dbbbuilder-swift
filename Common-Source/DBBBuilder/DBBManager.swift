//
//  DBBManager.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation
import FMDB
import os.log

@objc public class DBBManager: NSObject {
    public private(set) var database: FMDatabase
    var persistenceMap = [String : DBBPersistenceMap]()
    var joinMapDict = [String : [String : DBBJoinMap]]()
    private let logger = DBBBuilder.logger(withCategory: "DBBManager")

    /**
     Init method for instantiating a DBBManager instance.
     
     - Parameters:
        - databaseURL: A URL instance representing the database file.
     
     Usage example:
     ```
             let dbManager = DBBManager(url: fileURL)
     ```
     */
    public init(databaseURL: URL) {
        let database = FMDatabase(url: databaseURL)
        self.database = database
        let success = database.open()
        if success == false {
            os_log("Open failed with error message: %@", log: logger, type: defaultLogType, database.lastErrorMessage())
        }
        os_log("Initialized database: %@\nDatabase path: %@", log: logger, type: defaultLogType, (success) ? "true" : "false", database.databasePath ?? "NA")
        
        super.init()
    }
    
    /**
     Public method to set up setup classes under management.
     
     - Parameters:
        - tableClasses: An array of DBBTableObject types. Each subclass type is represented by one table in the resulting SQLite database that is being managed.
     */
    public func addTableClasses(_ tableClasses: [DBBTableObject.Type]) {
        for classType in tableClasses {
            let newClass = classType.init(dbManager: self)
            
            // make sure persistenceMap has been set up
            guard let _ = persistenceMap[newClass.shortName] else {
                os_log("Persistence map for %@ has not been setup", log: logger, type: defaultLogType, newClass.shortName)
                return
            }
            
            var validator = DBBDatabaseValidator(manager: self, table: newClass)
            validator.validateTable()
            let tableJoinMap = validator.joinMapDict
            if tableJoinMap.isEmpty == false {
                self.joinMapDict[newClass.shortName] = tableJoinMap
            }
        }
    }
    
    /**
     Public method to add persistence mapping for a DBBTableObject subclass. This mapping is required in order for any subclass to read and write data from the database.
     
     - Parameters:
        - contents: A [String : DBBPropertyPersistence] dictionary that maps out the storage required for each property in the subclass.
        - forTableNamed: The name of the subclass/database table that the mapped properties belong to.
     */
    public func addPersistenceMapContents(_ contents: [String : DBBPropertyPersistence], forTableNamed table: String, indexer: DBBIndexer? = nil) {
        // only need to add the mapping info once
        if let currentMap = persistenceMap[table], currentMap.map.count > DBBTableObject.defaultPropertiesMap.count {
            return
        }
        
        // get the existing map for the DBBTableObject passed in, or a new instance
        let map: DBBPersistenceMap = persistenceMap[table] ?? DBBPersistenceMap([String : DBBPropertyPersistence](), columnMap: [String : String]())
        // add the new content
        let newMap = map.appendDictionary(contents, indexer: indexer)
        // and update the persistence map dictionary
        persistenceMap[table] = newMap
    }
    
    /**
     A convenience method for getting the count of objects for any DBBTableObject subclass type.
     
     - Parameters:
        - tableName: The name of the DBBTableObject subclass whose count you want to obtain.
 
     - Returns: Int value representing the object count.
    */
    public func countForTable(_ tableName: String) -> Int {
        let query = "SELECT COUNT(*) FROM \(tableName)"
        let executor = DBBDatabaseExecutor(manager: self)
        let result = executor.runQuery(query)
        if let result = result {
            result.next()
            return Int(result.int(forColumnIndex: 0))
        }
        
        // failed
        return 0
    }
    
    /**
     A convenience method for sending the VACUUM command to the database.
     */
   public func vacuumDB() {
        let sql = "VACUUM"
        let executor = DBBDatabaseExecutor(manager: self)
        let _ = executor.executeStatements(sql)
    }
    
    
    /**
     A publicly accessible method for deleting an index.
     
     - Parameters:
     - named: The name of the index to delete from the SQLite file
     
     Returns: A Bool value indicating successful deletion.
     */
    public func dropIndex(named indexName: String) -> Bool {
        let sql = "DROP INDEX IF EXISTS \(indexName)"
        let executor = DBBDatabaseExecutor(manager: self)
        let success = executor.executeUpdate(sql: sql, withArgumentsIn: [])
        os_log("Success dropping index %@: %@", log: logger, type: defaultLogType, indexName, (success == true) ? "true" : "false")
        return success
    }
    
    func initializePersistenceContents(_ contents: [String : DBBPropertyPersistence], forTableNamed table: String) {
        let map = DBBPersistenceMap([String : DBBPropertyPersistence](), columnMap: [String : String]())
        let newMap = map.appendDictionary(contents)
        persistenceMap[table] = newMap
    }
}

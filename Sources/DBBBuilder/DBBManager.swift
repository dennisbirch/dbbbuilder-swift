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
     A convenience method for getting an initialized DBBManager instance located in the user's Documents folder.
     
     - Parameters:
        - named: A String with the file name to create or open if already existing.
        - tableClasses: An array of DBBTableObject *types* that the DBBManager instance manages.
     
     - Returns: A DBBManager instance set up with the table types passed in.
    */
    public static func createDatabaseInDocumentsFolder(named name: String, tableClasses: [DBBTableObject.Type]) -> DBBManager {
        let fileURL = documentsFolder.appendingPathComponent(name)
        let manager = DBBManager(databaseURL: fileURL)
        manager.addTableClasses(tableClasses)
        
        return manager
    }

    /**
     A convenience method for getting an initialized DBBManager instance located in a subfolder of the user's Application Support folder.
     
     - Parameters:
        - named: A String with the file name to create or open if already existing.
        - subFolders: A String specifying the subfolder hierarchy. This is an optional parameter but you will probably want to specify a directory at least one layer deep within Application Support.
        - tableClasses: An array of DBBTableObject *types* that the DBBManager instance manages.
     
     - Returns: A DBBManager instance set up with the table types passed in.
    */
    public static func createDatabaseInAppSupportFolder(named name: String, subFolders: String?, with tableClasses: [DBBTableObject.Type]) -> DBBManager {
        let fileURL = appSupportFolder(using: subFolders).appendingPathComponent(name)
        let manager = DBBManager(databaseURL: fileURL)
        manager.addTableClasses(tableClasses)
        
        return manager
    }
    
    public static func inMemoryDatabaseManager() -> DBBManager {
        let manager = DBBManager()
        return manager        
    }

    /**
     Init method for instantiating a DBBManager instance.
     
     - Parameters:
        - databaseURL: A URL instance representing the database file.
     
     Usage example:
     ```
        let dbManager = DBBManager(databaseURL: fileURL)
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
        
        addTableClasses([DBVersion.self])
    }

    // used for in-memory database
    private override init() {
        let database = FMDatabase(url: nil)
        self.database = database
        let success = database.open()
        if success == false {
            os_log("Open failed with error message: %@", log: logger, type: defaultLogType, database.lastErrorMessage())
        }
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
         Public method to add persistence mapping for a DBBTableObject subclass. This mapping is required in order for any subclass to read and write data to and from the database.
         
         - Parameters:
            - contents: A [String : DBBPropertyPersistence] dictionary that maps out the storage required for each property in the subclass.
            - for: The DBBTableObject subclass whose table the mapped properties belong to.
            - indexer: An optional DBBIndexer argument that defaults to nil. If you want to index any of the properties being mapped, include them in a DBBIndexer instance and pass that indexer in this argument.
         */
    public func addPersistenceMapping(_ contents: [String : DBBPropertyPersistence], for tableObject: DBBTableObject, indexer: DBBIndexer? = nil) {
        if tableObject.superclass == NSObject.self {
            return
        }
        
        let tableName = tableObject.shortName
        
        // get the existing map for the DBBTableObject passed in, or a new instance
        var map: DBBPersistenceMap? = persistenceMap[tableName]
        if let existingMap = map, existingMap.isInitialized == true {
            return
        }
        
        if map == nil {
            map = DBBPersistenceMap([String : DBBPropertyPersistence](), columnMap: [String : String]())
        }
        // add the new content
        var newMap = map?.appendDictionary(contents, indexer: indexer)
        // and update the persistence map dictionary
        if tableObject.hasSubclass == false {
            newMap?.isInitialized = true
        }
        persistenceMap[tableName] = newMap
    }

    @available(*, deprecated, message: "Please use addPersistenceMapping:_:for:indexer: instead")
    /**
     Public method to add the required persistence mapping for a DBBTableObject subclass. This method is deprecated and should be replaced with calls to addPersistenceMapping:_:forTableNamed:indexer:.
     
     - Parameters:
        - contents: A [String : DBBPropertyPersistence] dictionary that maps out the storage required for each property in the subclass.
        - forTableNamed: The name of the subclass/database table that the mapped properties belong to.
        - indexer: An optional DBBIndexer argument that defaults to nil. If you want to index any of the properties being mapped, include them in a DBBIndexer instance and pass that indexer in this argument.
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
     A public accessor for the user's Documents folder.
     
     - Returns: URL to the user's Documents folder.
    */
    public static var documentsFolder: URL {
        guard let folder = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            fatalError("Failed to get Documents folder")
        }
        
        return folder
    }
    
    /**
     A convenience method for getting the user's Application Support folder or a subfolder within Application Support.
     
     - Parameters:
        - using: A string defining a directory hierarchy within the user's Application Support folder.
 
     - Returns: URL to the folder if it is either successfully created or already existing.
    */
    public static func appSupportFolder(using subFolder: String?) -> URL {
        guard let folder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            fatalError("Failed to get Application Support folder")
        }
        
        let appFolder: URL
        if let subFolder = subFolder {
            appFolder = folder.appendingPathComponent(subFolder)
        } else {
            appFolder = folder
        }

        do {
            try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Error creating or getting the application folder: \(error)")
        }
        
        return appFolder
    }

    /**
     A convenience method for getting the count of objects for any DBBTableObject subclass type.
     
     - Parameters:
        - tableName: The name of the DBBTableObject subclass whose count you want to obtain.
 
     - Returns: Int value representing the object count.
    */
    public func countForTable(_ tableName: String) -> Int {
        let query = "SELECT COUNT(*) FROM \(tableName)"
        let executor = DBBDatabaseExecutor(db: self.database)
        let result = executor.runQuery(query)
        if let result = result {
            result.next()
            return Int(result.int(forColumnIndex: 0))
        }
        
        // failed
        return 0
    }
    
/**
 A helper method for checking a version number (which you must assign) for determining whether a database migration is required. The current DB version can be set with the `setCurrentDBVersion` function.
     
     - Parameters:
        currentVersion: A Double value representing the version you want to check against.
        
     - Returns: A (Bool, Double) tuple with values for whether or not the current database version is equal to or greater than the currentVersion value passed in, and the version the database is set to.
*/
    public func hasLatestDBVersion(currentVersion: Double) -> (hasLatest: Bool, version: Double) {
        guard let result = dbCheckResultSet() else {
            return (false, 0)
        }
        if result.next() == false {
            return (false, 0)
        }
        if let dict = result.resultDictionary,
           let lastVersion = dict["MAX(version)"] as? Double {
            return (lastVersion >= currentVersion, lastVersion)
        } else {
            return (false, 0)
        }
    }
    
    /**
     A helper method for setting a version number for the database, which can be useful for determining the need for database migrations in conjunction with the `hasLatestDB` function. If the database already has a version number equal to or higher than the value passed in, it does NOT set the value passed in.
         
         - Parameters:
            currentVersion: A Double value to set the database version to.
    */
    public func setCurrentDBVersion(_ version: Double) {
        if hasLatestDBVersion(currentVersion: version).hasLatest == true {
            return
        }
        
        let count = countForTable("DBVersion")
        let sql: String
        if count > 0 {
            sql = "UPDATE DBVersion SET version = \(version)"
        } else {
            sql = "INSERT INTO DBVersion (version) VALUES (\(version))"
        }
        let executor = DBBDatabaseExecutor(db: database)
        let _ = executor.executeStatements(sql)
    }
    
    private func dbCheckResultSet() -> FMResultSet? {
        let sql = "SELECT MAX(version) FROM DBVersion"
        let executor = DBBDatabaseExecutor(db: database)
        return executor.runQuery(sql)
    }
    
    /**
     A convenience method for sending the VACUUM command to the database.
     */
   public func vacuumDB() {
        let sql = "VACUUM"
        let executor = DBBDatabaseExecutor(db: self.database)
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
        let executor = DBBDatabaseExecutor(db: self.database)
        do {
            try executor.executeUpdate(sql: sql, withArgumentsIn: [])
            os_log("Success dropping index %@: true", log: logger, type: defaultLogType, indexName)
            return true
        } catch {
            os_log("Error dropping index: %@", log: logger, type: defaultLogType, error.localizedDescription)
            return false
        }
    }
    
    public func errorMessage() -> String {
        return database.lastErrorMessage()
    }
    
    // MARK: Internal Methods
    
    func initializePersistenceContents(_ contents: [String : DBBPropertyPersistence], forTableNamed table: String) {
        let map = DBBPersistenceMap([String : DBBPropertyPersistence](), columnMap: [String : String]())
        let newMap = map.appendDictionary(contents)
        persistenceMap[table] = newMap
    }
}

class DBVersion: DBBTableObject {
    private struct Keys {
        static let version = "version"
    }
    
    @objc var version: Double = 0
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        let map: [String : DBBPropertyPersistence] = [Keys.version : DBBPropertyPersistence(type: .float)]
        dbManager.addPersistenceMapping(map, for: self)
    }

}

//
//  DBBDatabaseValidator.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import ExceptionCatcher
import  os.log

struct DBBDatabaseValidator {
    // MARK: - Properties
    private var dbCreationStrings = [String : String]()
    private var executor: DBBDatabaseExecutor
    private let logger = DBBBuilder.logger(withCategory: "DBBDatabaseValidator")
    private let tableClass: DBBTableObject
    private let idNumWithAttributes = "id Integer PRIMARY KEY AUTOINCREMENT"
    var joinMapDict = [String : DBBJoinMap]()

    // MARK: - Internal Methods
    
    init(manager: DBBManager, table: DBBTableObject) {
        self.tableClass = table
        self.executor = DBBDatabaseExecutor(db: manager.database)
        dbCreationStrings = getDatabaseCreationStrings()
    }

    mutating func validateTable() {
        let tableName = tableClass.shortName
        guard let map = tableClass.dbManager.persistenceMap[tableName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, tableName)
            return
        }
        
        let specs = map.map
        let mapKeys = specs.keys
        var joinColumns = [String]()
        for key in mapKeys {
            let needsJoin = requiresJoin(type: specs[key]?.storageType)
            if needsJoin {
                joinColumns.append(key)
            }
        }

        guard let creationString = dbCreationStrings[tableName] else {
            // the file does not contain create string for this table, so insert one
            let sql = tableClass.tableCreationString
            
            do {
                try executor.executeUpdate(sql: sql, withArgumentsIn: [])
                os_log("Created table: %@", log: logger, type: defaultLogType, sql)
                // update the creation strings dictionary
                dbCreationStrings[tableName] = sql
            } catch {
                os_log("Failed to create table: %@ - Error: %@", log: logger, type: defaultLogType, sql, error.localizedDescription)
            }
            
            if joinColumns.count > 0 {
                validateJoinTables(joinColumns, tableName: tableName)
            }
            
            createIndexIfNecessary()
            
            return
        }
        
        // there was a create string for this table, so check to see if it needs to be updated
        let components = creationStringFields(creationString, tableName: tableName)
        var missingComponents = [(propertyName: String, columnName: String)]()
        for key in mapKeys {
            let needsJoin = requiresJoin(type: specs[key]?.storageType)
            var columnName = (needsJoin == true) ? "\(key)\(idExtension)" : key
            if specs[key]?.columnName.isEmpty == false, let colName = specs[key]?.columnName {
                columnName = colName
            }
            if components.contains(columnName) == false && needsJoin == false {
                missingComponents.append((key, columnName))
            }
        }
        
        createIndexIfNecessary()
        
        var alterStatements = [String]()
        let theClass = self.tableClass
        for missing in missingComponents {
            do {
                try ExceptionCatcher.catchException( {
                    // check that property exists on class (without causing an exception at runtime that crashes the app)
                    let _ = theClass.value(forKey: missing.propertyName)
                })
            } catch {
                showMissingProperty(missing.propertyName, className: theClass.shortName, logger: logger)
                continue
            }

            if let type = typeForColumn(missing.propertyName) {
                let alterSQL = "ALTER TABLE \(tableName) ADD COLUMN \(missing.columnName) \(type);"
                alterStatements.append(alterSQL)
            }
        }
        
        if alterStatements.isEmpty == false {
            let joinedStatements = alterStatements.joined()
            let success = executor.executeStatements(joinedStatements)
            if success == false {
                os_log("Execute failed with error message: %@", log: logger, type: defaultLogType, tableClass.dbManager.errorMessage())
            } else {
                os_log("Alter table statements %@ succeeded: %@", log: logger, type: defaultLogType, joinedStatements, (success == true) ? "true" : "false")
            }
        }
                
        if joinColumns.count > 0 {
            validateJoinTables(joinColumns, tableName: tableName)
        }
    }
    
    // MARK: - Private Methods
    
    private mutating func validateJoinTables(_ propertyNames: [String], tableName: String) {
        guard let map = tableClass.dbManager.persistenceMap[tableName]?.map else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, tableName)
            return
        }
        let intString = TypeNames.int
        for propName in propertyNames {
            guard let columnName = tableClass.dbManager.persistenceMap[tableClass.shortName]?.columnNameForProperty(propName) else {
                os_log("Couldn't find column name for %@", log: logger, type: defaultLogType, propName)
                continue
            }
            let column = propName
            var objectType: DBBTableObject.Type? = nil
            if let rawType = map[column] {
                switch rawType.storageType {
                case .dbbObject(let objType):
                    objectType = objType
                case .dbbObjectArray(let objType):
                    objectType = objType
                default:
                    break
                }
                let type: String
                if let _ = objectType {
                    // in a join table, store row IDs for DBBTableObject types
                    type = intString
                } else {
                    type = rawType.storageType.joinType()
                }
                
                let joinTableName = "\(tableName)_\(columnName)"
                let joinMap = DBBJoinMap(parentJoinColumn: "\(tableName)\(idExtension)",
                    joinTableName: joinTableName,
                    joinColumnName: columnName,
                    propertyType: rawType.storageType)
                joinMapDict[columnName] = joinMap
                if let joinSQL = dbCreationStrings[joinTableName] {
                    // check existing string for required columns
                    let columnsDict = [DBBTableObject.Keys.id : idNumWithAttributes,
                                       "\(tableName)\(idExtension)" : "\(tableName)\(idExtension) \(intString)",
                        "\(columnName)" : "\(columnName)\(idExtension) \(type)"]
                    checkJoinTableCreationString(requiredColumns: columnsDict, joinSQL: joinSQL, tableName: tableName, joinTableName: joinTableName)
                } else {
                    // create new join table sql
                    createJoinTableForParent(tableName, column: columnName, type: type)
                }
                
                // generate index for parent ID column -- won't do anything if there is already one
                let indexSQL = "\(createIndexIfNotExists) \(tableName)_\(column)_idx ON \(joinTableName) (\(joinMap.parentJoinColumn))"
                do {
                    try executor.executeUpdate(sql: indexSQL, withArgumentsIn: [])
                    os_log("Successfully created join table index with SQL '%@': true", log: logger, type: defaultLogType, indexSQL)
                } catch {
                    os_log("Error creating join table: %@", log: logger, type: defaultLogType, error.localizedDescription)
                }
            } else {
                // failed to get raw type from map
                os_log("Failed to get type from map for %@", log: logger, type: defaultLogType, column)
                continue
            }
        }
    }
    
    private func checkJoinTableCreationString(requiredColumns: [String : String], joinSQL: String, tableName: String, joinTableName: String) {
        let fields = creationStringFields(joinSQL, tableName: joinTableName)
        var missingFields = [String]()
        for requiredField in requiredColumns {
            if fields.contains(requiredField.key) == false {
                missingFields.append(requiredField.value)
            }
        }
        if missingFields.count > 0 {
            var alterStatements = [String]()
            for missing in missingFields {
                let alterSQL = "ALTER TABLE \(tableName) ADD COLUMN \(missing);"
                alterStatements.append(alterSQL)
            }
            
            let joinedStatements = alterStatements.joined()
            let success = executor.executeStatements(joinedStatements)
            if success == false {
                os_log("Execute failed with error message: %@", log: logger, type: defaultLogType, tableClass.dbManager.errorMessage())
            }
            os_log("Join table alter table statements %@ succeeded: %@", log: logger, type: defaultLogType, joinedStatements, (success == true) ? "true" : "false")
        }
    }
    
    private func createJoinTableForParent(_ tableName: String, column: String, type: String) {
        let createString = "\(createTableIfNotExists) \(tableName)_\(column) (\(idNumWithAttributes), \(tableName)\(idExtension) Integer, \(column) \(type))"

        do {
            try executor.executeUpdate(sql: createString, withArgumentsIn: [])
            os_log("Adding join table with creation string: %@", log: logger, type: defaultLogType, createString)
        } catch  {
            os_log("Update failed with error message: %@", log: logger, type: defaultLogType, error.localizedDescription)
        }
    }
    
    private func requiresJoin(type: DBBStorageType?) -> Bool {
        guard let realType = type else {
            return false
        }
        
        switch realType {
        case .bool, .int, .float, .string, .date:
            return false
        default:
            return true
        }
    }
    
    private func createIndexIfNecessary() {
        let tableName = tableClass.shortName
        guard let map = tableClass.dbManager.persistenceMap[tableName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, tableName)
            return
        }
        if let indexer = map.indexer {
            let createIndexSQL = indexer.createIndicesString(forTable: tableName)
            guard createIndexSQL.isEmpty == false else {
                return
            }
            do {
                try executor.executeUpdate(sql: createIndexSQL, withArgumentsIn: [])
                os_log("Created index for table: %@", log: logger, type: defaultLogType, createIndexSQL)
            } catch {
                os_log("Failed to create index for table: %@ with error: %@", log: logger, type: defaultLogType, createIndexSQL, error.localizedDescription)
            }
        }

    }
    
    private func typeForColumn(_ column: String) -> String? {
        guard let map = tableClass.dbManager.persistenceMap[tableClass.shortName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, tableClass.shortName)
            return nil
        }
        let specs = map.map
        guard let type = specs[column]?.storageType  else {
            os_log("Can't get specs for %@", log: logger, type: defaultLogType, column)
            return nil
        }
        
        return type.columnName()
    }
    
    private func getDatabaseCreationStrings() -> [String : String] {
        // get the "create" strings from the current file
        var output = [String : String]()
        let sql = "SELECT name, sql FROM sqlite_master WHERE type = 'table'"
        
        guard let result = executor.runQuery(sql) else {
            os_log("Database schema query result is nil", log: logger, type: defaultLogType)
            return output
        }
        
        while result.next() == true {
            if let resultDict = result.resultDictionary {
                if let name = resultDict["name"] as? String, let resultSQL = resultDict["sql"] as? String {
                    if name == "sqlite_sequence" {
                        continue
                    }
                    output[name] = resultSQL
                }
            }
        }
        
        return output
    }
    
    private func creationStringFields(_ input: String, tableName: String) -> [String] {
        let create = "CREATE TABLE \(tableName) ("
        let sql = input.replacingOccurrences(of: create, with: "").replacingOccurrences(of: ")", with: "")
        let longFields = sql.components(separatedBy: ", ")
        let fields = longFields.compactMap{ $0.components(separatedBy: " ").first }
        return fields
    }
}

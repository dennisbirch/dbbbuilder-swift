//
//  TableObjectWriting.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/15/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

/*
    Methods for writing object instances to the database file
*/
extension DBBTableObject {
    /**
     Public method for saving a DBTableObject subclass instance to its database file

     - Returns: Boolean value indicating successful execution
    */
    public func saveToDB() -> Bool {
        performPreSaveActions()
        if id == 0 {
            let success = insertIntoDB()
            performPostSaveActions()
            return success
        } else {
            let success = updateInDB()
            performPostSaveActions()
            return success
        }
    }
    
    /**
     Public method you can call from DBTableObject subclasses or from external types to perform any actions required before saving to the database.
    */
    public func performPreSaveActions() {
        // subclasses can override, or external types can call this if pre-save action is required
    }
    
    /**
     Public method you can call from DBTableObject subclasses or from external types to perform any actions required after saving to the database.
     */
    public func performPostSaveActions() {
        // subclasses can override, or external types can call this if post-save action is required
    }
        
    // MARK: - Private Methods
    
    private func insertIntoDB() -> Bool {
        var success = false
        
        createdTime = Date()
        modifiedTime = Date()
        
        // get an object with param (column) names and values to persist
        let instanceComponents = persistenceComponents()
        guard instanceComponents.params.count == instanceComponents.values.count else {
            os_log("Params and values are of unequal sizes", log: logger, type: defaultLogType)
            return false
        }
        
        let placeholders = sqlPlaceholders(count: instanceComponents.params.count)
        let columnNamesString = instanceComponents.params.joined(separator: ", ")
        let statement = "INSERT INTO \(shortName) (\(columnNamesString)) VALUES (\(placeholders))"
        let executor = DBBDatabaseExecutor(manager: dbManager)
        success = executor.executeUpdate(sql: statement, withArgumentsIn: instanceComponents.values)
        if success == false {
            os_log("Insert failed with error message: %@", log: logger, type: defaultLogType, dbManager.errorMessage())
        }
        
        // set the id property for this instance
        id = dbManager.database.lastInsertRowId

        // update any join columns for this class
        if let joinMap = dbManager.joinMapDict[shortName] {
            insertIntoJoinTable(joinDict: joinMap)
        }
        
        return success
    }
    
    private func updateInDB() -> Bool {
        var success = false
        modifiedTime = Date()
        let instanceComponents = persistenceComponents()
        guard instanceComponents.params.count == instanceComponents.values.count else {
            os_log("Params and values are of unequal sizes", log: logger, type: defaultLogType)
            return false
        }
        
        var statement = "UPDATE \(shortName) SET "
        var paramsArray = [String]()
        for param in instanceComponents.params {
            paramsArray.append("\(param) = ?")
        }
        
        statement += paramsArray.joined(separator: ", ") + " WHERE \(Keys.id) = \(id)"
        let executor = DBBDatabaseExecutor(manager: dbManager)
        success = executor.executeUpdate(sql: statement, withArgumentsIn: instanceComponents.values)
        if success == false {
            os_log("Update failed with error message: %@", log: logger, type: defaultLogType, dbManager.errorMessage())
        }
        
        if let joinMap = dbManager.joinMapDict[shortName] {
            insertIntoJoinTable(joinDict: joinMap)
        }
        
        return success
    }
    
    private func insertIntoJoinTable(joinDict: [String : DBBJoinMap]) {
        let joinColumns = joinDict.keys
        for column in joinColumns {
            let joinMap: DBBJoinMap
            // get the mapping for writing this column's join table
            if let unwrappedJoinMap = joinDict[column] {
                joinMap = unwrappedJoinMap
            } else {
                os_log("Failed to find joinMap for column %@", log: logger, type: defaultLogType, column)
                continue
            }

            // delete from joinTable where parentClass_id = parentClassIDNum
            let joinTableName = joinMap.joinTableName
            var sql = "DELETE FROM \(joinMap.joinTableName) WHERE \(joinMap.parentJoinColumn) = \(id)"
            let executor = DBBDatabaseExecutor(manager: dbManager)
            var success = executor.executeStatements(sql)
            if success == false {
                os_log("Error deleting existing join rows: %@", log: logger, type: defaultLogType, dbManager.errorMessage())
            }
            os_log("Success deleting existing join rows with SQL: %@ – %@", log: logger, type: defaultLogType, sql, (success == true) ? "true" : "false")
            
            guard let propertyName = dbManager.persistenceMap[shortName]?.propertyForColumn(named: column) else {
                os_log("Can't get property name for %@", log: logger, type: defaultLogType, column)
                continue
            }
            let valuesToInsert = joinValues(column: propertyName)
            if valuesToInsert.count == 0 {
                continue
            }
            
            for item in valuesToInsert {
                var args: [Any]
                args = [String(id), item]
                sql = "INSERT INTO \(joinTableName) (\(joinMap.parentJoinColumn), \(joinMap.joinColumnName)) VALUES (\("?, ?"))"
                success = executor.executeUpdate(sql: sql, withArgumentsIn: args)
                if success == false {
                    os_log("Insert failed with error message: %@", log: logger, type: defaultLogType, dbManager.errorMessage())
                }
                os_log("Saved join to table with SQL statement(s) %@ – Success: %@ – Values: %@", log: logger, type: defaultLogType, sql, (success == true) ? "true" : "false", args)
            }
        }        
    }    

    private func joinValues(column: String) -> [Any] {
        var itemArray = [Any]()
        let objectInfo = objectTypeForColumn(column)
        let isArray = objectInfo.1
        guard let values = valuesForJoinInsertion(column: column, isArray: isArray) else {
            return itemArray
        }
        
        if let objectArray = values as? [DBBTableObject] {
            let idArray = objectArray.map{ String($0.id) }
            itemArray = idArray
        } else if let dateArray = values as? [Date] {
            itemArray = dateArray.map{ $0.dbb_timeIntervalForDate() }
        } else {
            guard let type = dbManager.persistenceMap[shortName]?.map[column]?.storageType else {
                return itemArray
            }
            if let valuesAsStrings = values as? [String] {
                itemArray = valuesAsStrings
            } else if type.name() == TypeNames.blob {
                if let data = values as? [Data] {
                    itemArray = data
                }
            } else {
                itemArray = values.map{ return String(describing: $0) }
            }
        }
        
        return itemArray
    }
        
    private func valuesForJoinInsertion(column: String, isArray: Bool) -> [Any]? {
        var valuesArray: [Any]? = nil
        
        if isArray {
            let exception = tryBlock { [weak self] in
                guard let objects = self?.value(forKey: column) as? [Any] else {
                    return
                }
                    valuesArray = objects
            }
            
            if exception != nil {
                return nil
            }
        } else {
            let exception = tryBlock { [weak self] in
                guard let object = self?.value(forKey: column) else {
                    return
                }
                valuesArray = [object]
            }
            if exception != nil {
                return nil
            }
        }
        
        return valuesArray
    }
    
    private func persistenceComponents() -> (ParamsAndValues) {
        var params = [String]()
        var values = [String]()
        let instanceVals = instanceValues()
        
        guard let persistenceMap = dbManager.persistenceMap[shortName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, shortName)
            return (params, values)
        }
        
        for (key, property) in persistenceMap.map {
            let type = property.storageType
            // the .name() function returns an empty string for non-atomic types
            if type.name().isEmpty || type.name() == TypeNames.blob {
                continue
            }
            
            if let match = (instanceVals.filter{ $0.label == key }).first {
                let columnName = (property.columnName.isEmpty) ? key : property.columnName
                params.append(columnName)
                
                if type.name() == TypeNames.timeStamp {
                    if match.value == "nil" {
                        values.append("")
                        continue
                    }
                    if let interval = TimeInterval(match.value) {
                        values.append(String(interval))
                    } else {
                        os_log("Failed to convert date to correct format for '%@'. Using current timestamp.", log: logger, type: defaultLogType, key)
                        values.append(String(Date().dbb_timeIntervalForDate()))
                    }
                } else if type.name() == TypeNames.bool {
                    values.append((match.value == "true") ? "1" : "0")
                } else {
                    values.append(String(describing: match.value))
                }
            }
        }
        
        return ((params, values))
    }

    private func instanceValues() -> [(ValueTuple)] {
        let selfMirror = Mirror(reflecting: self)
        var output = [ValueTuple]()
        guard let persistenceMap = dbManager.persistenceMap[shortName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, shortName)
            return [ValueTuple]()
        }
        for case let (label?, value) in selfMirror.children {
            let keyValue = (String(describing: label), String(describing: value))
            if let type = persistenceMap.map[keyValue.0]?.storageType, type.name() == TypeNames.timeStamp, let date = value as? Date {
                let dateString = String(date.dbb_timeIntervalForDate())
                output.append((keyValue.0, dateString))
            } else {
                output.append(keyValue)
            }
        }
        
        // add DBBTableObject properties
        if let createdTime = createdTime {
            output.append((Keys.createdTime, String(describing: createdTime.dbb_timeIntervalForDate())))
        }
        if let modified = modifiedTime {
            output.append((Keys.modifiedTime, String(describing: modified.dbb_timeIntervalForDate())))
        }
        if self.id > 0 {
            output.append((Keys.id, String(describing: self.id)))
        }
        
        return output
    }    

    private func objectTypeForColumn(_ column: String) -> (DBBTableObject.Type?, Bool) {
        var objectType: DBBTableObject.Type? = nil
        guard let persistenceMap = dbManager.persistenceMap[shortName] else {
            os_log("Can't get persistenceMap for %@", log: logger, type: defaultLogType, shortName)
            return (nil, false)
        }

        var isArray = false
        if let rawType = persistenceMap.map[column] {
            switch rawType.storageType {
            case .dbbObject(let objType):
                objectType = objType
            case .dbbObjectArray(let objType):
                objectType = objType
                isArray = true
            case .stringArray, .intArray, .dateArray, .floatArray, .boolArray:
                isArray = true
            default:
                break
            }
        }
        
        return (objectType, isArray)
    }
    
    private func sqlPlaceholders(count: Int) -> String {
        var output = [String]()
        while output.count < count {
            output.append("?")
        }
        
        return output.joined(separator: ", ")
    }

}

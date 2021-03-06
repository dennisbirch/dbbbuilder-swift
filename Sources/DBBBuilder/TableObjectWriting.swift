//
//  TableObjectWriting.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/15/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import FMDB
import ExceptionCatcher
import os.log

private typealias JoinStatementsAndValues = (statement: String, args: [Any]?)

/*
    Methods for writing object instances to the database file
*/
extension DBBTableObject {
    private static var writerLogger: OSLog {
        return DBBBuilder.logger(withCategory: "TableObjectWriting")
    }
    
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
     Public static method for saving an array of DBTableObject subclass instances to the database file
     - Parameters:
         - objects: A homogenous array of DBBTableObject subclass types.
         - dbManager: The DBBManager instance managing the database the object values should be saved to.
     - Returns: Boolean value indicating successful execution
     */
    public static func saveObjects(_ objects: [DBBTableObject], dbManager: DBBManager) -> Bool {
        if objects.isEmpty == true { return true }
       
        let objectType = type(of: objects.first!)
        let filteredObjects = objects.filter({type(of: $0) == objectType})
        if filteredObjects.count < objects.count {        
            os_log("Objects must all be of the same type", log: writerLogger, type: defaultLogType)
            return false
        }
        
        let insertArray = objects.filter{ $0.idNum == 0 }
        let updateArray = objects.filter{ $0.idNum > 0 }
        
        var success = true
        if insertArray.isEmpty == false {
            success = success && insertObjects(insertArray, dbManager: dbManager)
        }
        if updateArray.isEmpty == false {
            success = success && updateObjects(updateArray, dbManager: dbManager)
        }
        
        return success
    }
        
    // MARK: - Private Methods
    
    private static func insertObjects(_ objects: [DBBTableObject], dbManager: DBBManager) -> Bool {
        if objects.isEmpty == true { return true }
        
        let logger = writerLogger
        
        guard let databaseURL = dbManager.database.databaseURL else {
            os_log("Can't get database URL", log: logger, type: defaultLogType)
            return false
        }

        // make sure all DBBTableObject properties have been saved
        saveDBTableObjectProperties(forObjects: objects, dbManager: dbManager)
        
        // now save scalar properties
        var success = true
        var statements = [String]()
        var valueStrings = [[String]]()
        
        for instance in objects {
            instance.createdTime = Date()
            instance.modifiedTime = Date()
            let instanceComponents = instance.persistenceComponents()
            guard instanceComponents.params.count == instanceComponents.values.count else {
                os_log("Params and values are of unequal sizes", log: logger, type: defaultLogType)
                success = false
                continue
            }

            let placeholders = instance.sqlPlaceholders(count: instanceComponents.params.count)
            let columnNamesString = instanceComponents.params.joined(separator: ", ")
            let statement = "INSERT INTO \(instance.shortName) (\(columnNamesString)) VALUES (\(placeholders))"
            statements.append(statement)
            valueStrings.append(instanceComponents.values)
        }
        
        guard statements.count == valueStrings.count && objects.count == valueStrings.count else {
            os_log("Params and values or object arrays are of unequal sizes", log: writerLogger, type: defaultLogType)
            return false
        }

        let queue = FMDatabaseQueue(url: databaseURL)
        queue?.inTransaction({ (database, rollback) in
            for idx in 0..<statements.count {
                let sql = statements[idx]
                let values = valueStrings[idx]
                let instance = objects[idx]

                let executor = DBBDatabaseExecutor(db: database)
                do {
                    try executor.executeUpdate(sql: sql, withArgumentsIn: values)
                    instance.id = database.lastInsertRowId
                    success = true
                } catch  {
                    os_log("Insert failed with error message: %@", log: writerLogger, type: defaultLogType, error.localizedDescription)
                    success = false
                    rollback.pointee = true
                }
            }
        })
        
        success = success && writeJoinColumnsForObjects(objects, databaseURL: databaseURL, dbManager: dbManager)
        
        return success
    }
    
    private static func updateObjects(_ objects: [DBBTableObject], dbManager: DBBManager) -> Bool {
        if objects.isEmpty == true { return true }
        
        guard let databaseURL = dbManager.database.databaseURL else {
            os_log("Can't get database URL", log: writerLogger, type: defaultLogType)
            return false
        }
        
        saveDBTableObjectProperties(forObjects: objects, dbManager: dbManager)
        
        var success = true        
        var statements = [String]()
        var valueStrings = [[String]]()
        
        for instance in objects {
            instance.modifiedTime = Date()
            let instanceComponents = instance.persistenceComponents()
            guard instanceComponents.params.count == instanceComponents.values.count else {
                os_log("Params and values are of unequal sizes", log: writerLogger, type: defaultLogType)
                success = false
                continue
            }
            
            var statement = "UPDATE \(instance.shortName) SET "
            var paramsArray = [String]()
            for param in instanceComponents.params {
                paramsArray.append("\(param) = ?")
            }
            
            statement += paramsArray.joined(separator: ", ") + " WHERE \(Keys.id) = \(instance.idNum);"
            
            statements.append(statement)
            valueStrings.append(instanceComponents.values)
        }
        
        guard statements.count == valueStrings.count else {
            os_log("Params and values are of unequal sizes", log: writerLogger, type: defaultLogType)        
            return false
        }
        
        let queue = FMDatabaseQueue(url: databaseURL)
        queue?.inTransaction({ (database, rollback) in
            for idx in 0..<statements.count {
                let sql = statements[idx]
                let values = valueStrings[idx]
                
                let executor = DBBDatabaseExecutor(db: database)
                do {
                    try executor.executeUpdate(sql: sql, withArgumentsIn: values)
                    success = true
                } catch  {
                    os_log("Update failed with error message: %@", log: writerLogger, type: defaultLogType, error.localizedDescription)
                    success = false
                    rollback.pointee = true
                }
            }
        })
        
        success = success && writeJoinColumnsForObjects(objects, databaseURL: databaseURL, dbManager: dbManager)
        
        return success
    }

    private func insertIntoDB() -> Bool {
        let success = type(of: self).insertObjects([self], dbManager: dbManager)
        return success
    }
    
    private func updateInDB() -> Bool {
        let success = type(of: self).updateObjects([self], dbManager: dbManager)
        return success
    }

    private static func writeJoinColumnsForObjects(_ objects: [DBBTableObject], databaseURL: URL, dbManager: DBBManager) -> Bool {
        var success = true
        
        for instance in objects {
            if let joinMap = dbManager.joinMapDict[instance.shortName] {
                let queue = FMDatabaseQueue(url: databaseURL)
                let statementsAndArgs = instance.statementsAndValuesForJoins(joinDict: joinMap)
                queue?.inTransaction({ (database, rollback) in
                    for statementTuple in statementsAndArgs {
                        let statement = statementTuple.statement
                        if let args = statementTuple.args {
                            database.executeUpdate(statement, withArgumentsIn: args)
                            if database.lastErrorCode() != 0 {
                                rollback.pointee = true
                                success = false
                            }
                        } else {
                            database.executeUpdate(statement, withArgumentsIn: [])
                            if database.lastErrorCode() != 0 {
                                rollback.pointee = true
                                success = false
                            }
                        }
                    }
                })
            }
        }
        
        return success
    }
    
    private static func saveDBTableObjectProperties(forObjects objects: [DBBTableObject], dbManager: DBBManager) {
        let map = dbManager.joinMapDict
        var propertiesToSave = [String]()
        
        // gather up a list of the object's join properties
        if let firstObject = objects.first {
            let className = firstObject.shortName
            if let joinMap = map[className] {
                for (key, _) in joinMap {
                    if let propertyType = joinMap[key]?.propertyType,
                        propertyType.isSavedToJoinTableType() == true,
                        let propertyColumnMap = dbManager.persistenceMap[className]?.propertyColumnMap,
                        let propertyName = propertyColumnMap[key],
                        propertiesToSave.contains(propertyName) == false
                    {
                        propertiesToSave.append(propertyName)
                    }
                }
            }
        }
        
        // now check each object to see if it has unsaved iVars or arrays of DBBTableObjects
        if propertiesToSave.isEmpty == false {
            for object in objects {
                for property in propertiesToSave {
                    if let iVar = object.value(forKey: property) as? DBBTableObject, iVar.id == 0 {
                        let _ = iVar.saveToDB()
                    } else if let iVar = object.value(forKey: property) as? [DBBTableObject] {
                        let _ = saveObjects(iVar, dbManager: dbManager)
                    }
                }
            }
        }
    }

    private func statementsAndValuesForJoins(joinDict: [String : DBBJoinMap]) -> [JoinStatementsAndValues] {
            let joinColumns = joinDict.keys
            
            var statementsAndArgs = [JoinStatementsAndValues]()
        
            for column in joinColumns {
                let joinMap: DBBJoinMap
                // get the mapping for writing this column's join table
                if let unwrappedJoinMap = joinDict[column] {
                    joinMap = unwrappedJoinMap
                } else {
                    os_log("Failed to find joinMap for column %@", log: DBBTableObject.writerLogger, type: defaultLogType, column)
                    continue
                }
                
                // delete from joinTable where parentClass_id = parentClassIDNum
                let joinTableName = joinMap.joinTableName
                var sql = "DELETE FROM \(joinMap.joinTableName) WHERE \(joinMap.parentJoinColumn) = \(id)"
                statementsAndArgs.append((sql, nil))
                
                guard let propertyName = dbManager.persistenceMap[shortName]?.propertyForColumn(named: column) else {
                    os_log("Can't get property name for %@", log: DBBTableObject.writerLogger, type: defaultLogType, column)
                    continue
                }
                let valuesToInsert = joinValues(column: propertyName)
                if valuesToInsert.isEmpty == true { continue }
                
                for item in valuesToInsert {
                    let args: [Any] = [String(id), item]
                    sql = "INSERT INTO \(joinTableName) (\(joinMap.parentJoinColumn), \(joinMap.joinColumnName)) VALUES (?, ?)"
                    statementsAndArgs.append((sql, args))
                }
            }

        return statementsAndArgs
    }
    
    private func joinValues(column: String) -> [Any] {
        var itemArray = [Any]()
        let objectInfo = objectTypeForColumn(column)
        let isArray = objectInfo.1
        guard let values = valuesForJoinInsertion(column: column, isArray: isArray) else {
            return itemArray
        }
        
        if let objectArray = values as? [DBBTableObject] {
            let idArray = objectArray.map{ String($0.idNum) }
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
            do {
                try ExceptionCatcher.catchException({ [weak self] in
                    guard let objects = self?.value(forKey: column) as? [Any] else {
                        return
                    }
                        valuesArray = objects
                })
            } catch {
                return nil
            }
        } else {
            do {
                try ExceptionCatcher.catchException({ [weak self] in
                    guard let object = self?.value(forKey: column) else {
                        return
                    }
                        valuesArray = [object]
                })
            } catch {
                return nil
            }
        }
        
        return valuesArray
    }
    
    private func persistenceComponents() -> (ParamsAndStringValues) {
        var params = [String]()
        var values = [String]()
        let instanceVals = instanceValues()
        
        guard let persistenceMap = dbManager.persistenceMap[shortName] else {
            os_log("Can't get persistenceMap for %@", log: DBBTableObject.writerLogger, type: defaultLogType, shortName)
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
                        os_log("Failed to convert date to correct format for '%@'. Using current timestamp.", log: DBBTableObject.writerLogger, type: defaultLogType, key)
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
            os_log("Can't get persistenceMap for %@", log: DBBTableObject.writerLogger, type: defaultLogType, shortName)
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
        
        // go up the class hierarchy (if exists) to get superclass properties
        var superMirror = selfMirror.superclassMirror
        while superMirror != nil && superMirror?.subjectType != DBBTableObject.self {
            for case let (label?, value) in superMirror!.children {
                let keyValue = (String(describing: label), String(describing: value))
                if let type = persistenceMap.map[keyValue.0]?.storageType, type.name() == TypeNames.timeStamp, let date = value as? Date {
                    let dateString = String(date.dbb_timeIntervalForDate())
                    output.append((keyValue.0, dateString))
                } else {
                    output.append(keyValue)
                }
            }
            
            superMirror = superMirror?.superclassMirror
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
            os_log("Can't get persistenceMap for %@", log: DBBTableObject.writerLogger, type: defaultLogType, shortName)
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

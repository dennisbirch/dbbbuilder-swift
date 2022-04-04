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
            let success = insertIntoDB(fmdbQueue: nil)
            performPostSaveActions()
            return success
        } else {
            let success = updateInDB(fmdbQueue: nil)
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
       
        return saveObjects(objects, dbManager: dbManager, fmdbQueue: nil)
    }
        
    // MARK: - Private Methods
    private static func saveObjects(_ objects: [DBBTableObject], dbManager: DBBManager, fmdbQueue: FMDatabaseQueue? = nil) -> Bool {
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
            success = success && insertObjects(insertArray, dbManager: dbManager, fmdbQueue: fmdbQueue)
        }
        if updateArray.isEmpty == false {
            success = success && updateObjects(updateArray, dbManager: dbManager, fmdbQueue: fmdbQueue)
        }
        
        return success
    }
    
    private static func insertObjects(_ objects: [DBBTableObject], dbManager: DBBManager, fmdbQueue: FMDatabaseQueue?) -> Bool {
        if objects.isEmpty == true { return true }
        
        let logger = writerLogger
        
        guard let databaseURL = dbManager.database.databaseURL else {
            os_log("Can't get database URL", log: logger, type: defaultLogType)
            return false
        }
        
        guard let queue = fmdbQueue ?? FMDatabaseQueue(url: databaseURL) else {
            os_log("Unable to create a database queue")
            return false
        }
        
        // make sure all DBBTableObject properties have been saved
        if let object = objects.first {
            if object.hasDBBObjectTableObjectProperties(className: object.shortName) == true {
                saveDBTableObjectProperties(forObjects: objects, dbManager: dbManager, fmdbQueue: queue)
            }
        }
        
        // now save scalar properties
        var success = true
        var statements = [String]()
        var valueStrings = [[Any]]()

        for instance in objects {
            instance.createdTime = Date()
            instance.modifiedTime = Date()
            let instanceComponents = instance.persistenceComponents()
            guard instanceComponents.params.count == instanceComponents.values.count else {
                os_log("Params and values are of unequal sizes", log: logger, type: defaultLogType)
                success = false
                continue
            }
            
            autoreleasepool {
                let placeholders = instance.sqlPlaceholders(count: instanceComponents.params.count)
                let columnNamesString = instanceComponents.params.joined(separator: ", ")
                let statement = "INSERT INTO \(instance.shortName) (\(columnNamesString)) VALUES (\(placeholders))"
                statements.append(statement)
                valueStrings.append(instanceComponents.values)
            }
        }
        
        guard statements.count == valueStrings.count && objects.count == valueStrings.count else {
            os_log("Params and values or object arrays are of unequal sizes", log: writerLogger, type: defaultLogType)
            return false
        }
        
        queue.inTransaction({ (database, rollback) in
            for idx in 0..<statements.count {
                autoreleasepool {
                    let sql = statements[idx]
                    let values = valueStrings[idx]
                    let instance = objects[idx]
                    
                    let executor = DBBDatabaseExecutor(db: database)
                    do {
                        os_log("Executing Insert statements: %@, arguments: %@", sql, String(describing: values))
                        try executor.executeUpdate(sql: sql, withArgumentsIn: values)
                        instance.id = database.lastInsertRowId
                    } catch  {
                        os_log("Insert failed with error message: %@", log: writerLogger, type: defaultLogType, error.localizedDescription)
                        success = false
                        rollback.pointee = true
                    }
                }
            }
        })

        success = success && writeJoinColumnsForObjects(objects, databaseURL: databaseURL, dbManager: dbManager, isInsert: true, queue: queue)
        return success
    }
    
    private static func updateObjects(_ objects: [DBBTableObject], dbManager: DBBManager, fmdbQueue: FMDatabaseQueue?) -> Bool {
        if objects.isEmpty == true { return true }
        
        guard let databaseURL = dbManager.database.databaseURL else {
            os_log("Can't get database URL", log: writerLogger, type: defaultLogType)
            return false
        }
        
        guard let queue = fmdbQueue ?? FMDatabaseQueue(url: databaseURL) else {
            os_log("Unable to create a database queue")
            return false
        }

        // make sure all DBBTableObject properties have been saved
        if let object = objects.first {
            if object.hasDBBObjectTableObjectProperties(className: object.shortName) == true {
                saveDBTableObjectProperties(forObjects: objects, dbManager: dbManager, fmdbQueue: queue)
            }
        }

        var success = true
        var statements = [String]()
        var valueStrings = [[Any]]()

        for instance in objects {
            instance.modifiedTime = Date()
            let instanceComponents = instance.persistenceComponents()
            guard instanceComponents.params.count == instanceComponents.values.count else {
                os_log("Params and values are of unequal sizes", log: writerLogger, type: defaultLogType)
                success = false
                continue
            }
            
            autoreleasepool {
                var statement = "UPDATE \(instance.shortName) SET "
                let paramsArray = instanceComponents.params.map{ "\($0) = ?" }
                statement += paramsArray.joined(separator: ", ") + " WHERE \(Keys.id) = \(instance.id);"
                statements.append(statement)
                valueStrings.append(instanceComponents.values)
            }
        }
        
        guard statements.count == valueStrings.count else {
            os_log("Params and values are of unequal sizes", log: writerLogger, type: defaultLogType)        
            return false
        }
        
        queue.inTransaction({ (database, rollback) in
            for idx in 0..<statements.count {
                autoreleasepool {
                    let sql = statements[idx]
                    let values = valueStrings[idx]
                    
                    let executor = DBBDatabaseExecutor(db: database)
                    do {
                        os_log("Executing Update statements: %@, arguments: %@", sql, String(describing: values))
                        try executor.executeUpdate(sql: sql, withArgumentsIn: values)
                    } catch  {
                        os_log("Update failed with error message: %@", log: writerLogger, type: defaultLogType, error.localizedDescription)
                        success = false
                        rollback.pointee = true
                    }
                }
            }
        })

        success = success && writeJoinColumnsForObjects(objects, databaseURL: databaseURL, dbManager: dbManager, isInsert: false, queue: queue)
        return success
    }

    private func insertIntoDB(fmdbQueue: FMDatabaseQueue?) -> Bool {
        let success = type(of: self).insertObjects([self], dbManager: dbManager, fmdbQueue: fmdbQueue)
        return success
    }
    
    private func updateInDB(fmdbQueue: FMDatabaseQueue?) -> Bool {
        let success = type(of: self).updateObjects([self], dbManager: dbManager, fmdbQueue: fmdbQueue)
        return success
    }

    private static func writeJoinColumnsForObjects(_ objects: [DBBTableObject], databaseURL: URL, dbManager: DBBManager, isInsert: Bool, queue: FMDatabaseQueue?) -> Bool {
        var success = true
        
        for instance in objects {
            autoreleasepool {
                if let joinMap = dbManager.joinMapDict[instance.shortName] {
                    let statementsAndArgs = instance.statementsAndValuesForJoins(joinDict: joinMap, isInsert: isInsert)
                    queue?.inTransaction({ (database, rollback) in
                        for statementTuple in statementsAndArgs {
                            let statement = statementTuple.statement
                            if let args = statementTuple.args {
                                os_log("Executing join table statements: %@, arguments: %@", statement, String(describing: args))
                                database.executeUpdate(statement, withArgumentsIn: args)
                                if database.lastErrorCode() != 0 {
                                    os_log("Executing join table statements failed; rolling back")
                                    rollback.pointee = true
                                    success = false
                                }
                            } else {
                                os_log("Executing join table statements: %@", statement)
                                database.executeUpdate(statement, withArgumentsIn: [])
                                if database.lastErrorCode() != 0 {
                                    os_log("Executing join table statements failed; rolling back")
                                    rollback.pointee = true
                                    success = false
                                }
                            }
                        }
                    })
                }
            }
        }
        
        return success
    }
    
    private static func saveDBTableObjectProperties(forObjects objects: [DBBTableObject], dbManager: DBBManager, fmdbQueue: FMDatabaseQueue) {
        let map = dbManager.joinMapDict
        var propertiesToSave = [String]()
        
        // gather up a list of the object's join properties
        if let firstObject = objects.first {
            let className = firstObject.shortName
            if let joinMap = map[className] {
                for (key, _) in joinMap {
                    if let propertyType = joinMap[key]?.propertyType,
                       propertyType.isDBBTableObjectType() == true,
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
                autoreleasepool {
                    for property in propertiesToSave {
                        if let iVar = object.value(forKey: property) as? [DBBTableObject],
                            iVar.isEmpty == false {
                            let _ = saveObjects(iVar, dbManager: dbManager, fmdbQueue: fmdbQueue)
                        } else if let iVar = object.value(forKey: property) as? DBBTableObject, iVar.id == 0 {
                            let _ = iVar.saveToDB()
                        }
                    }
                }
            }
        }
    }
    
    private func hasDBBObjectTableObjectProperties(className: String) -> Bool {
        let map = dbManager.joinMapDict
        
        if let joinMap = map[className] {
            for (key, _) in joinMap {
                if let propertyType = joinMap[key]?.propertyType,
                   propertyType.isDBBTableObjectType() {
                    return true
                }
            }
        }
        
        return false
    }

    private func statementsAndValuesForJoins(joinDict: [String : DBBJoinMap], isInsert: Bool) -> [JoinStatementsAndValues] {
        let joinColumns = joinDict.keys
        
        var statementsAndArgs: [JoinStatementsAndValues] = []
        
        for column in joinColumns {
            let joinMap: DBBJoinMap
            // get the mapping for writing this column's join table
            if let unwrappedJoinMap = joinDict[column] {
                joinMap = unwrappedJoinMap
            } else {
                os_log("Failed to find joinMap for column %@", log: DBBTableObject.writerLogger, type: defaultLogType, column)
                continue
            }
            
            var sql: String
            let joinTableName = joinMap.joinTableName

            if isInsert == false {
                // delete from joinTable where parentClass_id = parentClassID
                sql = "DELETE FROM \(joinMap.joinTableName) WHERE \(joinMap.parentJoinColumn) = \(id)"
                statementsAndArgs.append((sql, nil))
            }
            
            guard let propertyName = dbManager.persistenceMap[shortName]?.propertyForColumn(named: column) else {
                os_log("Can't get persistence map's property name for %@", log: DBBTableObject.writerLogger, type: defaultLogType, column)
                continue
            }
            let valuesToInsert = joinValues(column: propertyName)
            if valuesToInsert.isEmpty == true { continue }
            
            let inserts: [JoinStatementsAndValues] = valuesToInsert.map{("INSERT INTO \(joinTableName) (\(joinMap.parentJoinColumn), \(joinMap.joinColumnName)) VALUES (?, ?)", [String(id), $0])}
            statementsAndArgs.append(contentsOf: inserts)
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
        var values = [Any]()
        let instanceVals = instanceValues()
        
        guard let persistenceMap = dbManager.persistenceMap[shortName] else {
            os_log("Can't get persistenceMap for %@", log: DBBTableObject.writerLogger, type: defaultLogType, shortName)
            return (params, values)
        }
        
        for (key, property) in persistenceMap.map {
            let type = property.storageType
            // the .name() function returns an empty string for non-atomic types
            let typeName = type.name()
            if typeName.isEmpty || typeName == TypeNames.blob {
                continue
            }
            
            let columnName = (property.columnName.isEmpty) ? key : property.columnName
            if let match = (instanceVals.filter{ $0.label == key }).first {
                if typeName == TypeNames.timeStamp {
                    if let matchValue = match.value as? String,
                       matchValue == "nil" {
                        values.append("")
                        continue
                    }
                    if let date = match.value as? String, let interval = TimeInterval(date) {
                        values.append(String(interval))
                    } else {
                        os_log("Failed to convert date to correct format for '%@'. Using current timestamp.", log: DBBTableObject.writerLogger, type: defaultLogType, key)
                        values.append(String(Date().dbb_timeIntervalForDate()))
                    }
                } else if typeName == TypeNames.bool, let boolString = match.value as? String {
                    values.append((boolString == "true") ? "1" : "0")
                } else {
                    values.append(String(describing: match.value))
                }
            } else {
                continue
            }
            
            params.append(columnName)
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
            let keyValue = (label, value)
            if let type = persistenceMap.map[keyValue.0]?.storageType {
                let typeName = type.name()
                if typeName == TypeNames.timeStamp, let date = value as? Date {
                    let dateString = String(date.dbb_timeIntervalForDate())
                    output.append((keyValue.0, dateString))
                } else if typeName == TypeNames.bool, let boolValue = value as? Bool {
                    output.append((keyValue.0, String(boolValue)))
                } else if typeName == TypeNames.float, let floatValue = value as? Double {
                    output.append((keyValue.0, String(floatValue)))
                } else if typeName == TypeNames.float, let floatValue = value as? Float {
                    output.append((keyValue.0, String(floatValue)))
                } else if typeName == TypeNames.int, let intValue = value as? Int {
                    output.append((keyValue.0, String(intValue)))
                } else if let unwrappedString = value as? String {
                    output.append((keyValue.0, unwrappedString))
                } else {
                    continue
                }
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

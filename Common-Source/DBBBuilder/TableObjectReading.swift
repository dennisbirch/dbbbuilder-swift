//
//  TableObjectReading.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/15/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import FMDB
import os.log

/**
 Methods for retrieving DBBTableObject instances (or metadata) from the database.
 */

extension DBBTableObject {
    
    // MARK: - Retrieving From Database
    /**
     A static method to retrieve all instances of a DBBTableObject subclass from the database.
     
     - Parameters:
         - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.

     - Returns: An array of DBBTableObject instances. In most cases you will need to cast them as the subclass type to be useful. e.g.:
     ```
    guard let projects = Project.allInstances(manager: manager) as? [Project] else {
        return
    }
     ```
     */
    public static func allInstances(manager: DBBManager) -> [DBBTableObject] {
        let allIDs = self.allInstanceIDs(manager: manager)
        return instancesWithIDNumbers(allIDs, manager: manager)
    }
    
    /**
     A static method that lets you retrieve instances of a DBBTableObject subclass based on options that allow you to filter return values and affect sort order
     
     - Parameters:
        - options: A DBBQueryOptions instance that specifies the desired filtering and sorting.
        - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.
        - sparsePopulation: A Bool value indicating whether the instances should be constructed with only their basic (id, creationTime and modifiedTime) properties populated. The default is false, but can be set to true for better performance.
     
     - Returns: An array of the DBBtableObject subclass that meet your criteria, or nil if there was an error. In most cases you will need to cast the returned array as the subclass type to be useful. e.g.:
     ```
     guard let projects = instancesWithOptions(options, manager: manager) as? [Project] else {
        return
     }
     ```
     - SeeAlso:
        DBBQueryOptions struct
    */
    public static func instancesWithOptions(_ options: DBBQueryOptions,
                                            manager: DBBManager,
                                            sparsePopulation: Bool = false) -> [DBBTableObject]? {
        let sql = sqlString(withOptions: options, manager: manager)
        let executor = DBBDatabaseExecutor(manager: manager)
        guard let results = executor.runQuery(sql) else {
            os_log("Fetch failed with error: %@ for SQL: %@", log: DBBBuilder.logger(withCategory: "TableObjectReading"), type: defaultLogType, manager.errorMessage(), sql)
            return nil
        }
        
        var foundInstances = [DBBTableObject]()
        while results.next() {
            if let resultsDict = results.resultDictionary,
                let obj = instanceFromResultsDictionary(resultsDict, manager: manager,
                                                        sparsePopulation: sparsePopulation,
                                                        options: options) {
                foundInstances.append(obj)
            }
        }
        
        return foundInstances
    }
    
    /**
     A static method that lets you retrieve instances of a DBBTableObject subclass asynchrounously, based on options that allow you to filter return values and affect sort order. This method uses the FMDBDatabaseQueue class to execute a fetch asynchronously and "return" results in a completion closure.
     
     - Parameters:
         - options: A DBBQueryOptions instance that specifies the desired filtering and sorting.
         - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.
        - sparsePopulation: A Bool value indicating whether the instances should be constructed with only their basic (id, creationTime and modifiedTime) properties populated. The default is false, but can be set to true for better performance.
         - completion: A closure with the signature `([DBBTableObject], NSError?) -> Void`

            - [DBBTableObject]: An array of the DBBTableObject subclass you call this method on
            - NSError: An NSError instance if there was an error, or nil
     
     - SeeAlso:
     DBBQueryOptions struct
     */
    public static func getInstancesFromQueue(withOptions options: DBBQueryOptions,
                                             manager: DBBManager,
                                             sparsePopulation: Bool = false,
                                             completion: ([DBBTableObject], NSError?) -> Void) {
        let sql = sqlString(withOptions: options, manager: manager)
        let queue = FMDatabaseQueue(url: manager.database.databaseURL)
        queue?.inDatabase({ (db) in
            do {
                let results = try db.executeQuery(sql, values: nil)
                var foundInstances = [DBBTableObject]()
                while results.next() {
                    if let resultsDict = results.resultDictionary,
                        let obj = instanceFromResultsDictionary(resultsDict, manager: manager,
                                                                sparsePopulation: sparsePopulation,
                                                                options: options) {
                        foundInstances.append(obj)
                    }
                }
                
                db.closeOpenResultSets()
                completion(foundInstances, nil)
            } catch {
                completion([DBBTableObject](), error as NSError)
                os_log("Error accessing records: %@", log: DBBBuilder.logger(withCategory: "TableObjectReading"), type: defaultLogType, error.localizedDescription)
            }
        })
    }
    
    /**
     A static method that lets you retrieve an instance of a DBTableObject subclass for the `idNum` value you pass in.
     
     - Parameters:
         - id: An Int64 for the instance with the idNum value you want to retrieve.
         - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.
        - sparsePopulation: A Bool value indicating whether the instance should be constructed with only its basic (id, creationTime and modifiedTime) properties populated. The default is false, but can be set to true for better performance.

     - Returns: A single instance of a DBBTableObject subclass that matches the ID number passed in, or nil if there was an error or no match. In most cases you will need to cast the returned instance as the subclass type to be useful. e.g.:
     ```
     guard let projects = Project.instanceWithIDNumber(id, manager: manager) as? Project else {
         return
     }
     ```
     */
    public static func instanceWithIDNumber(_ id: Int64, manager: DBBManager, sparsePopulation: Bool = false) -> DBBTableObject? {
        let instance = self.init(dbManager: manager)
        let table = instance.shortName
        let sql = "SELECT * FROM \(table) WHERE \(Keys.id) = \(id)"
        let executor = DBBDatabaseExecutor(manager: manager)
        guard let result = executor.runQuery(sql) else {
            os_log("Fetch from database failed")
            return nil
        }
        let _ = result.next()
        guard let resultDict = result.resultDictionary else {
            os_log("Results dictionary object is nil")
            return nil
        }
        
        return instanceFromResultsDictionary(resultDict,
                                             manager: manager,
                                             sparsePopulation: sparsePopulation,
                                             options: nil)
    }
    
    /**
     A static method that lets you retrieve an array of instances of a DBTableObject subclass for the `idNum` values you pass in.
     
     - Parameters:
         - ids: An array of Int64s for the instances with the idNum values you want to retrieve.
         - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.
     
     - Returns: An array of instances of a DBBTableObject subclass that match the ID numbers passed in, or nil if there was an error. In most cases you will need to cast the returned instances as the subclass type to be useful. e.g.:
     ```
     guard let projects = Project.instanceWithIDNumbers(idArray, manager: manager) as? [Project] else {
        return
     }
     ```
     */
    public static func instancesWithIDNumbers(_ ids: [Int64], manager: DBBManager) -> [DBBTableObject] {
        var instances = [DBBTableObject]()
        for id in ids {
            if let instance = self.instanceWithIDNumber(id, manager: manager) {
                instances.append(instance)
            }
        }
        
        return instances
    }

    /**
     A static method that lets you retrieve all instance IDs for a DBTableObject subclass.
     
     - Parameters:
         - manager: A DBBManager instance that owns the FMDB instance/SQLite file being read from.
     
     - Returns: An array of Int64's representing the `idNum` value for all instances of the DBBTableObject subclass you call this method on.
     */
    public static func allInstanceIDs(manager: DBBManager) -> [Int64] {
        var idsArray = [Int64]()
        let tableName = self.init(dbManager: manager).shortName
        
        let sql = "SELECT \(Keys.id) FROM \(tableName)"
        let executor = DBBDatabaseExecutor(manager: manager)
        guard let result = executor.runQuery(sql) else {
            os_log("Error getting results with query %@: %@", log: DBBBuilder.logger(withCategory: "DBTableObject"), type: defaultLogType,  sql, manager.errorMessage())
            return idsArray
        }
        
        while result.next() {
            idsArray.append(Int64(result.int(forColumn: DBBTableObject.Keys.id)))
        }
        
        return idsArray
    }
    
    // MARK: - Private Methods
    
    private static func instanceFromResultsDictionary(_ resultDict: [AnyHashable : Any],
                                                      manager: DBBManager,
                                                      sparsePopulation: Bool,
                                                      options: DBBQueryOptions?) -> DBBTableObject? {
        let instance = self.init(dbManager: manager)
        
        for (key, value) in resultDict {
            if let _ = value as? NSNull {
                continue
            }
            
            guard let keyString = key as? String,
                let persistenceMap = instance.dbManager.persistenceMap[instance.shortName],
                let propertyName = persistenceMap.propertyForColumn(named: keyString),
                let propertyPersistence = persistenceMap.map[propertyName] else {
                os_log("Cannot get column type in instanceFromResultsDictionary", log: DBBBuilder.logger(withCategory: "TableObjectReading"), type: defaultLogType)
                return nil
            }
            
            let type = propertyPersistence.storageType
            if type.name() == TypeNames.timeStamp {
                if let dateInterval = value as? TimeInterval {
                    let valueDate = Date.dbb_dateFromTimeInterval(dateInterval)
                    instance.setValue(valueDate, forKey: String(describing: propertyName))
                }
            } else if type.name() == TypeNames.bool, let boolValue = value as? Int {
                instance.setValue(boolValue == 1, forKey: String(describing: propertyName))
            } else {
                instance.setValue(value, forKey: String(describing: propertyName))
            }
        }
        
        if let joinMap = manager.joinMapDict[instance.shortName] {
            instance.readJoinColumns(joinMapDict: joinMap,
                                     instance: instance,
                                     manager: manager,
                                     sparsePopulation: sparsePopulation,
                                     options: options)
        }
        
        return instance
    }
        
    private static func sqlString(withOptions options: DBBQueryOptions, manager: DBBManager) -> String {
        let instance = self.init(dbManager: manager)
        let tableName = instance.shortName
        var sql = (options.distinct) ? "SELECT DISTINCT " : "SELECT "
        let columnString: String
        if var columnNames = options.propertyNames {
            if let joinMap = manager.joinMapDict[tableName] {
                columnNames = columnNames.filter{ joinMap.keys.contains($0) == false }
            }
            
            if columnNames.contains(Keys.id) == false {
                columnNames.append(Keys.id)
            }
            if columnNames.contains(Keys.createdTime) == false {
                columnNames.append(Keys.createdTime)
            }
            if columnNames.contains(Keys.modifiedTime) == false {
                columnNames.append(Keys.modifiedTime)
            }
            columnString = columnNames.joined(separator: ",")
        } else {
            columnString = "*"
        }
        sql += columnString + " FROM \(tableName)"
        
        sql += conditionsString(options: options, tableName: tableName)
        
        if let sorting = options.sorting, sorting.isEmpty == false {
            sql += " ORDER BY \(orderString(orderArray: sorting))"
        }
        
        return sql
    }
    
    private func readJoinColumns(joinMapDict: [String : DBBJoinMap],
                                 instance: DBBTableObject,
                                 manager: DBBManager,
                                 sparsePopulation: Bool,
                                 options: DBBQueryOptions?) {
        let columns: [String]
        if sparsePopulation == true, let joinOptions = options?.joinPropertiesToPopulate, joinOptions.isEmpty == false {
            columns = joinOptions
        } else {
            if let properties = options?.propertyNames {
                columns = Array(joinMapDict.keys).filter{ properties.contains($0) }
            } else {
                columns = Array(joinMapDict.keys)
            }
        }
        let executor = DBBDatabaseExecutor(manager: manager)
        for column in columns {
            guard let propertyName = instance.dbManager.persistenceMap[instance.shortName]?.propertyForColumn(named: column) else {
                os_log("Can't get property name for %@", log: logger, type: defaultLogType, column)
                continue
            }
            
            if let joinMap = joinMapDict[column] {
                let sql = "SELECT \(joinMap.joinColumnName) FROM \(joinMap.joinTableName) WHERE \(joinMap.parentJoinColumn) = \(instance.id);"
                if let results = executor.runQuery(sql) {
                    os_log("Executed query for join table content: %@", sql)
                    instance.setValues(fromResult: results,
                                       forColumn: column,
                                       propertyName: propertyName,
                                       type: joinMap.propertyType,
                                       joinMap: joinMap,
                                       manager: manager)
                } else {
                    os_log("ResultSet is nil with query: %@", log: logger, type: defaultLogType, sql)
                    if manager.database.lastErrorCode() != 0 {
                        os_log("Database error message: %@", log: logger, type: defaultLogType, manager.errorMessage())
                    }
                }                
            } else {
                os_log("Cannot retrieve values for %@ because its joinMap is nil", log: logger, type: defaultLogType, column)
                continue
            }            
        }
    }
    
    private func setValues(fromResult resultSet: FMResultSet,
                           forColumn column: String,
                           propertyName: String,
                           type: DBBStorageType,
                           joinMap: DBBJoinMap,
                           manager: DBBManager) {
        let isArray: Bool
        let requiresDBBObject: Bool
        var objectType: DBBTableObject.Type? = nil
        switch type {
        case .stringArray, .intArray, .boolArray, .dateArray, .floatArray :
            isArray = true
            requiresDBBObject = false
        case .dbbObjectArray(let objType):
            isArray = true
            requiresDBBObject = true
            objectType = objType
        case .dbbObject(let objType):
            isArray = false
            requiresDBBObject = true
            objectType = objType
        default:
            isArray = false
            requiresDBBObject = false
        }
        
        if requiresDBBObject {
            guard let type = objectType else {
                os_log("Type of object is nil", log: logger, type: defaultLogType)
                return
            }
            setDBBObjectValue(objectType: type, joinMap: joinMap, manager: manager, isArray: isArray)
            return
        }
        
        var valueArray = [Any]()
        
        while resultSet.next() {
            if let resultDict = resultSet.resultDictionary, let value = resultDict[column] {
                if let _ = value as? NSNull {
                    continue
                }
                if column == Keys.createdTime || column == Keys.modifiedTime {
                    if let dateInterval = value as? TimeInterval {
                        let valueDate = Date.dbb_dateFromTimeInterval(dateInterval)
                        valueArray.append(valueDate)
                    }
                } else {
                    if type.joinType() == TypeNames.bool, let boolValue = value as? Int {
                        valueArray.append(boolValue == 1)
                    } else if type.joinType() == TypeNames.timeStamp, let floatValue = value as? Double {
                        valueArray.append(Date.dbb_dateFromTimeInterval(floatValue))
                    } else {
                        valueArray.append(value)
                    }
                }
            }
        }
        
        if valueArray.isEmpty {
            return
        }
        
        if isArray {
            self.setValue(valueArray, forKey: propertyName)
        } else {
            if let firstValue = valueArray.first {
                self.setValue(firstValue, forKey: propertyName)
            }
        }
    }
    
    private func setDBBObjectValue(objectType: DBBTableObject.Type, joinMap: DBBJoinMap, manager: DBBManager, isArray: Bool) {
        let tableName = (objectType == type(of: self)) ? joinMap.joinTableName.replacingOccurrences(of: idExtension, with: "") : joinMap.joinTableName
        let sql = "SELECT \(joinMap.joinColumnName) FROM \(tableName) WHERE \(joinMap.parentJoinColumn) = \(self.id)"

        let executor = DBBDatabaseExecutor(manager: manager)
        guard let result = executor.runQuery(sql) else {
            os_log("Result of query is nil: %@", log: logger, type: defaultLogType, sql)
            return
        }
        var valuesArray = [Int32]()
        while result.next() {
            valuesArray.append(result.int(forColumn: joinMap.joinColumnName))
        }
        
        if valuesArray.isEmpty {
            return
        }
        
        let propertyName = joinMap.joinColumnName.replacingOccurrences(of: idExtension, with: "")
        
        if isArray {
            var objects = [DBBTableObject]()
            for idNum in valuesArray {
                if let instance = objectType.instanceWithIDNumber(Int64(idNum), manager: manager) {
                    objects.append(instance)
                }
            }
            
            self.setValue(objects, forKey: propertyName)
        } else {
            guard let instanceID = valuesArray.first else {
                os_log("Couldn't get first id from object array", log: logger, type: defaultLogType)
                return
            }
            
            let propertyObect = objectType.instanceWithIDNumber(Int64(instanceID), manager: manager)
            self.setValue(propertyObect, forKey: propertyName)
        }
    }

    private static func conditionsString(options: DBBQueryOptions, tableName: String) -> String {
        var conditionsArray = [String]()
        var conjunction = ""
        if let conditions = options.conditions, conditions.isEmpty == false {
            conditionsArray.append(contentsOf: conditions.map{ return $0 })
            conjunction = " AND "
            var conjunctionIndex = -1
            for index in 0..<conditionsArray.count {
                let condition = conditionsArray[index]
                if condition.lowercased().trimmingCharacters(in: CharacterSet.whitespaces) == "or" {
                    conjunction = " OR "
                    conjunctionIndex = index
                } else if condition.lowercased().trimmingCharacters(in: CharacterSet.whitespaces) == "and" {
                    conjunctionIndex = index
                }
            }
            
            if conjunctionIndex >= 0 {
                conditionsArray.remove(at: conjunctionIndex)
            }
        }
        
        if options.distinct {
            conditionsArray.append(buildDistinctClauseWorkaround(options: options, tableName: tableName))
        }
        
        if conditionsArray.isEmpty {
            return ""
        }
        
        let conditionsString = " WHERE (\(conditionsArray.joined(separator: conjunction)))"
        return conditionsString
    }
    
    private static func buildDistinctClauseWorkaround(options: DBBQueryOptions, tableName: String) -> String {
        guard let columns = options.propertyNames?.joined(separator: ", ") else {
            return ""
        }
        let distinctClause = "\(Keys.id) IN (SELECT MAX(\(Keys.id)) FROM \(tableName) GROUP BY \(columns))"
        return distinctClause
    }
    
    private static func orderString(orderArray: [String]) -> String {
        var orderCopy = orderArray
        var order = " \(ColumnSorting.ascending) "
        var orderIndex = -1
        for index in 0..<orderArray.count {
            let item = orderArray[index]
            if item.uppercased().trimmingCharacters(in: CharacterSet.whitespaces) == ColumnSorting.descending {
                order = " \(ColumnSorting.descending) "
                orderIndex = index
            } else if item.uppercased().trimmingCharacters(in: CharacterSet.whitespaces) == ColumnSorting.ascending {
                orderIndex = index
            }
        }
        
        if orderIndex >= 0 {
            orderCopy.remove(at: orderIndex)
        }
        
        let orderColumns = orderCopy.joined(separator: ",")
        return orderColumns + " \(order)"
    }

}

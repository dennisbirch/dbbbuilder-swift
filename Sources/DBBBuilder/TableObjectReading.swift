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
     
     - __Note:__ You can query the database for objects that match the ID(s) of a property that is of type DBBTableObject. To do so, include a condition in the _options_ argument with the _name_ of the property and the ID number it should match. For example, if you have a Meeting DBBTableObject that has as a 'project' property, which is a Project DBBTableObject subclass, you could include a condition like "project = \(projectID)" (where 'projectID' is an Integer value). If the property is represented as an array of DBBTableObjects, you should use "IN" syntax: "project IN (\(idsArray))" (where 'idsArray' is an array of Integer values).
    */
        
    public static func instancesWithOptions(_ options: DBBQueryOptions,
                                            manager: DBBManager,
                                            sparsePopulation: Bool = false) -> [DBBTableObject]? {
        
        var joinMaps = [String : DBBJoinMap]()

        // see if we're extracting values based on matching a DBBTableObject equality condition
        let typeObj = self.init(dbManager: manager)
        if let properties = manager.joinMapDict[typeObj.shortName],
            let conditions = options.conditions {
            for condition in conditions {
                if  let spaceIndex = condition.firstIndex(of: " ")  {
                    let propertyToMatch = String(condition[condition.startIndex..<spaceIndex]).trimmingCharacters(in: CharacterSet.whitespaces)
                    if let map = properties[propertyToMatch] {
                        joinMaps[propertyToMatch] = map
                    }
                }
            }
        }
        
        let sql = sqlString(withOptions: options, manager: manager, joinMaps: joinMaps)
        os_log("Executing SQL: %@", sql)
        let executor = DBBDatabaseExecutor(db: manager.database)
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
        os_log("Executing SQL: %@", sql)
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
        let options = DBBQueryOptions.options(withConditions: ["\(Keys.id) = \(id)"])
        guard let object = instancesWithOptions(options, manager: manager)?.first else {
            os_log("Fetch from database failed")
            return nil
        }

        return object
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
        let instance = self.init(dbManager: manager)
        let idNumString = ids.map{ String($0) }
        let sql = "SELECT * FROM \(instance.shortName) WHERE \(Keys.id) IN (\(idNumString.joined(separator: ",")))"
        let executor = DBBDatabaseExecutor(db: manager.database)
        guard let results = executor.runQuery(sql) else {
            os_log("Fetch failed with error: %@ for SQL: %@", log: DBBBuilder.logger(withCategory: "TableObjectReading"), type: defaultLogType, manager.errorMessage(), sql)
            return instances
        }
        
        while results.next() {
            if let resultsDict = results.resultDictionary,
                let obj = instanceFromResultsDictionary(resultsDict, manager: manager,
                                                        sparsePopulation: false,
                                                        options: nil) {
                instances.append(obj)
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
        let executor = DBBDatabaseExecutor(db: manager.database)
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
            
            guard let persistenceMap = instance.dbManager.persistenceMap[instance.shortName],
                let keyString = key as? String else {
                    os_log("Cannot get key as string in instanceFromResultsDictionary", log: DBBBuilder.logger(withCategory: "TableObjectReading"), type: defaultLogType)
                    return nil
            }
            
            if let propertyName = persistenceMap.propertyForColumn(named: keyString),
                let propertyPersistence = persistenceMap.map[propertyName] {
                let type = propertyPersistence.storageType
                if type.name() == TypeNames.timeStamp {
                    if let dateInterval = value as? TimeInterval {
                        let valueDate = Date.dbb_dateFromTimeInterval(dateInterval)
                        instance.setValue(valueDate, forKey: String(describing: propertyName))
                    }
                } else if type.name() == TypeNames.bool {
                    if let boolValue = value as? Int {
                        instance.setValue(boolValue == 1, forKey: String(describing: propertyName))
                    } else {
                        instance.setValue(false, forKey: String(describing: propertyName))
                    }
                } else {
                    instance.setValue(value, forKey: String(describing: propertyName))
                }
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

    private static func sqlString(withOptions options: DBBQueryOptions, manager: DBBManager, joinMaps: [String : DBBJoinMap] = [String : DBBJoinMap]()) -> String {
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
        
        sql += conditionsString(options: options, tableName: tableName, joinMaps: joinMaps)
        
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
        let executor = DBBDatabaseExecutor(db: manager.database)
        for column in columns {
            guard let propertyName = instance.dbManager.persistenceMap[instance.shortName]?.propertyForColumn(named: column) else {
                os_log("Can't get property name for %@", log: logger, type: defaultLogType, column)
                continue
            }
            
            if let joinMap = joinMapDict[column] {
                let sql = "SELECT \(joinMap.joinColumnName) FROM \(joinMap.joinTableName) WHERE \(joinMap.parentJoinColumn) = \(instance.idNum);"
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
            setDBBObjectValue(objectType: type, joinMap: joinMap, resultSet: resultSet, manager: manager, isArray: isArray)
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
    
    private func setDBBObjectValue(objectType: DBBTableObject.Type, joinMap: DBBJoinMap, resultSet: FMResultSet, manager: DBBManager, isArray: Bool) {
        var valuesArray = [Int32]()
        while resultSet.next() {
            valuesArray.append(resultSet.int(forColumn: joinMap.joinColumnName))
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

    private static func conditionsString(options: DBBQueryOptions, tableName: String, joinMaps: [String : DBBJoinMap]) -> String {
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
        
        if joinMaps.count > 0 {
            var whereItems = [String]()
            for condition in conditionsArray {
                if  let spaceIndex = condition.firstIndex(of: " ")  {
                    let propertyToMatch = String(condition[condition.startIndex..<spaceIndex]).trimmingCharacters(in: CharacterSet.whitespaces)
                    if let map = joinMaps[propertyToMatch] {
                        whereItems.append("\(DBBTableObject.Keys.id) IN (SELECT \(map.parentJoinColumn) FROM \(map.joinTableName) WHERE \(condition))")
                    } else {
                        whereItems.append(condition)
                    }
                }
            }
            
            return " WHERE \(whereItems.joined(separator: " AND "))"
        } else {
            let conditionsString = " WHERE (\(conditionsArray.joined(separator: conjunction)))"
            return conditionsString
        }
    }
    
    private static func buildDistinctClauseWorkaround(options: DBBQueryOptions, tableName: String) -> String {
        var columnString = ""
        if let columns = options.propertyNames {
            columnString = columns.joined(separator: ", ")
        }
        var distinctClause = "\(Keys.id) IN (SELECT MAX(\(Keys.id)) FROM \(tableName)"
        if columnString.isEmpty == false {
            distinctClause += " GROUP BY \(columnString)"
        }
        
        distinctClause += ")"
        
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

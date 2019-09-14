//
//  DBBStorageType.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation

/**
 An enum of types that DBBBuilder supports persisting to SQLite files. These types are used in the DBBPersistenceMap struct, and are used by the DBBTableObject class and others to create, read and write SQLite tables.
 
 Types supported:
    - bool
    - int
    - float
    - string
    - date
 
 There is also support for arrays of each of the above types.
 
 In addition, you can persist single instances and arrays of DBBTableObject classes. For a DBBTableObject subclass, use the `dbbObject` case. For an array of DBBTableObjects, use the `dbbObjectArray` case. Both of these cases require defining the specific type. For example:
 ```
 let gameType: DBBStorageType = .dbbObject(objectType: Game.self)
 ```
 
 - Note: Due to limitations in Swift, Decimal property types are not supported. If you need to deal with Decimal values, a possible workaround is to persist raw values as Strings and add conversion methods for any math required.
 */
public enum DBBStorageType {
    case bool
    case int
    case float
    case string
    case date
    case dbbObject(objectType: DBBTableObject.Type)
    case boolArray
    case intArray
    case floatArray
    case stringArray
    case dateArray
    case dbbObjectArray(objectType: DBBTableObject.Type)
    case binary
    
    func name() -> String {
        switch self {
        case .bool:
            return TypeNames.bool
        case .int:
            return TypeNames.int
        case .float:
            return TypeNames.float
        case .string:
            return TypeNames.text
        case .date:
            return TypeNames.timeStamp
        case .binary:
            return TypeNames.blob
            
        default:
            return ""
        }
    }
    
    func joinType() -> String {
        switch self {
        case .boolArray:
            return DBBStorageType.bool.name()
        case .intArray:
            return DBBStorageType.int.name()
        case .floatArray:
            return DBBStorageType.float.name()
        case .stringArray:
            return DBBStorageType.string.name()
        case .dateArray:
            return DBBStorageType.date.name()
        case .dbbObject, .dbbObjectArray:
            return TypeNames.dbbObj
        default:
            return self.name()
        }
    }
    
    func columnName() -> String {
        switch self {
        case .date, .dateArray:
            return TypeNames.float
        default:
            return self.name()
        }
    }
    
    func isSavedToJoinTableType() -> Bool {
        switch self {
        case .boolArray, .intArray, .floatArray, .dateArray, .stringArray, .binary:
            return true
        case .bool, .int, .float, .date, .string:
            return false
        default:
            return false
        }
    }
}

struct TypeNames {
    static let bool = "Boolean"
    static let int = "Integer"
    static let float = "Real"
    static let text = "Text"
    static let timeStamp = "DateTimeStamp"
    static let blob = "BLOB"
    static let dbbObj = "ObjectReference"
}


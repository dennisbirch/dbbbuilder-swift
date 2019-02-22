//
//  DBBGenerationStorageType.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation

public enum DBBGenerationStorageType {
    case bool
    case int
    case float
    case string
    case date
    case boolArray
    case intArray
    case floatArray
    case stringArray
    case dateArray
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
            return DBBGenerationStorageType.bool.name()
        case .intArray:
            return DBBGenerationStorageType.int.name()
        case .floatArray:
            return DBBGenerationStorageType.float.name()
        case .stringArray:
            return DBBGenerationStorageType.string.name()
        case .dateArray:
            return DBBGenerationStorageType.date.name()
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
}

struct TypeNames {
    static let bool = ".bool"
    static let int = ".int"
    static let float = ".float"
    static let text = ".string"
    static let timeStamp = ".timeStamp"
    static let blob = ".blob"
}


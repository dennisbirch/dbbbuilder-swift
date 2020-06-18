//
//  DBBTableBuilder.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation
import ExceptionCatcher
import os.log

class DBBTableBuilder {
    private var tableObject: DBBTableObject
    private let logger = DBBBuilder.logger(withCategory: "DBBTableBuilder")
    
    init(table: DBBTableObject) {
        self.tableObject = table
    }
    
    func createTableString() -> String {
        let tableName = tableObject.shortName
        guard tableName.isEmpty == false else {
            return ""
        }
        var itemsArray = [String]()
        guard let persistenceMap = tableObject.dbManager.persistenceMap[tableName] else {
            os_log("Can't get persistenceMap for %@", tableName)
            return ""
        }
        for item in persistenceMap.map {
            let propertyName = item.key
            let columnName = (item.value.columnName.isEmpty == true) ? propertyName : item.value.columnName
            do {
                try ExceptionCatcher.catchException( {
                    // check that property exists on class (without causing an exception at runtime that crashes the app)
                    let _ = self.tableObject.value(forKey: propertyName)
                })
            } catch {
                os_log("\n\n***********\nEncountered an exception checking the property '%@' from the persistence map for table/class '%@'. \nThis is probably because it is 1) not included in the DBBTableObject class, 2) is not marked as @objc, or 3) its type does not match the DBBStorageType specified in its class's persistenceMap.\n***********\n", log: logger, type: defaultLogType, propertyName, tableName)
                continue
            }
            
            let type = item.value.storageType
            var isBinary = false
            switch type {
            case .binary:
                isBinary = true
            default:
                break
            }
            let typeValue = type.columnName()
            if propertyName == DBBTableObject.Keys.id {
                itemsArray.append("\(columnName) \(typeValue) PRIMARY KEY AUTOINCREMENT")
            } else if type.name().isEmpty == true || isBinary {
                // will be looked up from join table
                continue
            } else {
                itemsArray.append("\(columnName) \(typeValue)\(columnAttributesString(column: propertyName))")
            }
        }
        
        return "\(createTableIfNotExists) \(tableName) (" + itemsArray.joined(separator: ", ") + ")"
    }
    
    private func columnAttributesString(column: String) -> String {
        var attributesString = ""
        var itemsArray = [String]()
        if let attributesDict = tableObject.attributesDictionary, let attributes = attributesDict[column] {
            itemsArray.append(attributes)
        
            if itemsArray.isEmpty == false {
                attributesString = " " + itemsArray.joined(separator: " ")
            }
        }
        
        return attributesString
    }
}

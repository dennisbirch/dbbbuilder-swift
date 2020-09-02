//
//  DBBPersistenceMap.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

/**
    A struct used by DBBTableObject to define database tables matching subclass type properties.DBBTableObject subclasses must add entries mapping their properties to their persistence table.
*/
public struct DBBPersistenceMap {
    // map property names to storage type
    var map = [String : DBBPropertyPersistence]()
    // map property names to column names
    var propertyColumnMap = [String : String]()
    var indexer: DBBIndexer?
    public var isInitialized = false
    private let logger = DBBBuilder.logger(withCategory: "DBBPersistenceMap")

    init(_ dict: [String : DBBPropertyPersistence], columnMap: [String : String], indexer: DBBIndexer? = nil) {
        self.map = dict
        self.indexer = indexer
        self.propertyColumnMap = columnMap
    }
    
    /**
     A method for adding mapping information to a persistenceMap instance, used internally by DBBBuilder.
    */
    func appendDictionary(_ dictToAppend: [String : DBBPropertyPersistence], indexer: DBBIndexer? = nil) -> DBBPersistenceMap {
        var newMap = self.map
        var columnMap = self.propertyColumnMap
        for item in dictToAppend {
            let key = item.key
            if let _ = map[key] {
                os_log("Already have an item with the key: %@", log: logger, type: defaultLogType, key)
                continue
            }
            
            newMap[key] = item.value
            if item.value.columnName.isEmpty == false {
                columnMap[item.value.columnName] = key
            } else {
                columnMap[key] = item.key
            }
        }
        
        return DBBPersistenceMap(newMap, columnMap: columnMap, indexer: indexer)
    }
    
    // MARK: - Helpers
    
    func propertyForColumn(named column: String) -> String? {
        return propertyColumnMap[column]
    }
    
    func columnNameForProperty(_ property: String) -> String? {
        return propertyColumnMap.first(where: {$0.value == property})?.key
    }
}

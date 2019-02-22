//
//  DBBIndexer.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/31/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

/**
 A struct you can use to specify database table columns that should be indexed. This is an optional component of the `DBBPersistenceMap` type.
 */
public struct DBBIndexer {
    var columns = [String]()
    var isUnique = false
    private var logger = DBBBuilder.logger(withCategory: "DBBIndexer")
    
    /**
     Default initializer.
     
     - Parameters:
        - columnsToIndex: A string array that includes the name of each column (property) you want the table to be indexed on.
         - unique: An optional Bool value indicating whether you want SQLite to create an index with the Unique attribute. The default is False.
     */
    public init(columnsToIndex: [String], unique: Bool = false) {
        columns = columnsToIndex
        isUnique = unique
    }
    
    // used internally to get the index creation string
    func createIndicesString(forTable table: String) -> String {
        guard columns.count > 0 else {
            os_log("Indexer with no columns cannot generate an index statement", log: logger, type: defaultLogType)
            return ""
        }
        // ensure column names are not empty
        var allColumns = [String]()
        var indexName = "\(table)_"
        for column in columns {
            if column.isEmpty == false {
                allColumns.append(column)
                indexName += column
            }
        }
        
        guard allColumns.isEmpty == false else {
            os_log("Indexer cannot generate an index statement with empty column names", log: logger, type: defaultLogType)
            return ""
        }
        
        if isUnique {
            return "\(createUniqueIndexIfNotExists) \(indexName) ON \(table) (\(allColumns.joined(separator: ",")))"
        } else {
            return "\(createIndexIfNotExists) \(indexName) ON \(table) (\(allColumns.joined(separator: ",")))"
        }
    }

}

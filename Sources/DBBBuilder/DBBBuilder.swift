//
//  DBBBuilder.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/12/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

// MARK: - Publicly Accessible Constants

// Column attributes
public struct ColumnAttribute {
    public static let notNull = "NOT NULL"
    public static let unique = "UNIQUE"
}

// Column sorting
public struct ColumnSorting {
    public static let ascending = "ASC"
    public static let descending = "DESC"
}




// MARK: - String Constants For Internal Use

// Table & index create/write/read
let createTableIfNotExists = "CREATE TABLE IF NOT EXISTS"
let createIndexIfNotExists = "CREATE INDEX IF NOT EXISTS"
let createUniqueIndexIfNotExists = "CREATE UNIQUE INDEX IF NOT EXISTS"
let idExtension = "_ID"

// MARK: - Logging Support

// Change the log type for all framework os_log calls by editing this value
let defaultLogType: OSLogType = .debug


struct DBBBuilder {
    static func logger(withCategory category: String) -> OSLog {
        let logger = OSLog(subsystem: "com.DBBBuilder.logger", category: category)
        return logger
    }
}

func showMissingProperty(_ property: String, className: String, logger: OSLog) {
    os_log("\n\n***********\nEncountered an exception checking the property '%@' from the persistence map for table/class '%@'. \nThis is probably because it is 1) not included in the DBBTableObject class, 2) is not marked as @objc, or 3) its type does not match the DBBStorageType specified in %@'s persistenceMap, or its key in the persistence map ('%@') does not match the property name — remember to check for case-sensitivity.\n***********\n", log: logger, type: defaultLogType, property, className, className, property)
}


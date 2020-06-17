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


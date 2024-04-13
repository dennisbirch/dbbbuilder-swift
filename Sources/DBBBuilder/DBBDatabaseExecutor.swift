//
//  DBBDatabaseExecutor.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/10/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import FMDB
import os.log

struct DBBDatabaseExecutor {
    private var database: FMDatabase
    private let logger = DBBBuilder.logger(withCategory: "DBBDatabaseExecutor")
    private var fmDBQueue: FMDatabaseQueue?

    init(db: FMDatabase) {
        self.database = db
        fmDBQueue = FMDatabaseQueue(url: db.databaseURL)
    }
    
    func runQuery(_ query: String, arguments: [String]) -> FMResultSet? {
        guard query.isEmpty == false else {
            os_log("Query string is empty", log: logger, type: defaultLogType)
            return nil
        }
        
        do {
            let result = try database.executeQuery(query, values: arguments)
            logError()
            return result
        } catch {
            os_log("Error executing query: %@", log: logger, type: defaultLogType, error.localizedDescription)
            return nil
        }
    }
    
    func runQuery(_ query: String) -> FMResultSet? {
        return runQuery(query, arguments: [])
    }
    
    func runQueryOnQueue(_ query: String, arguments: [String], _ completion: (FMResultSet?) -> Void) {
        guard query.isEmpty == false else {
            os_log("Query string is empty", log: logger, type: defaultLogType)
            completion(nil)
            return
        }
        
        fmDBQueue?.inDatabase({ db in
            do {
                let result = try db.executeQuery(query, values: arguments)
                logError()
                completion(result)
            } catch {
                os_log("Error executing query", log: logger, type: defaultLogType)
                completion(nil)
            }
        })
    }

    func runQueryOnQueue(_ query: String, _ completion: (FMResultSet?) -> Void) {
        runQueryOnQueue(query, arguments: []) { result in
            completion(result)
        }
    }

    func executeUpdate(sql: String, withArgumentsIn arguments: [Any]) throws {
        do {
            try database.executeUpdate(sql, values: arguments)
            logError()
        } catch {
            throw error
        }
    }
    
    func executeStatements(_ sql: String) -> Bool {
        let success = database.executeStatements(sql)
        logError()
        return success
    }

    private func logError() {
        let error = database.lastError() as NSError
        if error.code != 0 {
            os_log("Execution error: %@", log: logger, type: defaultLogType, error.localizedDescription)
        }
    }
}

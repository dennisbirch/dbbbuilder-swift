//
//  DBBJoinMap.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/14/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation

struct DBBJoinMap {
    var parentJoinColumn: String
    var joinTableName: String
    var joinColumnName: String
    var propertyType: DBBStorageType
    
    init(parentJoinColumn: String, joinTableName: String, joinColumnName: String, propertyType: DBBStorageType) {
        self.parentJoinColumn = parentJoinColumn
        self.joinTableName = joinTableName
        self.joinColumnName = joinColumnName
        self.propertyType = propertyType
    }
}


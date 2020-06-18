//
//  DBBPropertyPersistence.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 2/13/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import os.log

public struct DBBPropertyPersistence {
    public var columnName = ""
    public var storageType: DBBStorageType
    
    public init(type: DBBStorageType, columnName: String) {
        self.storageType = type
        // use the propertyName for the columnName by default
        self.columnName = columnName
    }
    
    public init(type: DBBStorageType) {
        self.storageType = type
    }

    
}

//
//  Company.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/9/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import DBBBuilder

final class Company: DBBTableObject {
    private struct Keys {
        static let name = "name"
        static let address = "address"
        static let city = "city"
        static let state = "state"
        static let zip = "zip"
        static let blurbData = "blurbData"
    }
    
    @objc var name: String = ""
    @objc var address: String = ""
    @objc var city: String = ""
    @objc var state: String = ""
    @objc var zip: String = ""
    @objc var blurbData: Data?
    
    private let companyMap: [String : DBBPropertyPersistence] = [Keys.name : DBBPropertyPersistence(type: .string),
                                                                 Keys.address : DBBPropertyPersistence(type: .string),
                                                                 Keys.city : DBBPropertyPersistence(type: .string),
                                                                 Keys.state : DBBPropertyPersistence(type: .string),
                                                                 Keys.zip : DBBPropertyPersistence(type: .string),
                                                                 Keys.blurbData: DBBPropertyPersistence(type: .binary)]
    
    init(name: String, city: String, state: String, dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        self.name = name
        self.city = city
        self.state = state
        
        configurePersistenceMap()
    }
    
    required init(dbManager: DBBManager) {
        // for DBBManager initialization
        super.init(dbManager: dbManager)
        
        configurePersistenceMap()
    }
    
    private func configurePersistenceMap() {
        dbManager.addPersistenceMapContents(companyMap, forTableNamed: shortName)
    }
}

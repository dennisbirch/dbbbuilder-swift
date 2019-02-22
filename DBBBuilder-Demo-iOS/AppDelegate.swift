//
//  AppDelegate.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 12/5/14.
//  Copyright (c) 2014 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var dbManager: DBBManager {
        get {
            let urlArray = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let folderURL: URL
            if let folders = urlArray.first as URL? {
                folderURL = folders
            } else {
                folderURL = Bundle.main.bundleURL
            }
            let fileURL = folderURL.appendingPathComponent("DBBBuilderDemo.sqlite")
            let dbManager = DBBManager(databaseURL: fileURL)
            dbManager.addTableClasses([Company.self, Meeting.self, Person.self, Project.self])
            return dbManager
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
	


}


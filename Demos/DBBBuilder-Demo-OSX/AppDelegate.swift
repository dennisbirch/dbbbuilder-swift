//
//  AppDelegate.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var dbManager: DBBManager?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupDBManager()
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let wc = storyboard.instantiateController(withIdentifier: ContainerViewController.windowControllerIdentifier) as? NSWindowController else {
            os_log("Can't get reference to initial window controller")
            return
        }
        
        guard let container = wc.contentViewController as? ContainerViewController else {
            os_log("Can't get reference to the container view controller")
            return
        }

        container.dbManager = dbManager
        wc.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    func setupDBManager() {
//        guard let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            return
//        }
//
//        let fileURL = documentsFolder.appendingPathComponent("DBBBuilderDemo.sqlite")
//        dbManager = DBBManager(databaseURL: fileURL)
//        dbManager?.addTableClasses([Person.self, Company.self, Project.self, Meeting.self])
    }
}


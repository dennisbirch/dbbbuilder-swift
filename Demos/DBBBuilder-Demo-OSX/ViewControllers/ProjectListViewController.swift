//
//  ProjectListViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/23/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

protocol ProjectListDelegate {
    func closingProjectList(_ viewController: ProjectListViewController)
}

class ProjectListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
DBBManagerConsumer {
    static let viewControllerIdentifier = "ProjectListViewController"
    static var editWindClose = false

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var addProjectButton: NSButton!
    @IBOutlet private weak var statisticsButton: NSButton!
    @IBOutlet private weak var infoLabel: NSTextField!
    @IBOutlet private weak var saveButton: NSButton!

    var dbManager: DBBManager? {
        didSet {
            if dbManager != nil {
                loadProjects()
                if tableView != nil {
                    tableView.deselectAll(nil)
                }
            }
        }
    }
    var projects = [Project]()
    var parentProject: Project?
    var delegate: ProjectListDelegate?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadProjects()
        title = "Project List"
        saveButton.isHidden = true
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        loadProjects()
        tableView.deselectAll(nil)
        
        if parentProject != nil {
            addProjectButton.isHidden = true
            statisticsButton.isHidden = true
            saveButton.isHidden = false
            if let proj = parentProject {
                infoLabel.stringValue = "Assign a  sub-project for '\(proj.name)'."
            } else {
                infoLabel.stringValue = "Assign a sub-project"
            }
        } else {
            infoLabel.stringValue = "Select a project to edit or tap the + button to add a new project."
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()

        if ProjectListViewController.editWindClose == false {
            ProjectListViewController.editWindClose = true
            ProjectListViewController.editWindClose = false
        }
        
        delegate = nil
    }
    
    
    func setupForSubprojectSelection(withParentProject parentProject: Project, delegate: ProjectListDelegate) {
        self.parentProject = parentProject
        self.delegate = delegate
        loadProjects()
    }
    
    // MARK: - Private Helper Methods

    private func loadProjects() {
        guard let manager = dbManager else {
            os_log("DB Manager is nil")
            return
        }

        var options = DBBQueryOptions.queryOptionsWithAscendingSortForColumns(["startDate"])
        options.propertyNames = ["name"]
        guard let projects = Project.instancesWithOptions(options, manager: manager) as? [Project] else {
            return
        }
        
        if let parent = parentProject {
            let otherProjects = projects.filter{ $0.idNum != parent.idNum }
            self.projects = otherProjects
        } else {
            self.projects = projects
        }

        if tableView == nil {
            return
        }
        
        tableView.reloadData()
    }
    
    private func showEditProjectView(projectToEdit: Project?) {
        guard let editViewController = storyboard?.instantiateController(withIdentifier: EditProjectViewController.viewControllerIdentifier) as? EditProjectViewController else {
            return
        }
        guard let manager = dbManager else {
            os_log("DB Manager is nil")
            return
        }
        
        guard let id = projectToEdit?.idNum, let project = Project.instanceWithIDNumber(id, manager: manager) as? Project else {
            os_log("Can't load project to edit")
            return
        }
        
        editViewController.project = project
        
        if let parentVC = parent as? ContainerViewController {
            parentVC.showChildViewController(editViewController)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func plusButtonPushed(sender: Any) {
        showEditProjectView(projectToEdit: nil)
    }
    
    @IBAction func saveSubproject(_ sender: NSButton) {
        delegate?.closingProjectList(self)
        view.window?.close()
    }

    // MARK: - TableViewDataSource/Delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.projects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let project = projects[row]
        return project.name
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        saveButton.isEnabled = false
        let row = tableView.selectedRow
        if row < 0 {
            return
        }
        
        if saveButton.isHidden == false {
            saveButton.isEnabled = true
        }
        let project = projects[row]
        
        if let parent = parentProject {
            parent.subProject = project
            parent.makeDirty(true)
            let success = parent.saveToDB()
            if success == false {
                os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
            }
            self.parentProject = nil
        } else {
            if row + 1 > projects.count {
                os_log("Can't get project for row %@", row)
                return
            }
            
            showEditProjectView(projectToEdit: project)
        }
    }
    
    //  MARK: - Direct Database Query Example
    
    @IBAction func statisticsButtonPushed(_ sender: NSButton) {
        // this is a very simple example of sending queries directly to your database manager, just to show that you can
        let queries: [String] = ["SELECT COUNT(*) As Projects FROM Project",
                                 "SELECT COUNT(*) As Meetings FROM Meeting",
                                 "SELECT COUNT(*) As Participants FROM Person"]
        var countsDict = [String : Int]()
        
        guard let mgr = dbManager else {
            return
        }
        
        let db = mgr.database
        
        for query:String in queries {
            if let results = db.executeQuery(query, withArgumentsIn: []), let table = results.columnName(for: 0), results.next() {
                let count = Int(results.int(forColumnIndex: 0))
                countsDict[table] = count
            }
            
        }
        var message = "Current counts for your Projects database:\n\n"
        for (table, count) in countsDict {
            message += "\(table): \(count)\n"
        }

        let alert = NSAlert()
        alert.messageText = "Database Statistics"
        alert.informativeText = message
        alert.runModal()
    }

}

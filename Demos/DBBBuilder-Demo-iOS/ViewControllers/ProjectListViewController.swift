//
//  ProjectListViewController.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 6/23/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder
import os.log

let kAddProjectSegueIdentifier = "AddProjectSegue"

class ProjectListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statsButton: UIButton!
    var projects: [Project] = []
    var parentProject: Project? = nil
    var dbManager: DBBManager?
	
	let kEditProjectSegue = "EditProjectSegue"
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonType: UIBarButtonItem.SystemItem = UIBarButtonItem.SystemItem.add
        let addSelector = #selector(addProject)
        let addButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: buttonType, target: self, action:addSelector)
        navigationItem.rightBarButtonItem = addButton
        title = "Projects"
        
        dbManager = AppDelegate.dbManager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadProjects()
        
        // setup for selecting subproject
        if parentProject != nil {
            tableView.contentInset = UIEdgeInsets.init(top: 44.0, left: 0, bottom: 0, right: 0)
            statsButton.isHidden = true
            addCancelButton()
            var temp = [Project]()
			
			// don't include parent project in subproject options
            let _ = projects.map({ (proj: Project) -> Bool in
                if proj.idNum != parentProject?.idNum
                {
                    temp.append(proj)
                }
                return true
            })

            projects = temp
            tableView.reloadData()
        }
    }
    
    // MARK: - Private
    
    func loadProjects() {
        guard let mgr = dbManager else {
            return
        }

        // select all meetings, sorted by start date
        var queryOptions = DBBQueryOptions.queryOptionsWithAscendingSortForColumns(["startDate"])
        queryOptions.propertyNames = ["name"]
        if let result = Project.instancesWithOptions(queryOptions, manager: mgr) as? [Project] {
            projects = result
            tableView.reloadData()
        }
    }
    
    func addCancelButton() {
        let cancelButton = UIButton(type: UIButton.ButtonType.system)
        cancelButton.frame = CGRect(x: 12.0, y: 12.0, width: 60.0, height: 32.0)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(handleCancelTap), for: .touchUpInside)
        view.addSubview(cancelButton)
    }
    
    @objc func addProject(sender: AnyObject) {
        performSegue(withIdentifier: kAddProjectSegueIdentifier, sender: self)
    }
    
    @objc func handleCancelTap() {
        parentProject?.subProject = nil
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "Cell";
        let aCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        
        let project: Project = projects[indexPath.row];
        aCell.textLabel?.text = project.name;
        
        if let _: Project = parentProject {
            aCell.accessoryType = .none
        }

        return aCell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if parentProject != nil {
            let project:Project = projects[indexPath.row]
            parentProject?.subProject = project
            parentProject?.isDirty = true
            dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? EditProjectViewController {
            vc.title = "Add Project"
            vc.dbManager = dbManager
            
            if segue.identifier == kEditProjectSegue {
                if let path = tableView.indexPathForSelectedRow {
                    let project = projects[path.row] as Project
                    let id = project.idNum
                    guard let manager = dbManager, let projectToEdit = Project.instanceWithIDNumber(id, manager: manager) as? Project else {
                        os_log("Can't get project to edit")
                        return
                    }
                    vc.title = "Edit Project"
                    vc.project = projectToEdit
                }
            }
        }
    }    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == kEditProjectSegue {
            return parentProject == nil
        }
        
        return true
    }

    // MARK: - Actions
    
    @IBAction func statisticsButtonTapped(sender: AnyObject) {
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
            if let results = db.executeQuery(query, withArgumentsIn: []), let table = (results.columnName(for: 0)), results.next() {
                let count = Int(results.int(forColumnIndex: 0))
                countsDict[table] = count
            }
            
        }
        var message = "Current counts for your Projects database:\n\n"
        for (table, count) in countsDict {
            message += "\(table): \(count)\n"
        }
        
        UIAlertController.showDefaultAlertWithTitle("Statistics", message: message, inViewController: self)
    }
        
}


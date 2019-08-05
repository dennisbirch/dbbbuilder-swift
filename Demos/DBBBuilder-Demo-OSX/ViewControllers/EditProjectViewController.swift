//
//  EditProjectViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/23/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

class EditProjectViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, DBBManagerConsumer, ProjectListDelegate {
    static let viewControllerIdentifier = "EditProjectViewController"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var nameTextField: NSTextField!
    @IBOutlet private weak var codeTextField: NSTextField!
    @IBOutlet private weak var startDatePicker: NSDatePicker!
    @IBOutlet private weak var endDatePicker: NSDatePicker!
    @IBOutlet private weak var meetingsTable: NSTableView!
    @IBOutlet private weak var budgetField: NSTextField!
    @IBOutlet private weak var tagsField: NSTextField!
    @IBOutlet private weak var subprojectLabel: NSTextField!
    @IBOutlet private weak var setButton: NSButton!
    @IBOutlet private weak var saveButton: NSButton!

    // MARK: - Properties
    
    private var activeTextField: NSTextField!

    var project: Project?
    var dbManager: DBBManager?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChangeNotification), name: NSControl.textDidChangeNotification, object: nil)
        
        nameTextField.delegate = self
        codeTextField.delegate = self
        budgetField.delegate = self
        tagsField.delegate = self
        
        if let project = self.project, project.idNum > 0 {
            nameTextField.stringValue = project.name
            codeTextField.stringValue = project.code
            if let startDate = project.startDate {
                startDatePicker.dateValue = startDate
            }
            if let endDate = project.endDate {
                endDatePicker.dateValue = endDate
            }
            
            loadTags()
            
            budgetField.stringValue = formatCurrency(project.budget)

            meetingsTable.reloadData()
            title = "Edit Project"
        } else {
            guard let dbManager = dbManager else {
                os_log("DB Manager is nil")
                return
            }
            
            self.project = Project(dbManager: dbManager)
            if let project = self.project {
                project.startDate = Date()
                project.endDate = Date()
                if let startDate = project.startDate {
                    startDatePicker.dateValue = startDate
                    
                }
                if let endDate = project.endDate {
                    endDatePicker.dateValue = endDate
                }
                title = "Add Project"
            }
        }
        
        project?.makeDirty(false)
        enableSaveButton()
        updateSetSubprojectButtonTitle()

        let firstColumn = meetingsTable.tableColumns[0]
        firstColumn.width = meetingsTable.frame.width
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        var subprojectName = ""
        if let subproject = self.project?.subProject {
            subprojectName = subproject.name
        }
        
        subprojectLabel.stringValue = subprojectName
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        nameTextField.becomeFirstResponder()
        nameTextField.selectText(nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        activeTextField?.resignFirstResponder()
    }
    
    private func updateSetSubprojectButtonTitle() {
        let btnTitle = (project?.subProject == nil) ? "Set" : "Clear"
        setButton.title = btnTitle
    }

    // MARK: - Actions
    
    @IBAction func didSetStartDate(_ sender: NSDatePicker) {
        project?.startDate = sender.dateValue
        project?.makeDirty(true)
        enableSaveButton()
    }

    @IBAction func didSetEndDate(_ sender: NSDatePicker) {
        project?.endDate = sender.dateValue
        project?.makeDirty(true)
        enableSaveButton()
    }

    @IBAction func clickedSetClearButton(_ sender: NSButton) {
        if sender.title == "Set" {
            if let project = self.project {
                 presentIndependentProjectList(parentProject: project)
            }
        } else {
            // "Clear"
            project?.subProject = nil
            subprojectLabel.stringValue = ""
            project?.makeDirty(true)
            enableSaveButton()
        }
        
        project?.makeDirty(true)
        updateSetSubprojectButtonTitle()
    }

    @IBAction func saveChanges(_ sender: NSButton) {
        let success = project?.saveToDB()
        os_log("Saved changes to project: %@", (success == true) ? "true" : "false")
        if success == false {
            os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
        }
        project?.makeDirty(success == false)
        
        showProjectList()
    }

    @IBAction func cancelChanges(_ sender: NSButton) {
        showProjectList()
    }

    @IBAction func addMeetingsButtonClicked(_ sender: Any) {
        guard let meetingListVC = storyboard?.instantiateController(withIdentifier: MeetingListViewController.viewControllerIdentifier) as? MeetingListViewController else {
            os_log("Can't hydrate MeetingListViewController from storyboard")
            return
        }

        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent is nil or is not a ContainerViewController")
            return
        }
        
        meetingListVC.project = project
        parentVC.showChildViewController(meetingListVC)
    }

    // MARK: - TableView DataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return project?.meetings.count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let meeting = project?.meetings[row] {
            return meeting.purpose
        }
        
        return nil
    }

    // MARK: - Private Helpers
    
    private func showProjectList() {
        guard let projectListVC = storyboard?.instantiateController(withIdentifier: ProjectListViewController.viewControllerIdentifier) as? ProjectListViewController else {
            os_log("Unable to instantiate project list view controller")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent view controller is nil or is not a ContainerViewController")
            return
        }
        
        parentVC.showChildViewController(projectListVC)
    }
    
    private func presentIndependentProjectList(parentProject: Project) {
        guard let projectListVC = storyboard?.instantiateController(withIdentifier: ProjectListViewController.viewControllerIdentifier) as? ProjectListViewController else {
            os_log("Unable to instantiate project list view controller")
            return
        }
        
        guard let dbManager = self.dbManager else {
            os_log("DBManager is nil")
            return
        }

        projectListVC.setupForSubprojectSelection(withParentProject: parentProject, delegate: self, dbManager: dbManager)
        let winController = NSWindowController(window: NSWindow(contentViewController: projectListVC))
        winController.showWindow(nil)
    }
    
    private func enableSaveButton() {
        var enable = false
        if let startDate = project?.startDate, let endDate = project?.endDate {
            enable = project?.name.isEmpty == false && project?.code.isEmpty == false && endDate >= startDate
        }
        saveButton.isEnabled = enable && project?.isDirty == true
    }

    private func loadTags() {
        if let tags = project?.tags, tags.isEmpty == false {
            let temp = tags.map{ $0.replacingOccurrences(of: " ", with: "") }.filter{ $0.isEmpty == false }
            tagsField.stringValue = temp.joined(separator: " ")
        }
    }

    private func formatCurrency(_ currencyAmount: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        guard let stringValue = formatter.string(from: NSNumber(value: currencyAmount)) else {
            return ""
        }
        
        return stringValue
    }

    // MARK: - Notifications and Delegate Methods
    
    @objc func handleTextChangeNotification(notification: Notification) {
        if activeTextField == nameTextField {
            project?.name = nameTextField.stringValue
        } else if activeTextField == codeTextField {
            project?.code = codeTextField.stringValue
        } else if activeTextField == budgetField {
            let text = budgetField.stringValue.replacingOccurrences(of: "$", with: "")
            if let budget = Float(text) {
                project?.budget = budget
            }
        }
        
        project?.makeDirty(true)
        enableSaveButton()
    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        if let field = control as? NSTextField {
            activeTextField = field
        }
        return true
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if control == budgetField, let budget = project?.budget {
            control.stringValue = formatCurrency(budget)
        } else if control == tagsField {
            let text = control.stringValue.replacingOccurrences(of: ",", with: " ")
            project?.tags = text.components(separatedBy: " ")
        }
        
        return true
    }
    
    func closingProjectList(_ viewController: ProjectListViewController) {
        guard let subproject = project?.subProject else {
            os_log("Can't get subproject")
            return
        }
        subprojectLabel.stringValue = subproject.name
        project?.makeDirty(true)
    }
    

}

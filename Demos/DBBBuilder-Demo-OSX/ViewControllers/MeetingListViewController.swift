//
//  MeetingListViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/24/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

class MeetingListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
DBBManagerConsumer {
    
    static let viewControllerIdentifier = "MeetingListViewController"
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var editColumn: NSTableColumn!
    @IBOutlet private weak var checkColumn: NSTableColumn!
    @IBOutlet private weak var nameColumn: NSTableColumn!
    
    private var allMeetings = [Meeting]()

    var dbManager: DBBManager?
    var project: Project?
    let tableRowHeight: CGFloat = 24.0

    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.rowHeight = tableRowHeight
        loadMeetings()
        title = "Meeting List"
    }
    
    // MARK: - TableView DataSource/Delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return allMeetings.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let meeting = allMeetings[row]
        var view: NSView?
        if tableColumn == editColumn {
            let pencilBtn = NSButton(frame: CGRect(x: 0, y: 0, width: 24.0, height: tableRowHeight))
            let pencilImage = NSImage(imageLiteralResourceName: "Pencil")
            pencilBtn.image = pencilImage
            pencilBtn.tag = row
            pencilBtn.showsBorderOnlyWhileMouseInside = true
            pencilBtn.isBordered = false
            pencilBtn.target = self
            pencilBtn.action = #selector(editMeetingForButton(_:))
            view = pencilBtn
        } else if tableColumn == checkColumn {
            let check = NSButton()
            check.tag = row
            check.setButtonType(.switch)
            if let proj = project, let _ = proj.meetings.index(of: meeting) {
                check.state = .on
            }
            check.target = self
            check.title = ""
            check.action = #selector(handleCheckboxClick(_:))
            view = check
        } else if tableColumn == nameColumn {
            let columnWidth = tableView.frame.width - editColumn.width - checkColumn.width
            let nameLabel = NSTextField(frame: CGRect(x: 0, y: 0, width: columnWidth, height: tableRowHeight))
            nameLabel.drawsBackground = false
            nameLabel.stringValue = meeting.purpose
            nameLabel.isEditable = false
            nameLabel.isBordered = false
            view = nameLabel
        }
        
        return view
    }
    
    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        return false
    }
    
    // MARK: - Private Methods
    
    private func loadMeetings() {
        guard let manager = dbManager else {
            os_log("DB manager is nil")
            return
        }
        
        // get all projects, sorted by start date
        let options = DBBQueryOptions.queryOptionsWithAscendingSortForColumns(["startTime"])
        guard let results = Meeting.instancesWithOptions(options, manager: manager) as? [Meeting] else {
            os_log("Meetings array is nil")
            return
        }
        
        allMeetings = results
        tableView.reloadData()
    }
    
    @objc private func editMeetingForButton(_ button: NSButton) {
        let row = button.tag
        guard row < allMeetings.count else {
            os_log("Selected row %d with %d number of meetings", row, allMeetings.count)
            return
        }

        let meeting = allMeetings[row]
        showEditMeetingViewController(meetingToEdit: meeting)
    }
    
    @objc private func handleCheckboxClick(_ button: NSButton) {
        let row = button.tag
        guard row < allMeetings.count else {
            os_log("Selected row %d with %d number of meetings", row, allMeetings.count)
            return
        }
        
        let state = (button.state == .on)
        let meeting = allMeetings[row]
        if state == true {
            project?.addMeeting(meeting)
        } else {
            project?.removeMeeting(meeting)
        }
        
        project?.makeDirty(true)
    }
    
    private func showEditMeetingViewController(meetingToEdit: Meeting?) {
        guard let editMtgVC = storyboard?.instantiateController(withIdentifier: EditMeetingViewController.viewControllerIdentifier) as? EditMeetingViewController else {
            os_log("Can't instantiate edit meeting viewController")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent is nil or is not a ContainerViewController")
            return
        }
        
        editMtgVC.project = project
        editMtgVC.meeting = meetingToEdit
        parentVC.showChildViewController(editMtgVC)
    }

    private func showEditProjectViewController() {
        guard let editProjectVC = storyboard?.instantiateController(withIdentifier: EditProjectViewController.viewControllerIdentifier) as? EditProjectViewController else {
            os_log("Can't instantiate edit project viewController")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent is nil or is not a ContainerViewController")
            return
        }
        
        editProjectVC.project = project
        parentVC.showChildViewController(editProjectVC)
    }

    // MARK: - Actions
    
    @IBAction func makeNewMeeting(_ sender: NSButton) {
        showEditMeetingViewController(meetingToEdit: nil)
    }
    
    @IBAction func saveChanges(_ sender: NSButton) {
        let success = project?.saveToDB()
        os_log("Saved meeting changes to project: %@", (success == true) ? "true" : "false")
        if success == false {
            os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
        }
        project?.makeDirty(success == false)
        
        showEditProjectViewController()
    }
    
}

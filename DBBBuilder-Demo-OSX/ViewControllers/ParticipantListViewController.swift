//
//  ParticipantListViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/25/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

class ParticipantListViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, DBBManagerConsumer {
    static let viewControllerIdentifier = "ParticipantListViewController"
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var editColumn: NSTableColumn!
    @IBOutlet private weak var checkColumn: NSTableColumn!
    @IBOutlet private weak var nameColumn: NSTableColumn!
    
    var dbManager: DBBManager?
    var allParticipants = [Person]()
    var meeting: Meeting?
    var project: Project?
    let tableViewRowHeight: CGFloat = 24
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = tableViewRowHeight
        loadParticipants()
        title = "Participants List"
    }
    
    // MARK: - TableView DataSource/Delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return allParticipants.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view: NSView?
        guard row < allParticipants.count else {
            os_log("Out of range: row = %d, participants count = %d", row, allParticipants.count)
            return nil
        }
        let person = allParticipants[row]
        
        if tableColumn == editColumn {
            let pencilBtn = NSButton(frame: CGRect(x: 0, y: 0, width: 24.0, height: tableViewRowHeight))
            let pencilImage = NSImage(imageLiteralResourceName: "Pencil")
            pencilBtn.image = pencilImage
            pencilBtn.tag = row
            pencilBtn.showsBorderOnlyWhileMouseInside = true
            pencilBtn.isBordered = false
            pencilBtn.target = self
            pencilBtn.action = #selector(editPersonForButton(_:))
            view = pencilBtn
        } else if tableColumn == checkColumn {
            let check = NSButton()
            check.tag = row
            check.setButtonType(.switch)
            if let mtg = meeting, let _ = mtg.participants?.index(of: person) {
                check.state = .on
            }
            check.target = self
            check.title = ""
            check.action = #selector(handleCheckboxClick(_:))
            view = check
        } else if tableColumn == nameColumn {
            let nameLabel = NSTextField(frame: CGRect(x: 0, y: 0, width: 300, height: tableViewRowHeight))
            nameLabel.stringValue = person.fullNameAndDepartment()
            nameLabel.isEditable = false
            nameLabel.isBordered = false
            view = nameLabel
        }
        
        return view
    }
    
    // MARK: - Private Methods
    
    private func loadParticipants() {
        guard let manager = dbManager else {
            os_log("DB Manager is nil")
            return
        }
        
        let options = DBBQueryOptions.queryOptionsWithAscendingSortForColumns(["lastName"])
        guard let people = Person.instancesWithOptions(options, manager: manager) as? [Person] else {
            os_log("Can't fetch people")
            return
        }
        
        allParticipants = people
        tableView.reloadData()
    }
    
    @objc func editPersonForButton(_ sender: NSButton) {
        let row = sender.tag
        guard allParticipants.count < row else {
            os_log("Out of range: row = %d, participants count = %d", row, allParticipants.count)
            return
        }
        
        let person = allParticipants[row]
        showEditParticipantViewController(personToEdit: person)
    }
    
    @objc func handleCheckboxClick(_ sender: NSButton) {
        guard let manager = dbManager else {
            os_log("DB manager is nil")
            return
        }
        
        let row = sender.tag
        let state = (sender.state == .on) ? true : false
        guard row < allParticipants.count else {
            os_log("Out of range: row = %d, participants count = %d", row, allParticipants.count)
            return
        }
        let person = allParticipants[row]
        if state == true {
            meeting?.addParticipant(person)
        } else {
            meeting?.removeParticipant(person, manager: manager)
        }
        
        meeting?.makeDirty(true)
    }
    
    private func showEditParticipantViewController(personToEdit: Person?) {
        guard let editPersonVC = storyboard?.instantiateController(withIdentifier: EditParticipantViewController.viewControllerIdentifier) as? EditParticipantViewController else {
            os_log("Can't instantiate edit participant viewController")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent is nil or is not a ContainerViewController")
            return
        }
        
        editPersonVC.participant = personToEdit
        editPersonVC.meeting = meeting
        editPersonVC.project = project
        parentVC.showChildViewController(editPersonVC)
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
        
        editMtgVC.meeting = meetingToEdit
        editMtgVC.project = project
        parentVC.showChildViewController(editMtgVC)
    }
    
    // MARK: - Actions
    
    @IBAction func makeNewParticipant(_ sender: NSButton) {
        showEditParticipantViewController(personToEdit: nil)
    }
    
    @IBAction func saveChanges(_ sender: NSButton) {
        let success = meeting?.saveToDB()
        os_log("Saved participants to meeting: %@", (success == true) ? "true" : "false")
        meeting?.makeDirty(success == false)
        showEditMeetingViewController(meetingToEdit: meeting)
    }
}



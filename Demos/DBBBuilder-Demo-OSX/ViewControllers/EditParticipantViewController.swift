//
//  EditParticipantViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/26/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

class EditParticipantViewController: NSViewController, NSTextFieldDelegate, DBBManagerConsumer {
    static let viewControllerIdentifier = "EditParticipantViewController"
    
    @IBOutlet private weak var firstNameField: NSTextField!
    @IBOutlet private weak var middleInitialField: NSTextField!
    @IBOutlet private weak var lastNameField: NSTextField!
    @IBOutlet private weak var departmentField: NSTextField!
    @IBOutlet private weak var saveButton: NSButton!
    
    private var activeTextField: NSTextField?
    
    var dbManager: DBBManager?
    var participant: Person?
    var meeting: Meeting?
    var project: Project?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChangeNotification), name: NSControl.textDidChangeNotification, object: nil)
        
        if let participant = self.participant {
            title = "Edit Participant"
            firstNameField.stringValue = participant.firstName
            middleInitialField.stringValue = participant.middleInitial
            lastNameField.stringValue = participant.lastName
            departmentField.stringValue = participant.department
        } else {
            title = "Add Participant"
            guard let dbManager = dbManager else {
                os_log("DB manager is nil")
                return
            }
            
            self.participant = Person(dbManager: dbManager)
        }
        
        enableSaveButton()
        firstNameField.delegate = self
        middleInitialField.delegate = self
        lastNameField.delegate = self
        departmentField.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        firstNameField.becomeFirstResponder()
        firstNameField.selectText(nil)
    }
    
    // MARK: - Actions
    
    @IBAction func saveChanges(_ sender: NSButton) {
        let success = participant?.saveToDB()
        os_log("Saved changes to participant: %@", (success == true) ? "true" : "false")
        participant?.makeDirty(success == false)
        showParcipitantList()
    }
    
    @IBAction func cancelChanges(_ sender: NSButton) {
        showParcipitantList()
    }
    
    // MARK: - Private Methods
    
    private func enableSaveButton() {
        saveButton.isEnabled = firstNameField.stringValue.isEmpty == false &&
            lastNameField.stringValue.isEmpty == false &&
            departmentField.stringValue.isEmpty == false
    }
    
    private func showParcipitantList() {
        guard let participantListVC = storyboard?.instantiateController(withIdentifier: ParticipantListViewController.viewControllerIdentifier) as? ParticipantListViewController else {
            os_log("Unable to instantiate parcipitant list view controller")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent view controller is nil or is not a ContainerViewController")
            return
        }
        
        participantListVC.meeting = meeting
        participantListVC.project = project
        parentVC.showChildViewController(participantListVC)
    }
    @objc func handleTextChangeNotification(notification: Notification) {
        if activeTextField == firstNameField {
            participant?.firstName = firstNameField.stringValue
        } else if activeTextField == middleInitialField {
            participant?.middleInitial = middleInitialField.stringValue
        } else if activeTextField == lastNameField {
            participant?.lastName = lastNameField.stringValue
        } else if activeTextField == departmentField {
            participant?.department = departmentField.stringValue
        }
        
        participant?.makeDirty(true)
        enableSaveButton()
    }

    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        if let fld = control as? NSTextField {
            activeTextField = fld
        }
        
        return true
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        activeTextField = nil
        return true
    }
}

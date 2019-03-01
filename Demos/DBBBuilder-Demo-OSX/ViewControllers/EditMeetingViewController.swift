//
//  EditMeetingViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/25/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

class EditMeetingViewController: NSViewController, NSTextFieldDelegate, NSTableViewDataSource, DBBManagerConsumer {
    static let viewControllerIdentifier = "EditMeetingViewController"
    var dbManager: DBBManager?
    var meeting: Meeting?
    var project: Project?
    
    @IBOutlet private weak var purposeField: NSTextField!
    @IBOutlet private weak var startTimeField: NSTextField!
    @IBOutlet private weak var endTimeField: NSTextField!
    @IBOutlet private weak var participantsTable: NSTableView!
    @IBOutlet private weak var startTimePicker: NSDatePicker!
    @IBOutlet private weak var endTimePicker: NSDatePicker!
    @IBOutlet private weak var saveButton: NSButton!

    private var hasChangedEndTime = false
    private var activeTextField: NSTextField?

    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChangedNotification), name: NSControl.textDidChangeNotification, object: nil)
        purposeField.delegate = self
        startTimeField.delegate = self
        endTimeField.delegate = self
        let startFormatter = DateFormatter.dbb_shortDateTimeFormatter()
        startTimeField.cell?.formatter = startFormatter
        let endFormatter = DateFormatter.dbb_shortDateTimeFormatter()
        endTimeField.cell?.formatter = endFormatter

        if let meeting = self.meeting {
            purposeField.stringValue = meeting.purpose
            if let startTime = meeting.startTime {
                startTimePicker.dateValue = startTime
                startTimeField.stringValue = startTime.dbb_displayTime()
            }
            if let endTime = meeting.finishTime {
                endTimePicker.dateValue = endTime
                endTimeField.stringValue = endTime.dbb_displayTime()
            }
            title = "Edit Meeting"
        } else {
            let date = Date()
            guard let dbManager = dbManager else {
                os_log("DB Manager is nil")
                return
            }
            meeting = Meeting(dbManager: dbManager)
            meeting?.startTime = date
            meeting?.finishTime = date
            startTimePicker.dateValue = date
            endTimePicker.dateValue = date
            startTimeField.stringValue = date.dbb_displayTime()
            endTimeField.stringValue = date.dbb_displayTime()
            title = "Add Meeting"
        }
        
        participantsTable.reloadData()
        enableSaveButton()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        purposeField.becomeFirstResponder()
        purposeField.selectText(nil)
    }

    // MARK: - Private Helpers
    
    private func enableSaveButton() {
        var enable = false
        if let startTime = meeting?.startTime, let endTime = meeting?.finishTime {
            enable = purposeField.stringValue.isEmpty == false && endTime >= startTime
        }
        saveButton.isEnabled = enable
    }
    
    // MARK: - Actions
    
    @IBAction func changedStartDate(_ sender: NSDatePicker) {
        let newTime = dateTime(sender.dateValue, timeString: startTimeField.stringValue)
        meeting?.startTime = newTime
        enableSaveButton()
        if hasChangedEndTime == false {
            endTimePicker.dateValue = sender.dateValue
            meeting?.finishTime = newTime
            changedEndDate(endTimePicker)
        }
        
        updateTimeFields()
    }
    
    @IBAction func changedEndDate(_ sender: NSDatePicker) {
        meeting?.finishTime = dateTime(sender.dateValue, timeString: endTimeField.stringValue)
        enableSaveButton()
        hasChangedEndTime = true
        
        updateTimeFields()
    }
    
    @IBAction func addParticipantsButtonClicked(_ sender: NSButton) {
        guard let meeting = self.meeting else {
            os_log("Meeting is nil")
            return
        }

        showParticipantsList(meeting: meeting)
    }

    @IBAction func saveChanges(_ sender: NSButton) {
        let success = meeting?.saveToDB()
        os_log("Saved message: %@", (success == true) ? "True" : "False")
        if success == false {
            os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
        }
       meeting?.makeDirty(success == false)
        showMeetingList()
    }
    
    @IBAction func cancelClose(_ sender: NSButton) {
        showMeetingList()
    }

    // MARK: - Private Helpers
    
    private func updateTimeFields() {
        if let startDate = dateTime(startTimePicker.dateValue, timeString: startTimeField.stringValue) {
            startTimeField.objectValue = startDate
        }
        
        if let endDate = dateTime(endTimePicker.dateValue, timeString: endTimeField.stringValue) {
            endTimeField.objectValue = endDate
        }
    }
    
    private func showParticipantsList(meeting: Meeting) {
        guard let peopleListVC = storyboard?.instantiateController(withIdentifier: ParticipantListViewController.viewControllerIdentifier) as? ParticipantListViewController else {
            os_log("Unable to instantiate participants list view controller")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent view controller is nil or is not a ContainerViewController")
            return
        }
        
        peopleListVC.meeting = meeting
        peopleListVC.project = project
        parentVC.showChildViewController(peopleListVC)
    }

    private func showMeetingList() {
        guard let meetingListVC = storyboard?.instantiateController(withIdentifier: MeetingListViewController.viewControllerIdentifier) as? MeetingListViewController else {
            os_log("Unable to instantiate meeting list view controller")
            return
        }
        
        guard let parentVC = parent as? ContainerViewController else {
            os_log("Parent view controller is nil or is not a ContainerViewController")
            return
        }
        
        meetingListVC.project = project
        parentVC.showChildViewController(meetingListVC)
    }
    
    // MARK: - Date/Time Helpers
    
    private func dateTime(_ date: Date, timeString: String) -> Date? {
        let fullTimeArray = timeString.components(separatedBy: " ")
        if fullTimeArray.count > 1 {
            let timeArray = fullTimeArray[1].components(separatedBy: ":")
            if timeArray.count > 1, var hours = Int(timeArray[0]), let minutes = Int(timeArray[1]) {
                if fullTimeArray.count > 2 && fullTimeArray[2].isEmpty == false {
                    let timeOfDay = fullTimeArray[2]
                    if let ampm = timeOfDay.first, String(ampm).uppercased() == "P" && hours < 12 {
                        hours += 12
                    }
                }

                let newDate = date.dbb_dateByAddingHours(hours, minutes: minutes)
                return newDate
            }
        }
        
        return nil
    }
    
    
    @objc private func handleTextChangedNotification(notification: Notification) {
        if activeTextField == purposeField {
            meeting?.purpose = purposeField.stringValue
        } else if activeTextField == startTimeField {
            meeting?.startTime = dateTime(startTimePicker.dateValue, timeString: startTimeField.stringValue)
        } else if activeTextField == endTimeField {
            meeting?.finishTime = dateTime(endTimePicker.dateValue, timeString: endTimeField.stringValue)
            hasChangedEndTime = true
        }
        
        meeting?.makeDirty(true)
        enableSaveButton()
    }
    
    // MARK: - TableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return meeting?.participants?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let participants = meeting?.participants {
            let person = participants[row]
            return person.fullNameAndDepartment()
        }
        
        return nil
    }

    // MARK: - Notifications/Delegate Methods
    
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

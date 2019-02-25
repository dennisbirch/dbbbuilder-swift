//
//  EditMeetingViewController.swift
//  DBBBuilder-Swift
//
//  Created by Birch, Dennis on 6/29/15.
//  Copyright © 2015 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder
import os.log

protocol EditMeetingDelegate
{
    func meetingEditor(editor: DBBEditMeetingViewController, savedMeeting:Meeting)
}


class DBBEditMeetingViewController: UITableViewController, DatePickerViewDelegate, UITextFieldDelegate {
    var meeting: Meeting?
    var delegate: EditMeetingDelegate?
    @IBOutlet weak var meetingPurposeField: UITextField!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var stopLabel: UILabel!
    @IBOutlet weak var participantsLabel: UILabel!
    var dbManager: DBBManager?

    var datePickerView: DBBDatePickerView?
    
    var activeTextField: UITextField?
    
    var startDate: Date?
    var stopDate: Date?

    var hasSetStopTime = false
    var shouldDeferSaving = false

    enum TableSectionType: Int {
        case purpose
        case startDate
        case stopDate
        case participants
    }
    
	let kParticipantsCellHeight: CGFloat = 88.0
    let kDefaultTableCellHeight: CGFloat	= 44.0
    let kSectionHeaderViewHeight: CGFloat = 32.0
	
	let kEditAttendeesSegue = "EditAttendeesSegue"
    
    // MARK: - ViewController Lifecycle

	override func viewDidLoad() {
        super.viewDidLoad()
        
        if let meeting = meeting {
			let purpose = meeting.purpose
				meetingPurposeField.text = purpose
			
			if let startTime = meeting.startTime {
                startLabel.text = startTime.dbb_displayTime()
				startDate = startTime
			}
			if let endTime = meeting.finishTime {
				stopLabel.text = endTime.dbb_displayTime()
				stopDate = endTime
			}
			
			hasSetStopTime = meeting.idNum > 0
        }
        
        meetingPurposeField.delegate = self
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textFieldDidChange),
                                               name: UITextField.textDidChangeNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        participantsLabel.text = participantNames()
        shouldDeferSaving = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// tidy up UI
		closeDatePickerView()
		activeTextField?.resignFirstResponder()
		
		if shouldDeferSaving {
			return
		}
		
		// save meeting
        guard let meeting = meeting else {
			return
		}

        let purpose = meeting.purpose
		if purpose.isEmpty == false {
			let success = meeting.saveToDB()
            delegate?.meetingEditor(editor: self, savedMeeting: meeting)
            if success == false {
                os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
            }
		}
	}
	
    func closeDatePickerView() {
		datePickerView?.removeFromSuperview()
    }
	
	// MARK: - Segues
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		shouldDeferSaving = true
		let vc = segue.destination as? DBBEditAttendeesViewController
        vc?.dbManager = dbManager

		if segue.identifier == kEditAttendeesSegue {
			if meeting == nil {
                guard let manager = dbManager else {
                    os_log("DB Manager is nil")
                    return
                }
                
				meeting = Meeting(dbManager: manager)
			}
            
			vc?.meeting = meeting
			vc?.title = "Edit Attendees"
		}
	}
	
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		guard let purpose = meeting?.purpose else {
			showMissingPurposeAlert()
			return false
		}
		
		if purpose.isEmpty {
			showMissingPurposeAlert()
			return false
		}
		
		return true
	}
	
	func showMissingPurposeAlert() {
        UIAlertController.showDefaultAlertWithTitle("Missing Purpose",
                                                    message: "Every meeting needs a purpose, but you haven't entered one for this meeting",
                                                    inViewController: self)
	}

    // MARK: - Helpers
    
    func participantNames() -> String {
        var names = [String]()
        if let participants = meeting?.participants {
            for person in participants {
                let fullName = person.fullName() as String
                names.append(fullName)
            }
        }
        
		return names.joined(separator: ", ")
    }
	
	func showDatePickerView(section: TableSectionType) {
		activeTextField?.resignFirstResponder()
		
		var date: Date?
		var label: UILabel?
		
		if section == .startDate {
			date = startDate
			label = startLabel
		} else {
			date = stopDate
			label = stopLabel
		}
		
		datePickerView = DBBDatePickerView(date: date, section:section.rawValue, showTime: true, superView: view)
		
		if date == nil {
			if section == .startDate {
				label?.text = Date().dbb_displayTime()
			} else {
				label?.text = Date().dbb_displayTime()
			}
		}
		
		if var frame = datePickerView?.frame, let label = label {
            let labelFrame:CGRect = label.convert(label.frame, to: view)
            frame = CGRect(x: (frame.origin.x),
                y: labelFrame.origin.y - 60,
                width:(frame.width),
                height:(frame.height))
            datePickerView?.frame = frame
        }
		datePickerView?.tag = section.rawValue
		datePickerView?.delegate = self
        if let picker = datePickerView {
            view.addSubview(picker)
        }
		tableView.reloadData()
	}
	

	// MARK: - UITableViewDelegate
	
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let section = TableSectionType(rawValue: indexPath.section)
		
		if section == .startDate || section == .stopDate, let sectionToShow = section {
            showDatePickerView(section: sectionToShow)
		}
	}
	
	// MARK: UITableViewDataSource
	
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let section = TableSectionType(rawValue: indexPath.section)
		
		if section == .participants {
			return CGFloat(kParticipantsCellHeight)
		}
		
		return CGFloat(kDefaultTableCellHeight)
	}

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat(kSectionHeaderViewHeight + 4.0)
	}
	
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var frame = CGRect(x: 0, y: 10.0, width: tableView.bounds.width, height: kSectionHeaderViewHeight)
		let view = UIView(frame: frame)
		
		let sectionTitle: String
		
		guard let tableSection = TableSectionType(rawValue: section) else {
			os_log("WTF? No table section?")
			return nil
		}
		
		switch tableSection {
		case .purpose:
			sectionTitle = "PURPOSE"
		case .startDate:
			sectionTitle = "START TIME"
		case .stopDate:
			sectionTitle = "END TIME"
		case .participants:
			sectionTitle = "PARTICIPANTS"
		}
		
		// make label
		frame.origin.x = 10.0
		let label = UILabel(frame: frame)
		label.text = sectionTitle
		label.backgroundColor = UIColor.clear
		label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 14)

		view.addSubview(label)
		
		return view
	}

    // MARK: - UITextFieldDelegate
	
    func textFieldDidBeginEditing(_ textField: UITextField) {
		activeTextField = textField
	}
	
    func textFieldDidEndEditing(_ textField: UITextField) {
		if textField == meetingPurposeField, let text = textField.text {
			meeting?.purpose = text
		}
		
		activeTextField = nil
	}
	
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == meetingPurposeField {
			textField.resignFirstResponder()
		}
		
		return true
	}
	
	
    @objc func textFieldDidChange(notification: Notification) {
		if let fld = notification.object as? UITextField,
            fld == meetingPurposeField,
            let text = fld.text {
			meeting?.purpose = text
		}
    }

    
    // MARK: - DatePickerViewDelegate
    
    func valueChanged(newDate:Date, pickerView:DBBDatePickerView) {
		guard let section = TableSectionType(rawValue: pickerView.tag) else {
			os_log("Oops, there was a problem setting the meeting start or stop time")
			return
		}
		
		if section == .startDate {
			meeting?.startTime = newDate
			startDate = newDate
			startLabel.text = newDate.dbb_displayTime()
			
			if hasSetStopTime == false {
				// match start and stop times
				stopDate = newDate
				stopLabel.text = newDate.dbb_displayTime()
			}
		} else {
			meeting?.finishTime = newDate
			stopDate = newDate
			stopLabel.text = newDate.dbb_displayTime()
			hasSetStopTime = true
		}
		
		meeting?.makeDirty(true)
    }
	
	
    func dismissedDatePickerView(pickerView: DBBDatePickerView) {
        pickerView.removeFromSuperview()
        datePickerView = nil
    }

}

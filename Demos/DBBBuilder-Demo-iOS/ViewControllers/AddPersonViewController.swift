//
//  AddPersonViewController.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 3/1/16.
//  Copyright © 2016 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder
import os.log

protocol AttendeeEditorDelegate {
	func addPersonViewControllerSavedPerson(person: Person)
}

class AddPersonViewController: UITableViewController, UITextFieldDelegate {
	var personToEdit: Person?
	var delegate: AttendeeEditorDelegate?
    var dbManager: DBBManager?

	@IBOutlet weak var firstNameField: UITextField!
	@IBOutlet weak var lastNameField: UITextField!
	@IBOutlet weak var middleInitialField: UITextField!
	@IBOutlet weak var departmentField: UITextField!
	@IBOutlet weak var ageField: UITextField!
	
	var activeTextField: UITextField?

	let kSectionHeaderViewHeight: CGFloat = 32.0

	enum TableSectionType: Int {
		case FirstName
		case MiddleInitial
		case LastName
		case Department
		case Age
	}

	// MARK: - ViewController Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let person = personToEdit {
			firstNameField.text = person.firstName
			middleInitialField.text = person.middleInitial
			lastNameField.text = person.lastName
			departmentField.text = person.department
			if person.age > 0 {
				ageField.text = "\(person.age)"
			}
		}
	}
	
	// MARK: - Actions
	
	@IBAction func saveButtonTapped(sender: AnyObject) {
		activeTextField?.resignFirstResponder()
		
        dismiss(animated: true) { [weak self] () -> Void in
			if let person = self?.personToEdit {
				if person.isDirty {
					if person.saveToDB() {
						if let delegate = self?.delegate {
                            delegate.addPersonViewControllerSavedPerson(person: person)
						}
					} else {
                        os_log("Error saving to database: %@", self?.dbManager?.errorMessage() ?? "NA")
					}
				}
			}
		}
	}
	
	@IBAction func cancelButtonTapped(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
	}
	
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat(kSectionHeaderViewHeight + 4.0)
	}
	
	// MARK: - TableView
	
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var frame = CGRect(x: 0,
			y: 10.0,
			width: tableView.bounds.width,
			height: kSectionHeaderViewHeight)
		let view = UIView(frame: frame)
		
		let sectionTitle: String
		
		guard let tableSection = TableSectionType(rawValue: section) else {
			os_log("WTF? No table section?")
			return nil
		}
		
		switch tableSection {
		case .FirstName:
			sectionTitle = "FIRST NAME"
		case .MiddleInitial:
			sectionTitle = "MIDDLE INITIAL"
		case .LastName:
			sectionTitle = "LAST NAME"
		case .Department:
			sectionTitle = "DEPARTMENT"
		case .Age:
			sectionTitle = "AGE"
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
	
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        var editablePerson: Person
        if let personToEdit = self.personToEdit {
            editablePerson = personToEdit
        } else {
            guard let manager = dbManager else {
                os_log("DB Manager is nil")
                return false
            }
            
            editablePerson = Person(dbManager: manager)
        }
        
		editablePerson.makeDirty(true)
        self.personToEdit = editablePerson
		
		return true
	}
	
    func textFieldDidEndEditing(_ textField: UITextField) {
		if let text = textField.text {
			if textField == firstNameField {
				personToEdit?.firstName = text
			} else if textField == middleInitialField {
				personToEdit?.middleInitial = text
			} else if textField == lastNameField {
				personToEdit?.lastName = text
			} else if textField == departmentField {
				personToEdit?.department = text
			} else if textField == ageField {
				if let age = Int(text) {
					personToEdit?.age = age
				}
			}
		}
		
		activeTextField = nil
	}
	
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}

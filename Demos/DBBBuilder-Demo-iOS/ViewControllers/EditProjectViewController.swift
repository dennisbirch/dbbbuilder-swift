//
//  EditProjectViewController.swift
//  DBBBuilder-Swift
//
//  Created by Birch, Dennis on 6/24/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder
import os.log

class EditProjectViewController: UITableViewController, UITextFieldDelegate, DatePickerViewDelegate {
    var project: Project? = nil
    var startDate: Date? = nil
    var stopDate: Date? = nil
    var datePickerView: DBBDatePickerView? = nil
    var activeTextField: UITextField? = nil
    var shouldDeferSaving: Bool = false
    var dbManager: DBBManager?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var budgetField: UITextField!
    @IBOutlet weak var tagsField: UITextField!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var stopLabel: UILabel!
    @IBOutlet weak var meetingsLabel: UILabel!
    @IBOutlet weak var subProjectLabel: UILabel!
    @IBOutlet weak var subProjectButton: UIButton!

    let kSectionHeaderViewHeight:CGFloat = 32.0
	
	let kSubprojectModalSegue = "SubprojectModalSegue"
	let kEditMeetingsSegue = "EditMeetingsSegue"

    enum ProjectEditTableSection: Int {
        case Name
        case Code
        case StartDate
        case EndDate
        case Budget
        case Meetings
        case Tags
        case SubProject
    }
	
	// MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let project = project {
            nameField.text = project.name
            codeField.text = project.code
			loadDates()
            displayBudget()
			let tags = project.tags
            tagsField.text = tags.joined(separator: " ")
			
            startDate = project.startDate
            stopDate = project.endDate
        } else {
            guard let manager = dbManager else {
                os_log("DB Manager is nil")
                return
            }
            
            project = Project(dbManager: manager)
        }
		
		loadDates()
        nameField.delegate = self
        budgetField.delegate = self
        codeField.delegate = self
        tagsField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChangeText), name: UITextField.textDidChangeNotification, object: nil)
    }
	
	func loadDates() {
		if let startDate = project?.startDate {
			startLabel.text = startDate.db_display()
			startLabel.textColor = UIColor.darkText
            startLabel.font = UIFont.systemFont(ofSize: 17.0)
		} else {
			startLabel.text = "Tap to enter start date"
			startLabel.textColor = UIColor.textFieldPlaceholderColor()
            startLabel.font = UIFont.systemFont(ofSize: 15.0)
		}
		if let stopDate = project?.endDate {
			stopLabel.text = stopDate.db_display()
			stopLabel.textColor = UIColor.darkText
            stopLabel.font = UIFont.systemFont(ofSize: 17.0)
		} else {
			stopLabel.text = "Tap to enter end date"
			stopLabel.textColor = UIColor.textFieldPlaceholderColor()
            stopLabel.font = UIFont.systemFont(ofSize: 15.0)
		}
	}
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        meetingsLabel.text = project?.meetingDisplayString()
        shouldDeferSaving = false
        setupSubProjectControls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        activeTextField?.resignFirstResponder()
        
        if (shouldDeferSaving) {
            return
        }
        
        if let project = project {
            // save meeting
            if project.isDirty == false {
                return
            }
            
            let projName = project.name
            if projName.isEmpty == false {
                let success = project.saveToDB()
                if success == false {
                    os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        shouldDeferSaving = true
        
        if segue.identifier == kEditMeetingsSegue {
            let vc  = segue.destination as? MeetingListViewController
            vc?.dbManager = dbManager
            vc?.project = project
        } else if segue.identifier == kSubprojectModalSegue {
            let projListVC = segue.destination as? ProjectListViewController
            projListVC?.dbManager = dbManager
            projListVC?.parentProject = project
        }
    }

    // MARK: - Actions
    
    @IBAction func subProjectButtonTapped(sender: AnyObject) {
        // clear subproject
        if let _: Project = project?.subProject
        {
            project?.subProject = nil
            project?.makeDirty(true)
            setupSubProjectControls()
        } else {
            // create new subproject
            performSegue(withIdentifier: kSubprojectModalSegue, sender: project)
        }
    }
    
    // MARK: - Helpers

    func displayBudget() {
		if let budget = project?.budget {
			let formatter:NumberFormatter = NumberFormatter()
			formatter.numberStyle = .currency
			
            let budgetStr = formatter.string(from: NSNumber(value: budget))
			budgetField.text = (budget > 0) ? budgetStr : ""
		}
    }
	
    func setupSubProjectControls() {
        let titleLabel = (project?.subProject == nil) ? "Set" : "Clear"
        subProjectButton.setTitle(titleLabel, for: .normal)
        subProjectButton.sizeToFit()
        if let subproject = project?.subProject {
            subProjectLabel.text = subproject.name
        } else {
            subProjectLabel.text = "None"
        }
    }
    
    func showDatePickerView(section: Int) {
        activeTextField?.resignFirstResponder()
        
        var date: Date?
        var label: UILabel?
        
        if section == ProjectEditTableSection.StartDate.rawValue {
            date = startDate
            label = startLabel
        } else {
            date = stopDate
            label = stopLabel
        }
        
        datePickerView = DBBDatePickerView(date: date, section:section, showTime: false, superView: view)
        
        if date == nil {
            let newDate = Date()
            if section == ProjectEditTableSection.StartDate.rawValue {
                label?.text = newDate.db_display()
                startDate = newDate as Date
            } else {
                stopDate = newDate as Date
                label?.text = newDate.db_display()
            }
        }
        
        if var frame = datePickerView?.frame, let label = label {
            let labelFrame = label.convert(label.frame, to: view)
            frame = CGRect(x: (frame.origin.x), y: labelFrame.origin.y - 60, width:(frame.width), height:(frame.height))
            datePickerView?.frame = frame
            datePickerView?.tag = section
            datePickerView?.delegate = self
            if let picker = datePickerView {
                view.addSubview(picker)
            }
            tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == ProjectEditTableSection.StartDate.rawValue ||
            indexPath.section == ProjectEditTableSection.EndDate.rawValue {
            showDatePickerView(section: indexPath.section)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		guard let name = project?.name else {
			showMissingNameAlert()
			return false
		}

        if name.isEmpty {
			showMissingNameAlert()
			return false
		}
        
        return true
    }
	
	func showMissingNameAlert() {
        UIAlertController.showDefaultAlertWithTitle("Missing Name", message: "Every project needs a name, but you haven't entered one for this project", inViewController: self)
	}

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return kSectionHeaderViewHeight + 4.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // make backing view
        let view = UIView(frame:CGRect(x: 0, y: 10, width: self.view.bounds.width, height: kSectionHeaderViewHeight))

        // make label
        let label = UILabel(frame:CGRect(x: 10, y: 10, width: 100, height: kSectionHeaderViewHeight))
        
        let sectionTitle: String
        
        switch (section) {
            case ProjectEditTableSection.Name.rawValue:
                sectionTitle = "NAME"
            case ProjectEditTableSection.Code.rawValue:
                sectionTitle = "CODE"
            case ProjectEditTableSection.StartDate.rawValue:
                sectionTitle = "START DATE"
            case ProjectEditTableSection.EndDate.rawValue:
                sectionTitle = "END DATE"
            case ProjectEditTableSection.Budget.rawValue:
                sectionTitle = "BUDGET"
            case ProjectEditTableSection.Meetings.rawValue:
                sectionTitle = "MEETINGS"
            case ProjectEditTableSection.Tags.rawValue:
                sectionTitle = "TAGS"
            case ProjectEditTableSection.SubProject.rawValue:
                sectionTitle = "SUB-PROJECT"
            default:
                sectionTitle = ""
        }
        
        label.text = sectionTitle
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(label)
        
        return view
    }
    
    // MARK: - UITextFieldDelegate
    
    @objc func textFieldDidChangeText(notification: Notification) {
        if let currentText = activeTextField?.text, let project = project {
            if activeTextField == nameField {
                project.name = currentText
            } else if activeTextField == codeField {
                project.code = currentText
            } else if activeTextField == budgetField {
                if let value = Float(currentText) {
                    project.budget = value
                }
            }
            
            project.makeDirty(true)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        if textField == nameField {
            project?.name = text
        } else if textField == codeField {
            project?.code = text
        } else if textField == budgetField {
            let budgetStr = text.replacingOccurrences(of: "$", with: "")
            if let value = Float(budgetStr) {
                project?.budget = value
                displayBudget()
            }
        } else if textField == tagsField {
            let temp = text.replacingOccurrences(of: ",", with: " ")
            project?.tags = temp.split(separator: " ").map{ String($0) }
        }
        
        activeTextField = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == nameField {
            codeField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // check to make sure budget field entries are numbers or ".", but also allow backspace
        if textField != budgetField || string == "" {
            // slightly hacky, but works — "string" is empty if backspace key is typed
            return true
        }
        
        let allowedKeys = "0123456789."
        let start = string.startIndex
        let firstChar = String(string[...start])
        return allowedKeys.contains(firstChar)
    }
    
    // MARK: - DatePickerViewDelegate
    
    func valueChanged(newDate: Date, pickerView:DBBDatePickerView) {
        if datePickerView?.tag == ProjectEditTableSection.StartDate.rawValue {
            if startDate != newDate {
                project?.startDate = newDate
                project?.makeDirty(true)
                startDate = newDate
                startLabel.text = newDate.db_display()
            }
        } else {
            if stopDate != newDate {
                project?.endDate = newDate
                project?.makeDirty(true)
                stopDate = newDate
                stopLabel.text = newDate.db_display()
            }
        }
    }
    
    
    func dismissedDatePickerView(pickerView: DBBDatePickerView) {
		loadDates()
        pickerView.removeFromSuperview()
        datePickerView = nil
    }
}


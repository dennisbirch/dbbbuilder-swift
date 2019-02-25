//
//  MeetingListViewController.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 6/23/15.
//  Copyright (c) 2015 Dennis Birch. All rights reserved.
//

import UIKit
import ObjectiveC
import DBBBuilder
import os.log

class MeetingListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EditMeetingDelegate, EditButtonTableViewHandler {
    var project: Project?
    var projects: [Project]?
    var meetings:  [Meeting]?
	var alllMeetings: [Meeting]?
    var dbManager: DBBManager?

    @IBOutlet weak var tableView:  UITableView!
  
	let kEditMeetingSegue = "EditMeetingSegue"
	let kAddMeetingSegue = "AddMeetingSegue"
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Meetings"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target:self, action: #selector(addMeeting))
        navigationItem.rightBarButtonItem = addButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMeetings()
    }
    
    func loadMeetings() {
        guard let mgr = dbManager else {
            return
        }
        
        meetings = project?.meetings
		alllMeetings = Meeting.allMeetings(manager: mgr)

		tableView.reloadData()
    }
    
  
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let meetings = alllMeetings {
			return meetings.count
		}
		
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let CellIdentifier = "MeetingCell"
        let newCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        guard let cell = newCell as? EditButtonTableViewCell else {
            return newCell
        }
        
		if let allMeetings = alllMeetings {
			let pencil = UIImage(named: "Pencil")
			let meeting = allMeetings[indexPath.row] as Meeting
			let purpose = meeting.purpose
            cell.configureWithTitle(title: purpose, editImage: pencil, buttonHandler: self)
			
			// set checkmark for meetings belonging to project
			guard let meetings = project?.meetings else {
                cell.accessoryType = .none
				return cell
			}
            if meetings.contains(where: {$0 == meeting}) {
                cell.accessoryType = .checkmark
			} else {
                cell.accessoryType = .none
			}
		}
		
		return cell
	}
	
    @objc func addMeeting() {
        performSegue(withIdentifier: kAddMeetingSegue, sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
		
		guard let project = project else {
			return
		}
        
        // check meetings included in project, and add or remove them depending on their state
        guard let cell = tableView.cellForRow(at: indexPath) else {
			return
		}

		if let allMeetings = alllMeetings {
            let meeting = allMeetings[indexPath.row]
            
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
				project.removeMeeting(meeting)
            } else if cell.accessoryType == .none {
                cell.accessoryType = .checkmark
				project.addMeeting(meeting)
			}
			
            project.makeDirty(true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? DBBEditMeetingViewController else {
            return
        }
        
        vc.dbManager = dbManager

        if segue.identifier == kEditMeetingSegue {
            guard let meeting = sender as? Meeting else {
                return
            }
            
            vc.meeting = meeting
            vc.title = "Edit Meeting"
            vc.delegate = nil
        } else if segue.identifier == kAddMeetingSegue {
            guard let manager = dbManager else {
                os_log("DB Manager is nil")
                return
            }
            
            let meeting = Meeting(dbManager: manager)
            meeting.startTime = Date()
            meeting.finishTime = Date()
            vc.meeting = meeting
            vc.title = "Add Meeting"
            vc.delegate = self
        }
    }
    
    // MARK: - EditMeetingDelegate
    
    func meetingEditor(editor: DBBEditMeetingViewController, savedMeeting: Meeting) {
        project?.addMeeting(savedMeeting)
        if let success = project?.saveToDB() {
            os_log("Saved updated project: %@", (success == true) ? "true" : "false")
            if success == false {
                os_log("Error saving to database: %@", self.dbManager?.errorMessage() ?? "NA")
            }
        }
    }

	
	// MARK: - EditButtonTableViewHandler
	
    func editButtonTapped(sender: EditButtonTableViewCell, event: UIEvent) {
        guard let touches = event.allTouches, let oneTouch = touches.first else {
            return
        }
        
        let currentTouchPosition = oneTouch.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: currentTouchPosition) else {
            return
        }
        
        if let allMeetings = alllMeetings {
            let meeting = allMeetings[indexPath.row] as Meeting
            performSegue(withIdentifier: kEditMeetingSegue, sender: meeting)
        }
    }
    
}



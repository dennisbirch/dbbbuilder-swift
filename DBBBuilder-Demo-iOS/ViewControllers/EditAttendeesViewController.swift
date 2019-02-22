//
//  EditAttendeesViewController.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 3/1/16.
//  Copyright © 2016 Dennis Birch. All rights reserved.
//

import UIKit
import DBBBuilder
import os.log

class DBBEditAttendeesViewController: UITableViewController, EditButtonTableViewHandler, AttendeeEditorDelegate {
    var manager: DBBManager?
	var meeting: Meeting?
	var editParticipant: Person?
	var participants: [Person]?
    var dbManager: DBBManager?

	let kAddPersonSegueIdentifier = "AddPersonSegue"
	
	// MARK: - ViewController Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addParticipant))
		self.navigationItem.rightBarButtonItem = addButton
		
        guard let mgr = dbManager else {
            return
        }
        
        self.participants = Person.allInstances(manager: mgr) as? [Person]
	}
	
	// MARK: - Segues
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kAddPersonSegueIdentifier, let vc = segue.destination as? AddPersonViewController {
            vc.dbManager = dbManager
			vc.delegate = self
			if let person = sender as? Person {
				vc.personToEdit = person
			}
		}
	}
	
	// MARK: - UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let participants = participants {
		return participants.count
		}
		
		return 0
	}
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let cell = dequeuedCell as? EditButtonTableViewCell else {
            return dequeuedCell
        }
        
		guard let person = participants?[indexPath.row] else {
            cell.accessoryType = .none
			return cell
		}
        
		// add a Pencil image user can click on to edit person
		let pencil = UIImage(named: "Pencil")
        cell.configureWithTitle(title: person.fullNameAndDepartment(), editImage: pencil, buttonHandler: self)
        
        // TODO: Make sure this makes sense
        cell.accessoryType = .checkmark
		return cell
	}
	
	// MARK: - UITableViewDelegate
	
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mgr = dbManager else {
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
			return
		}

		if let allParticipants = participants {
			let person = allParticipants[indexPath.row]
			
			if cell.accessoryType == .checkmark {
				cell.accessoryType = .none
				meeting?.removeParticipant(person, manager: mgr)
			} else if cell.accessoryType == .none {
				cell.accessoryType = .checkmark
				meeting?.addParticipant(person)
			}
			
			meeting?.makeDirty(true)
		}
	}
	
	
	func showEditViewForPerson(person: Person) {
        performSegue(withIdentifier: kAddPersonSegueIdentifier, sender: nil)
	}

	// MARK: - Editing Participants
	
	@objc func addParticipant() {
        guard let manager = dbManager else {
            os_log("DB Manager is nil")
            return
        }
		let newPerson = Person(dbManager: manager)
        showEditViewForPerson(person: newPerson)
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
		
		if let participants = participants {
			let person = participants[indexPath.row]
            performSegue(withIdentifier: kAddPersonSegueIdentifier, sender: person)
		}
	}

	// MARK: - AttendeeEditorDelegate
	
	func addPersonViewControllerSavedPerson(person: Person) {
        guard let mgr = dbManager else {
            return
        }
        
		meeting?.addParticipant(person)
		participants = Person.allInstances(manager: mgr) as? [Person]
		tableView.reloadData()
	}
}


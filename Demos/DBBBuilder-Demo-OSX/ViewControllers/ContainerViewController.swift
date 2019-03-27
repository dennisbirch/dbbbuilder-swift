//
//  ContainerViewController.swift
//  DBBBuilder-Demo-OSX
//
//  Created by Dennis Birch on 1/24/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa
import DBBBuilder
import os.log

protocol DBBManagerConsumer {
    var dbManager: DBBManager? {get set}
}

class ContainerViewController: NSViewController {
    @IBOutlet private weak var containerView: NSView!
    
    var dbManager: DBBManager? {
        didSet {
            if var currentVC = children.first as? DBBManagerConsumer {
                currentVC.dbManager = self.dbManager
            }
        }
    }
    static let viewControllerIdentifier = "ContainerViewController"
    static let windowControllerIdentifier = "ContainerWindowController"
    private var currentChildViewController: NSViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let projectListVC = storyboard?.instantiateController(withIdentifier: ProjectListViewController.viewControllerIdentifier) as? ProjectListViewController else {
            os_log("Can't instantiate project list view controller")
            return
        }
        
        showChildViewController(projectListVC)
    }
    
    func showChildViewController(_ viewController: NSViewController) {
        if var vc = viewController as? DBBManagerConsumer {
            vc.dbManager = dbManager
        }
        
        addChild(viewController)
        let newView = viewController.view
        addViewToSelf(viewToPin: newView)
        
        currentChildViewController = viewController
        if let title = viewController.title {
            view.window?.title = title
        }
    }
    
    private func addViewToSelf(viewToPin: NSView) {
        if let currentVC = currentChildViewController, let index = children.firstIndex(of: currentVC) {
            removeChild(at: index)
            for subview in containerView.subviews {
                subview.removeFromSuperview()
            }
        } else {
            os_log("Cannot remove current view controller from hierarchy.")
        }

        containerView.addSubview(viewToPin)
        viewToPin.frame = view.frame
        viewToPin.translatesAutoresizingMaskIntoConstraints = false
        viewToPin.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        viewToPin.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        viewToPin.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        viewToPin.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }
    
}

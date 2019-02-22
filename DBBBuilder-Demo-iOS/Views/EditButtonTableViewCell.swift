//
//  EditButtonTableViewCell.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 3/1/16.
//  Copyright © 2016 Dennis Birch. All rights reserved.
//

import UIKit

@objc protocol EditButtonTableViewHandler {
	@objc func editButtonTapped(sender: EditButtonTableViewCell, event: UIEvent)
}

class EditButtonTableViewCell: UITableViewCell {
	
	var editImage: UIImage?
	
	@IBOutlet weak var editButton: UIButton!
	@IBOutlet weak var infoLabel: UILabel!
	@IBOutlet weak var widthConstraint: NSLayoutConstraint!
	@IBOutlet weak var heightConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	

	func configureWithTitle(title: String, editImage: UIImage?, buttonHandler: EditButtonTableViewHandler) {
		infoLabel.text = title
		if let image = editImage {
			editButton.addTarget(buttonHandler,
                                 action: #selector(buttonHandler.editButtonTapped),
                                 for: .touchDown)
			editButton.setBackgroundImage(editImage, for: .normal)
			widthConstraint.constant = image.size.width
			heightConstraint.constant = image.size.height
		} else {
			widthConstraint.constant = 0
			heightConstraint.constant = 0
			editButton.setBackgroundImage(nil, for: .normal)
		}
	}
}

//
//  UIAlertController+Extensions.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 1/22/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

#if os(iOS)
import UIKit

extension UIAlertController {
    static func showDefaultAlertWithTitle(_ title: String, message: String, buttonTitle: String = "OK", inViewController viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true, completion: nil)
    }
}
#endif

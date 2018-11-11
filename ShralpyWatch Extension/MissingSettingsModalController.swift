//
//  MissingSettingsModalController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/1/16.
//
//

import Foundation
import WatchKit

class MissingSettingsModalController:WKInterfaceController {
    
    @IBOutlet weak var messageLabel:WKInterfaceLabel?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissModal), name: NSNotification.Name(rawValue: "SDTideDidUpdate"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awake(withContext context: Any?) {
        let message = context as! String
        messageLabel?.setText(message)
    }
    
    @IBAction func dismissModal() {
        DispatchQueue.main.async {
            self.dismiss()
        }
    }
}

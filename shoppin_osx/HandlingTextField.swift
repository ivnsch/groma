//
//  HandlingTextField.swift
//  shoppin
//
//  Created by ischuetz on 31/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class HandlingTextField: NSTextField {
    
    var keyUpHandler: ((theEvent: NSEvent) -> Bool)?
    var keyDownHandler: ((theEvent: NSEvent) -> Bool)?

    override func keyUp(theEvent: NSEvent) {
        if self.keyUpHandler?(theEvent: theEvent) ?? true {
            super.keyUp(theEvent)
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        if self.keyDownHandler?(theEvent: theEvent) ?? true {
            super.keyDown(theEvent)
        }
    }
    
    override func complete(sender: AnyObject?) {
        super.complete(sender)
    }
}

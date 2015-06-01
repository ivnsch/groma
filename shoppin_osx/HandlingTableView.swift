//
//  HandlingTableView.swift
//  shoppin
//
//  Created by ischuetz on 01/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa


class HandlingTableView: NSTableView {

    var keyUpHandler: ((theEvent: NSEvent) -> Bool)? // return: true to call super after

    var keyDownHandler: ((theEvent: NSEvent) -> Bool)? // return: true to call super after
    
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
}

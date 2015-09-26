//
//  TaggedView.swift
//  shoppin
//
//  Created by ischuetz on 26/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

/**
* View with read write tag. NSView's tag is read only.
*/
class TaggedView: NSView {
    var tagReadWrite: Int = -1
    
    override var tag: Int {
        return tagReadWrite
    }
}

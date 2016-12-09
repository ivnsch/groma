//
//  NSTableView.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSTableView {
    
    func wrapUpdates(function: VoidFunction) -> VoidFunction {
        return {
            self.beginUpdates()
            function()
            self.endUpdates()
        }
    }
}

//
//  SectionModel.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// Object wrapper for table views with expandable cells (toggle expanded status) or anything else where it can be represented this way
class SectionModel<T> {
    var expanded: Bool
    let obj: T
    
    init(expanded: Bool = false, obj: T) {
        self.expanded = expanded
        self.obj = obj
    }
}

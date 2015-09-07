//
//  Array_ListItem.swift
//  shoppin
//
//  Created by ischuetz on 04/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: ListItem {
    
    /**
    Sorts increasingly by section and list item order
    */
    func sortedByOrder() -> [Element] {
        return self.sort {($0.section.order <= $1.section.order) && ($0.order <= $1.order)}
    }
}

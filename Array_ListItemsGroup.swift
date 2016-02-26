//
//  Array_ListItemsGroup.swift
//  shoppin
//
//  Created by ischuetz on 26/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: ListItemGroup {
    
    func sortedByOrder() -> [ListItemGroup] {
        return sort {$0.order < $1.order}
    }
}

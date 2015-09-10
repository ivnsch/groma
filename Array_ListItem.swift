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
    
    /**
    Group list items by list (note that the listitems inside each lists are ordered but the lists not)
    */
    func groupByList() -> [List: [ListItem]] {
        var dictionary = [List: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.list] == nil {
                dictionary[listItem.list] = []
            }
            dictionary[listItem.list]?.append(listItem)
        }
        return dictionary
    }
}


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
    
    /**
    Group list items by section (note that the listitems inside each section are ordered but the sections not)
    */
    func groupBySection() -> [Section: [ListItem]] {
        var dictionary = [Section: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.section] == nil {
                dictionary[listItem.section] = []
            }
            dictionary[listItem.section]?.append(listItem)
        }
        return dictionary
    }
    
    func sectionCountDict() -> [Section: Int] {
        return groupBySection().map {($0, $1.count)}
    }
    
    var sectionCount: Int {
        return Set(map{$0.section}).count
    }
    
    func findFirstWithProductName(productName: String) -> ListItem? {
        for listItem in self {
            if listItem.product.name == productName {
                return listItem
            }
        }
        return nil
    }
}


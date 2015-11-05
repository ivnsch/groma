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
    func sortedByOrder() -> [ListItem] {
        let bySection = self.sort {($0.section.order <= $1.section.order)}.groupBySectionOrdered()
        
        var listItemsFlat: [ListItem] = []
        for section in bySection {
            for listItem in section.1 {
                listItemsFlat.append(listItem)
            }
        }
        
        return listItemsFlat
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
    
    func groupBySectionOrdered() -> OrderedDictionary<Section, [ListItem]> {
        var dictionary = OrderedDictionary<Section, [ListItem]>()
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
    
    var totalPrice: Float {
        return reduce(0) {price, listItem in
            price + listItem.totalPrice
        }
    }

    // Total price excluding stash
    var totalPriceTodoAndCart: Float {
        return reduce(0) {price, listItem in
            price + (listItem.status == .Stash ? 0 : listItem.totalPrice)
        }
    }

    var totalPriceDone: Float {
        return reduce(0) {price, listItem in
            price + (listItem.status == .Done ? listItem.totalPrice : 0)
        }
    }
    
    func filterDone() -> Array<Element> {
        return self.filter{$0.status == .Done}
    }
}


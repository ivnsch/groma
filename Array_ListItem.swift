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
    func sortedByOrder(status: ListItemStatus) -> [Element] {
        
        // src (sort by multiple criteria) http://stackoverflow.com/a/27596550/930450
        
        let result = sort {
            // for now disabled as this is e.g. overwrites the list item memory cache so we get no items in the cart or stash
            // TODO review this method, sorting in general - this is not fully defined yet
//        let result = self.filter{$0.hasStatus(status)}.sort {
            switch ($0.section.order(status), $1.section.order(status)) {
            case let (lhs,rhs) where lhs == rhs:
                return $0.order(status) < $1.order(status)
            case let (lhs, rhs):
                return lhs < rhs
            }
        }
        
        return result
    }
    
    mutating func sortAndUpdateOrderFieldsMutating(status: ListItemStatus) {
        
        self = filter{$0.hasStatus(status)}
        
        self = sortedByOrder(status)
        
        let orderedDict = groupBySectionOrdered()
        orderedDict.enumerate().forEach {index, sectionWithListItems in
            sectionWithListItems.0.updateOrderMutable(ListItemStatusOrder(status, index))
            
            sectionWithListItems.1.enumerate().forEach {index, listItem in
                listItem.updateOrderMutable(ListItemStatusOrder(status, index))
            }
        }
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
    
    func sectionCountDict(status: ListItemStatus) -> [Section: Int] {
        return filterStatus(status).groupBySection().map {($0, $1.count)}
    }
    
    func sectionCount(status: ListItemStatus) -> Int {
        
        let sectionsOfItemsWithStatus: [Section] = collect({
            if $0.hasStatus(status) {
                return $0.section
            } else {
                return nil
            }
        })
        
        return Set(sectionsOfItemsWithStatus).count
    }
    
    // How many list items with given section are in this array
    func count(section: Section) -> Int {
        var count = 0
        for listItem in self {
            if listItem.section.same(section) {
                count = count + 1
            }
        }
        return count
    }
    
    func sectionsInOrder(status: ListItemStatus) -> [Section] {
        var set: Set<Section> = Set<Section>()
        for listItem in self {
            set.insert(listItem.section)
        }
        return Array<Section>(set).inOrder(status)
    }
    
    func findFirstWithProductNameAndBrand(productName: String, brand: String) -> ListItem? {
        
        for listItem in self {
            if listItem.product.product.name == productName && listItem.product.product.brand == brand {
                return listItem
            }
        }
        return nil
    }
    
    func totalPrice(status: ListItemStatus) -> Float {
        return reduce(0) {price, listItem in
            price + listItem.totalPrice(status)
        }
    }

    func totalQuanityAndPrice(status: ListItemStatus) -> (quantity: Int, price: Float) {
        return reduce((0, 0)) {priceAndQuantity, listItem in
            (
                quantity: priceAndQuantity.0 + listItem.quantity(status),
                price: priceAndQuantity.1 + listItem.totalPrice(status)
            )
        }
    }
    
    // Total price excluding stash
    var totalPriceTodoAndCart: Float {
        return totalPrice(.Todo) + totalPrice(.Done)
    }
    
    func filterTodo() -> Array<Element> {
        return self.filter{$0.todoQuantity > 0}
    }
    
    func filterDone() -> Array<Element> {
        return self.filter{$0.doneQuantity > 0}
    }
    
    func filterStash() -> Array<Element> {
        return self.filter{$0.stashQuantity > 0}
    }
    
    func filterStatus(status: ListItemStatus) -> Array<Element> {
        return self.filter{$0.quantity(status) > 0}
    }
    
    mutating func removeWithUuid(uuid: String) -> ListItem? {
        for i in 0..<self.count {
            if self[i].uuid == uuid {
                let listItem = self[i]
                self.removeAtIndex(i)
                return listItem
            }
        }
        return nil
    }
    
    func hasSection(status: ListItemStatus, section: Section) -> Bool {
        return filterStatus(status).contains{$0.section.same(section)}
    }
}


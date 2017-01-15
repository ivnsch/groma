//
//  Array_ListItem.swift
//  shoppin
//
//  Created by ischuetz on 04/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

extension Array where Element: ListItem {
    
    /**
    Sorts increasingly by section and list item order
    */
    public func sortedByOrder(_ status: ListItemStatus) -> [Element] {
        
        // src (sort by multiple criteria) http://stackoverflow.com/a/27596550/930450
        
        let result = sorted {
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
    
    public mutating func sortAndUpdateOrderFieldsMutating(_ status: ListItemStatus) {
        
        self = filter{$0.hasStatus(status)}
        
        self = sortedByOrder(status)
        
        let orderedDict = groupBySectionOrdered()
        orderedDict.enumerated().forEach {index, sectionWithListItems in
            sectionWithListItems.1.section.updateOrderMutable(ListItemStatusOrder(status, index))
            
            sectionWithListItems.1.listItems.enumerated().forEach {index, listItem in
                listItem.updateOrderMutable(ListItemStatusOrder(status, index))
            }
        }
    }
    
    /**
    Group list items by list (note that the listitems inside each lists are ordered but the lists not)
    */
    public func groupByList() -> [String: [ListItem]] {
        var dictionary = [String: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.list.uuid] == nil {
                dictionary[listItem.list.uuid] = []
            }
            dictionary[listItem.list.uuid]?.append(listItem)
        }
        return dictionary
    }
    
    /**
    Group list items by section (note that the listitems inside each section are ordered but the sections not)
    */
    public func groupBySection() -> [String: [ListItem]] {
        var dictionary = [String: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.section.uuid] == nil {
                dictionary[listItem.section.uuid] = []
            }
            dictionary[listItem.section.uuid]?.append(listItem)
        }
        return dictionary
    }
    
    public func groupBySectionOrdered() -> OrderedDictionary<String, (section: Section, listItems: [ListItem])> {
        var dictionary = OrderedDictionary<String, (section: Section, listItems: [ListItem])>()
        for listItem in self {
            if dictionary[listItem.section.uuid] == nil {
                dictionary[listItem.section.uuid] = (section: listItem.section, listItems: [])
            }
            dictionary[listItem.section.uuid]?.listItems.append(listItem)
        }
        return dictionary
    }
    
    public func sectionCountDict(_ status: ListItemStatus) -> [String: Int] {
        return filterStatus(status).groupBySection().map {($0, $1.count)}
    }
    
    public func sectionCount(_ status: ListItemStatus) -> Int {
        
        let sectionsOfItemsWithStatus: [String] = collect({
            if $0.hasStatus(status) {
                return $0.section.uuid
            } else {
                return nil
            }
        })
        
        return Set(sectionsOfItemsWithStatus).count
    }
    
    // How many list items with given section are in this array
    public func count(_ section: Section) -> Int {
        var count = 0
        for listItem in self {
            if listItem.section.same(section) {
                count = count + 1
            }
        }
        return count
    }
    
    public func sectionsInOrder(_ status: ListItemStatus) -> [Section] {
        var set = Set<String>()
        var sections = [Section]()
        for listItem in self {
            if !set.contains(listItem.section.uuid) {
                set.insert(listItem.section.uuid)
                sections.append(listItem.section)
            }
        }
        return sections.inOrder(status)
    }
    
    // TODO!!!!!!!!!!!!!!! consider quantifiable product unique?
    public func findFirstWithProductNameAndBrand(_ productName: String, brand: String) -> ListItem? {
        
        for listItem in self {
            if listItem.product.product.product.name == productName && listItem.product.product.product.brand == brand {
                return listItem
            }
        }
        return nil
    }
    
    public func totalPrice(_ status: ListItemStatus) -> Float {
        return reduce(0) {price, listItem in
            price + listItem.totalPrice(status)
        }
    }

    public func totalQuanityAndPrice(_ status: ListItemStatus) -> (quantity: Int, price: Float) {
        return reduce((0, 0)) {priceAndQuantity, listItem in
            (
                quantity: priceAndQuantity.0 + listItem.quantity(status),
                price: priceAndQuantity.1 + listItem.totalPrice(status)
            )
        }
    }
    
    // Total price excluding stash
    public var totalPriceTodoAndCart: Float {
        return totalPrice(.todo) + totalPrice(.done)
    }
    
    public func filterTodo() -> Array<Element> {
        return self.filter{$0.todoQuantity > 0}
    }
    
    public func filterDone() -> Array<Element> {
        return self.filter{$0.doneQuantity > 0}
    }
    
    public func filterStash() -> Array<Element> {
        return self.filter{$0.stashQuantity > 0}
    }
    
    public func filterStatus(_ status: ListItemStatus) -> Array<Element> {
        return self.filter{$0.quantity(status) > 0}
    }
    
    public mutating func removeWithUuid(_ uuid: String) -> ListItem? {
        for i in 0..<self.count {
            if self[i].uuid == uuid {
                let listItem = self[i]
                self.remove(at: i)
                return listItem
            }
        }
        return nil
    }
    
    public func hasSection(_ status: ListItemStatus, section: Section) -> Bool {
        return filterStatus(status).contains{$0.section.same(section)}
    }
}



extension Results where T: ListItem {
    
    /**
     Sorts increasingly by section and list item order
     */
    public func sortedByOrder(_ status: ListItemStatus) -> [Element] {
        
        // src (sort by multiple criteria) http://stackoverflow.com/a/27596550/930450
        
        let result = sorted {
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
    
//    public mutating func sortAndUpdateOrderFieldsMutating(_ status: ListItemStatus) {
//        
//        self = filter{$0.hasStatus(status)}
//        
//        self = sortedByOrder(status)
//        
//        let orderedDict = groupBySectionOrdered()
//        orderedDict.enumerated().forEach {index, sectionWithListItems in
//            sectionWithListItems.1.section.updateOrderMutable(ListItemStatusOrder(status, index))
//            
//            sectionWithListItems.1.listItems.enumerated().forEach {index, listItem in
//                listItem.updateOrderMutable(ListItemStatusOrder(status, index))
//            }
//        }
//    }
    
    /**
     Group list items by list (note that the listitems inside each lists are ordered but the lists not)
     */
    public func groupByList() -> [String: [ListItem]] {
        var dictionary = [String: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.list.uuid] == nil {
                dictionary[listItem.list.uuid] = []
            }
            dictionary[listItem.list.uuid]?.append(listItem)
        }
        return dictionary
    }
    
    /**
     Group list items by section (note that the listitems inside each section are ordered but the sections not)
     */
    public func groupBySection() -> [String: [ListItem]] {
        var dictionary = [String: [ListItem]]()
        for listItem in self {
            if dictionary[listItem.section.uuid] == nil {
                dictionary[listItem.section.uuid] = []
            }
            dictionary[listItem.section.uuid]?.append(listItem)
        }
        return dictionary
    }
    
    public func groupBySectionOrdered() -> OrderedDictionary<String, (section: Section, listItems: [ListItem])> {
        var dictionary = OrderedDictionary<String, (section: Section, listItems: [ListItem])>()
        for listItem in self {
            if dictionary[listItem.section.uuid] == nil {
                dictionary[listItem.section.uuid] = (section: listItem.section, listItems: [])
            }
            dictionary[listItem.section.uuid]?.listItems.append(listItem)
        }
        return dictionary
    }
    
    public func sectionCountDict(_ status: ListItemStatus) -> [String: Int] {
        return filterStatus(status).groupBySection().map {($0, $1.count)}
    }
    
    public func sectionCount(_ status: ListItemStatus) -> Int {
        
        let sectionsOfItemsWithStatus: [String] = collect({
            if $0.hasStatus(status) {
                return $0.section.uuid
            } else {
                return nil
            }
        })
        
        return Set(sectionsOfItemsWithStatus).count
    }
    
    // How many list items with given section are in this array
    public func count(_ section: Section) -> Int {
        var count = 0
        for listItem in self {
            if listItem.section.same(section) {
                count = count + 1
            }
        }
        return count
    }
    
    public func sectionsInOrder(_ status: ListItemStatus) -> [Section] {
        var set = Set<String>()
        var sections = [Section]()
        for listItem in self {
            if !set.contains(listItem.section.uuid) {
                set.insert(listItem.section.uuid)
                sections.append(listItem.section)
            }
        }
        return sections.inOrder(status)
    }
    
    // TODO!!!!!!!!!!!!!! use quantifiable product unique (+unit related)
    public func findFirstWithProductNameAndBrand(_ productName: String, brand: String) -> ListItem? {
        
        for listItem in self {
            if listItem.product.product.product.name == productName && listItem.product.product.product.brand == brand {
                return listItem
            }
        }
        return nil
    }
    
    public func totalPrice(_ status: ListItemStatus) -> Float {
        return reduce(0) {price, listItem in
            price + listItem.totalPrice(status)
        }
    }
    
    public func totalQuanityAndPrice(_ status: ListItemStatus) -> (quantity: Int, price: Float) {
        return reduce((0, 0)) {priceAndQuantity, listItem in
            (
                quantity: priceAndQuantity.0 + listItem.quantity(status),
                price: priceAndQuantity.1 + listItem.totalPrice(status)
            )
        }
    }
    
    // Total price excluding stash
    public var totalPriceTodoAndCart: Float {
        return totalPrice(.todo) + totalPrice(.done)
    }
    
    public func filterTodo() -> Array<Element> {
        return self.filter{$0.todoQuantity > 0}
    }
    
    public func filterDone() -> Array<Element> {
        return self.filter{$0.doneQuantity > 0}
    }
    
    public func filterStash() -> Array<Element> {
        return self.filter{$0.stashQuantity > 0}
    }
    
    public func filterStatus(_ status: ListItemStatus) -> Array<Element> {
        return self.filter{$0.quantity(status) > 0}
    }
    
//    public mutating func removeWithUuid(_ uuid: String) -> ListItem? {
//        for i in 0..<self.count {
//            if self[i].uuid == uuid {
//                let listItem = self[i]
//                self.remove(at: i)
//                return listItem
//            }
//        }
//        return nil
//    }
    
    public func hasSection(_ status: ListItemStatus, section: Section) -> Bool {
        return filterStatus(status).contains{$0.section.same(section)}
    }
    
}

//
//  MemListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class MemListItemProvider {

    private var listItems = [List: [ListItem]]()
    
    private let enabled: Bool
    
    init(enabled: Bool = true) {
        self.enabled = enabled
    }
    
    func listItems(list: List) -> [ListItem]? {
        guard enabled else {return nil}
        
        return listItems[list]
    }
    
    func addListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] == nil {
            listItems[listItem.list] = []
        }
        listItems[listItem.list]?.append(listItem)
        return true
    }
    
    func removeListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] != nil {
            listItems[listItem.list]?.remove(listItem)
            return true
        } else {
            return false
        }
    }
    
    func updateListItem(listItem: ListItem) -> Bool {
        guard enabled else {return false}
        
        // TODO more elegant way to write this?
        if listItems[listItem.list] != nil {
            listItems[listItem.list]?.update(listItem)
            return true
        } else {
            return false
        }
    }

    func updateListItems(listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        
        for listItem in listItems {
            if !updateListItem(listItem) {
                return false
            }
        }
        return true
    }
    
    func overwrite(listItems: [ListItem]) -> Bool {
        guard enabled else {return false}
        
        invalidate()
        
        self.listItems = listItems.groupByList()
        
        return true
    }
    
    func invalidate() {
        guard enabled else {return}
        
        listItems = [List: [ListItem]]()
    }
}

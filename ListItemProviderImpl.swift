//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class ListItemProviderImpl:ListItemProvider {

    let cdProvider = CDListItemProvider()

    func products() -> [Product] {
        return self.cdProvider.loadProducts().map {ProductMapper.productWithCD($0)}
    }
    
    func listItems() -> [ListItem] {
        return self.cdProvider.loadListItems().map {ListItemMapper.listItemWithCD($0)}
    }
    
    func remove(listItem:ListItem) -> Bool {
        return self.cdProvider.remove(listItem)
    }
    
    func add(listItem:ListItem) -> ListItem? {
        // return the saved object, to get object with generated id
        if let cdListItem = self.cdProvider.saveListItem(listItem) {
            return ListItemMapper.listItemWithCD(cdListItem)
        } else {
            return nil
        }
    }
    
    func update(listItem:ListItem) -> Bool {
        return self.cdProvider.updateListItem(listItem) != nil
    }
    
    func sections() -> [Section] {
        return self.cdProvider.loadSections().map {
            return Section(name: $0.name)
        }
    }
}
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
    
    func listItems(list:List) -> [ListItem] {
        return self.cdProvider.loadListItems(list.id).map {ListItemMapper.listItemWithCD($0)}
    }
    
    func remove(listItem:ListItem) -> Bool {
        return self.cdProvider.remove(listItem)
    }
    
    func add(listItem:ListItem) -> ListItem? {
        // return the saved object, to get object with generated id
        let cdListItem = self.cdProvider.saveListItem(listItem)
        return ListItemMapper.listItemWithCD(cdListItem)
    }
    
    func updateDone(listItems:[ListItem]) -> Bool {
        return self.cdProvider.updateListItemsDone(listItems)
    }
    
    func update(listItem:ListItem) -> Bool {
        self.cdProvider.saveSection(listItem.section) // creates a new section if there isn't one already
        return self.cdProvider.updateListItem(listItem) != nil
    }
    
    func sections() -> [Section] {
        return self.cdProvider.loadSections().map {
            return Section(name: $0.name)
        }
    }
    
    func lists() -> [List] {
        return self.cdProvider.loadLists().map {ListMapper.listWithCD($0)}
    }
    
    func list(listId: String) -> List? {
        // return the saved object, to get object with generated id
        let cdList = self.cdProvider.loadList(listId)
        return ListMapper.listWithCD(cdList)
    }
    
    func add(list:List) -> List? {
        // return the saved object, to get object with generated id
        let list = self.cdProvider.saveList(list)
        return ListMapper.listWithCD(list)
    }
}
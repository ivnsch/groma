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
    
    func add(listItemInput:ListItemInput, list:List) -> ListItem? {
        // for now just create a new product and a listitem with it
        let product = Product(id: "dummy", name: listItemInput.name, price:listItemInput.price)
        let section = Section(name: listItemInput.section)
       
        let listItems = self.listItems(list)
        let order = listItems.count + 1
        
        // we use for now core data object id as list item id. So before we insert the item there's no id and it's not used -> "dummy"
        let listItem = ListItem(id:"dummy", done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
       
        return self.add(listItem)
    }
 
    func updateDone(listItems:[ListItem]) -> Bool {
        return self.cdProvider.updateListItemsDone(listItems)
    }
    
    func update(listItems:[ListItem]) -> Bool {
        return self.cdProvider.updateListItems(listItems) != nil
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
    
    var firstList:List {
        
        func createList(name:String) -> List {
            let list = List(id: "dummy", name: name)
            let savedList = self.add(list)
            PreferencesManager.savePreference(PreferencesManagerKey.listId, value: NSString(string: savedList!.id))
            return savedList!
        }

        var list:List
        if let listId:String = PreferencesManager.loadPreference(PreferencesManagerKey.listId) {
            list = self.list(listId)!
        } else {
            list = createList(Constants.defaultListIdentifier)
        }
        return list
    }
}
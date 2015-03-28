//
//  ListItemProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ListItemProviderMock: ListItemProvider {
    
    private var productsVar:[Product]
    private var listItemsVar:[ListItem]
    
    init() {
        self.productsVar = (0...20).map {
            Product(id: String($0), name: "product " + String($0), price:1.2)
        }
        
        let list:List = List(id: "test", name: "test")
        
        let i:Int = self.productsVar.count / 2
        let notDone = self.productsVar[0...i].map {ListItem(id: String(i), done: false, quantity: 1, product: $0, section: Section(name: "test"), list: list)}
        let done = self.productsVar[i...self.productsVar.count - 1].map {ListItem(id: String(i), done: true, quantity: 1, product: $0, section: Section(name: "test"), list: list)}
        self.listItemsVar = Array(notDone) + Array(done)
    }
    
    
    func listItems(list:List) -> [ListItem] {
        //TODO use list
        return self.listItemsVar
    }
    
    func products() -> [Product] {
        return self.productsVar
    }
    
    func remove(listItem:ListItem) -> Bool {
        if let index = find(self.listItemsVar, listItem) {
            listItemsVar.removeAtIndex(index)
        }
        return true
    }
    
    func add(listItem:ListItem) -> ListItem? {
        listItemsVar.append(listItem)
        return listItem
    }
    
    func add(listItemInput:ListItemInput, list:List) -> ListItem? {
        return nil
    }
    
    func sections() -> [Section] {
        return [Section(name: "test")]
    }
    
    func lists() -> [List] {
        //TODO
        return [List(id: "test", name: "test")]
    }

    func update(listItem:ListItem) -> Bool {
        //TODO?
        return true
    }
    
    func list(listId: String) -> List? {
        //TODO
        return List(id: listId, name: "test")
    }
    
    func add(list:List) -> List? {
        //TODO
        return nil
    }
    
    func updateDone(listItems:[ListItem]) -> Bool {
        //TODO
        return true
    }
}

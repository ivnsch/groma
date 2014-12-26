//
//  ListItemProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class ListItemProviderMock: ListItemProvider {
    
    private var productsVar:[Product]
    private var listItemsVar:[ListItem]
    
    init() {
        self.productsVar = (0...20).map {
            Product(name: "product " + String($0), price:1.2, quantity: 1)
        }
        
        let i:Int = self.productsVar.count / 2
        let notDone = self.productsVar[0...i].map {ListItem(id: String(i), done: false, product: $0, section: Section(name: "test"))}
        let done = self.productsVar[i...self.productsVar.count - 1].map {ListItem(id: String(i), done: true, product: $0, section: Section(name: "test"))}
        self.listItemsVar = Array(notDone) + Array(done)
    }
    
    
    func listItems() -> [ListItem] {
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
    
    func sections() -> [Section] {
        return [Section(name: "test")]
    }
    
    func update(listItem:ListItem) -> Bool {
        //TODO?
        return true
    }
}

//
//  ListItemProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemProviderMock: ListItemProvider {
    
    private(set) var productsVar:[Product] = []
    private(set) var sectionsVar:[Section] = []
    private(set) var listsVar:[List] = []
    private(set) var listItemsVar:[ListItem] = []
    
    init() {
        self.productsVar = (0...20).map {
            Product(uuid: String($0), name: "product " + String($0), price:1.2)
        }
        
        let section = Section(uuid: NSUUID().UUIDString, name: "test")
        self.sectionsVar.append(section)
        
        let list:List = List(uuid: NSUUID().UUIDString, name: Constants.defaultListIdentifier)
        self.listsVar.append(list)
        
        let i:Int = self.productsVar.count / 2
        
        func ranged<T>(arr:[T], interval:Range<Int>) -> ([T], Range<Int>) {
            return (Array(arr[interval]), interval)
        }
        
        func zipTuple<T>(tuple: ([T], Range<Int>)) -> Zip2<[T], Range<Int>> {
            return Zip2(tuple.0, tuple.1)
        }
        
        let notDone = Array(zipTuple(ranged(self.productsVar, 0...i))).map {product, index in
            ListItem(uuid: String(index), done: false, quantity: 1, product: product, section: section, list: list, order: index)
        }
        let done = Array(zipTuple(ranged(self.productsVar, i + 1...self.productsVar.count - 1))).map {product, index in
            ListItem(uuid: String(index), done: true, quantity: 1, product: product, section: section, list: list, order: index)
        }
        
        self.listItemsVar = Array(notDone) + Array(done)
    }
    
    func listItems(list: List, handler: Try<[ListItem]> -> ()) {
        handler(Try(self.listItemsVar))
    }
    
    func products(handler: Try<[Product]> -> ()) {
        handler(Try(self.productsVar))
    }
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {
        if let index = find(self.listItemsVar, listItem) {
            listItemsVar.removeAtIndex(index)
        }
        handler(Try(true))
    }
    
    func remove(section: Section, handler: Try<Bool> -> ()) {
        // TODO
        handler(Try(false))
    }
    func remove(list: List, handler: Try<Bool> -> ()) {
        // TODO
        handler(Try(false))
    }
    
    func add(listItem: ListItem, handler: Try<ListItem> -> ()) {
        self.listItemsVar.insert(listItem, atIndex: listItem.order)
        handler(Try(listItem))
    }
    
    func add(product:Product) -> Product? {
        self.productsVar.append(product)
        return product
    }
    
    func add(section:Section) -> Section? {
        self.sectionsVar.append(section)
        return section
    }
    
    private func maxId(ids:[String]) -> Int {
        var m = -1
        for id in ids {
            m = max(m, id.intValue)
        }
        return m
    }
    
    private func nextId(ids:[String]) -> Int {
        return self.maxId(ids) + 1
    }
    
    private func findProduct(name:String) -> Product? {
        return self.productsVar.findFirst{$0.name == name}
    }
    
    private func addFindProduct(#name:String, price:Float) -> Product {
        return self.findProduct(name) ?? {
            let product = Product(uuid: "", name: name, price: price)
            self.add(product)
            return product
        }()
    }
    
    private func findSection(name:String) -> Section? {
        return self.sectionsVar.findFirst{$0.name == name}
    }
    
    private func addFindSection(name: String) -> Section {
        return self.findSection(name) ?? {
            let section = Section(uuid: NSUUID().UUIDString, name: name)
            self.add(section)
            return section
        }()
    }
    
    func add(listItemInput:ListItemInput, list:List, order orderMaybe:Int?, handler: Try<ListItem> -> ()) {
        let product = addFindProduct(name: listItemInput.name, price: listItemInput.price)
        let section = Section(uuid: NSUUID().UUIDString, name: listItemInput.section)
        
        let idInt = self.nextId(self.listItemsVar.map{$0.uuid})
        let uuid = "\(idInt)"
        
        let order = orderMaybe ?? idInt
        
        let listItem = ListItem(uuid: uuid, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
        self.add(listItem, handler: handler)
    }
    
    func update(listItem: ListItem, handler: Try<Bool> -> ()) {
        //TODO
        handler(Try(true))
    }
    
    func update(listItems: [ListItem], handler: Try<Bool> -> ()) {
        //TODO
        handler(Try(true))
    }
    
    func sections(handler: Try<[Section]> -> ()) {
        handler(Try(self.sectionsVar))
    }
   
    func lists(handler: Try<[List]> -> ()) {
        handler(Try(self.listsVar))
    }
    
    func list(listUuid: String, handler: Try<List> -> ()) {
        if let list = (self.listsVar.findFirst{$0.uuid == listUuid}) {
            handler(Try(list))
        } else {
            handler(Try(NSError()))
        }
    }
    
    func add(list: List, handler: Try<List> -> ()) {
        //TODO
        handler(Try(list))
    }
    
    func updateDone(listItems:[ListItem], handler: Try<Bool> -> ()) {
        //TODO
        handler(Try(true))
    }
    
    func firstList(handler: Try<List> -> ()) {
        let list = self.listsVar.first!
        handler(Try(list))
    }
}

//
//  ListItemProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ListItemProviderMock: ListItemProvider {
    
    private(set) var productsVar:[Product] = []
    private(set) var sectionsVar:[Section] = []
    private(set) var listsVar:[List] = []
    private(set) var listItemsVar:[ListItem] = []
    
    init() {
        self.productsVar = (0...20).map {
            Product(id: String($0), name: "product " + String($0), price:1.2)
        }
        
        let section = Section(name: "test")
        self.sectionsVar.append(section)
        
        let list:List = List(id: "dummy", name: Constants.defaultListIdentifier)
        self.listsVar.append(list)
        
        let i:Int = self.productsVar.count / 2
        
        func ranged<T>(arr:[T], interval:Range<Int>) -> ([T], Range<Int>) {
            return (Array(arr[interval]), interval)
        }
        
        func zipTuple<T>(tuple: ([T], Range<Int>)) -> Zip2<[T], Range<Int>> {
            return Zip2(tuple.0, tuple.1)
        }
        
        let notDone = Array(zipTuple(ranged(self.productsVar, 0...i))).map {product, index in
            ListItem(id: String(index), done: false, quantity: 1, product: product, section: section, list: list, order: index)
        }
        let done = Array(zipTuple(ranged(self.productsVar, i + 1...self.productsVar.count - 1))).map {product, index in
            ListItem(id: String(index), done: true, quantity: 1, product: product, section: section, list: list, order: index)
        }
        
        self.listItemsVar = Array(notDone) + Array(done)
    }
    
    func listItems(list:List) -> [ListItem] {
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
    
    func remove(section:Section) -> Bool {
        // TODO
        return false
    }
    
    func add(listItem:ListItem) -> ListItem? {
        self.listItemsVar.insert(listItem, atIndex: listItem.order)
        return listItem
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
            let product = Product(id: "", name: name, price: price)
            self.add(product)
            return product
        }()
    }
    
    private func findSection(name:String) -> Section? {
        return self.sectionsVar.findFirst{$0.name == name}
    }
    
    private func addFindSection(name:String) -> Section {
        return self.findSection(name) ?? {
            let section = Section(name: name)
            self.add(section)
            return section
        }()
    }
    
    func add(listItemInput:ListItemInput, list:List, order orderMaybe:Int?) -> ListItem? {
        let product = addFindProduct(name: listItemInput.name, price: listItemInput.price)
        let section = Section(name: listItemInput.section)
        
        let idInt = self.nextId(self.listItemsVar.map{$0.id})
        let id = "\(idInt)"
        
        let order = orderMaybe ?? idInt
        
        let listItem = ListItem(id: id, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
        return self.add(listItem)
    }
    
    func update(listItem:ListItem) -> Bool {
        //TODO
        return true
    }
    
    func update(listItems:[ListItem]) -> Bool {
        //TODO
        return true
    }
    
    func sections() -> [Section] {
        return self.sectionsVar
    }
   
    func lists() -> [List] {
        return self.listsVar
    }
    
    func list(listId: String) -> List? {
        return self.listsVar.findFirst{$0.id == listId}
    }
    
    func add(list:List) -> List? {
        //TODO
        return nil
    }
    
    func updateDone(listItems:[ListItem]) -> Bool {
        //TODO
        return true
    }
    
    var firstList:List {
        return self.listsVar.first!
    }
}

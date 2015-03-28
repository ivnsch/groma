//
//  ListItemProviderMock.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ListItemProviderMock: ListItemProvider {
    
    private var productsVar:[Product] = []
    private var sectionsVar:[Section] = []
    private var listsVar:[List] = []
    private var listItemsVar:[ListItem] = []
    
    init() {
        self.productsVar = (0...20).map {
            Product(id: String($0), name: "product " + String($0), price:1.2)
        }
        
        let section = Section(name: "test")
        self.sectionsVar.append(section)
        
        let list:List = List(id: "test", name: "test")
        self.listsVar.append(list)
        
        let i:Int = self.productsVar.count / 2
        let notDone = self.productsVar[0...i].map {ListItem(id: String(i), done: false, quantity: 1, product: $0, section: section, list: list)}
        let done = self.productsVar[i...self.productsVar.count - 1].map {ListItem(id: String(i), done: true, quantity: 1, product: $0, section: section, list: list)}
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
    
    func add(listItem:ListItem) -> ListItem? {
        self.listItemsVar.append(listItem)
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
    
    private func maxId(identifiables:[Identifiable]) -> Float {
        var m:Float = FLT_MIN
        for item in identifiables {
            m = max(m, item.id.floatValue)
        }
        return m
    }
    
    private func nextId(identifiables:[Identifiable]) -> Float {
        return self.maxId(identifiables) + 1
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
    
    func add(listItemInput:ListItemInput, list:List) -> ListItem? {
        let product = addFindProduct(name: listItemInput.name, price: listItemInput.price)
        let section = Section(name: listItemInput.name)
       
        let id = "\(self.nextId(self.listItemsVar)))"
        
        let listItem = ListItem(id: id, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list)
        return listItem
    }
    
    func update(listItem:ListItem) -> Bool {
        //TODO?
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
}

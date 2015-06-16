//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class ListItemProviderImpl: ListItemProvider {

    let cdProvider = CDListItemProvider()

    func products(handler: Try<[Product]> -> ()) {
        self.cdProvider.loadProducts {result in
            if let products = result.success {
                handler(Try(products.map{ProductMapper.productWithCD($0)}))
            }
        }
    }
    
    func listItems(list: List, handler: Try<[ListItem]> -> ()) {
        
        self.cdProvider.loadListItems(list.id, handler: {try in
            
            if let cdListItems = try.success {
                let listItems = cdListItems.map{ListItemMapper.listItemWithCD($0)}
                handler(Try(listItems))
            }
        })
    }
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {

        self.cdProvider.remove(listItem, handler: {removed in
            handler(removed)
            
        })
        
//        return self.cdProvider.remove(listItem)
    }
    
    func remove(section:Section, handler: Try<Bool> -> ()) {
        return self.cdProvider.remove(section, handler: {removed in
            handler(removed)
        })
    }
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        return self.cdProvider.remove(list, handler: {removed in
            handler(removed)
        })
    }
    
    func add(listItem: ListItem, handler: Try<ListItem> -> ()) {
        // return the saved object, to get object with generated id
        self.cdProvider.saveListItem(listItem, handler: {try in
            if let cdListItem = try.success {
                let listItem = ListItemMapper.listItemWithCD(cdListItem)
                handler(Try(listItem))
            }
        })
    }
    
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int? = nil, handler: Try<ListItem> -> ()) {
        // for now just create a new product and a listitem with it
        let product = Product(id: NSUUID().UUIDString, name: listItemInput.name, price:listItemInput.price)
        // for now create a new section (TODO review this), server assigns new id if not existent yet or ignores
        let section = Section(id: NSUUID().UUIDString, name: listItemInput.section)
       
        self.listItems(list, handler: {try in // TODO fetch items only when order not passed, because they are used only to get order
            
            if let listItems = try.success {
                
                let order = orderMaybe ?? listItems.count
                
                let listItem = ListItem(id: NSUUID().UUIDString, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
                
                self.add(listItem, handler: {try in
                    handler(try)
                })
            }
        })
    }
 
    func updateDone(listItems: [ListItem], handler: Try<Bool> -> ()) {
        return self.cdProvider.updateListItemsDone(listItems, handler: {try in
            handler(try)
        })
    }
    
    func update(listItems: [ListItem], handler: Try<Bool> -> ()) {
        self.cdProvider.updateListItems(listItems, handler: {try in
            handler(Try(try.success != nil))
        })
//        return self.cdProvider.updateListItems(listItems) != nil
    }
    
    func update(listItem: ListItem, handler: Try<Bool> -> ()) {
        self.cdProvider.saveSection(listItem.section, handler: {try in

            if try.success != nil {
                self.cdProvider.updateListItem(listItem, handler: {try in
                    handler(Try(try.success != nil))
                })
            }
        }) // creates a new section if there isn't one already
    }
    
    func sections(handler: Try<[Section]> -> ()) {
        self.cdProvider.loadSections {result in
            if let sections = result.success {
                handler(Try(sections.map{Section(id: $0.id, name: $0.name)}))
            }
        }
    }
    
    func lists(handler: Try<[List]> -> ()) {
        self.cdProvider.loadLists{try in
            if let cdLists = try.success {
                let lists = cdLists.map {ListMapper.listWithCD($0)}
                handler(Try(lists))
            }
        }
    }
    
    func list(listId: String, handler: Try<List> -> ()) {
        // return the saved object, to get object with generated id
        self.cdProvider.loadList(listId, handler: {try in
            if let cdList = try.success {
                let list = ListMapper.listWithCD(cdList)
                handler(Try(list))
            }
        })
    }
    
    func add(list: List, handler: Try<List> -> ()) {
        // return the saved object, to get object with generated id
        self.cdProvider.saveList(list, handler: {try in
            if let cdList = try.success {
                let list = ListMapper.listWithCD(cdList)
                handler(Try(list))
            }
        })
    }
    
    func firstList(handler: Try<List> -> ()) {
        
        func createList(name: String, #handler: Try<List> -> ()) {
            let list = List(id: NSUUID().UUIDString, name: name)
            self.add(list, handler: {try in
                if let savedList = try.success {
                    PreferencesManager.savePreference(PreferencesManagerKey.listId, value: NSString(string: savedList.id))
                    handler(Try(savedList))
                }
            })
        }

        if let listId:String = PreferencesManager.loadPreference(PreferencesManagerKey.listId) {
            self.list(listId, handler: {try in
                if let list = try.success {
                    handler(Try(list))
                }

            })
            
        } else {
            createList(Constants.defaultListIdentifier, handler: {try in
                if let list = try.success {
                    handler(Try(list))
                }
            })
        }
    }
}
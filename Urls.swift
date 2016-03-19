//
//  Urls.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct Urls {

    static let hostIPPort: String = "192.168.0.20:9000"
    private static let host: String = "http://\(hostIPPort)/"

    static let productWithUnique = host + "productWithUnique"
    static let sectionWithUnique = host + "sectionWithUnique"
    static let sections = host + "sections"

    static let removeAll = host + "debug_clearAll"

    // Global
    static let sync = host + "sync"
    
    // User
    static let register = host + "register"
    static let isRegistered = host + "reg"
    static let forgotPassword = host + "forgot"
    static let login = host + "login"
    static let logout = host + "logout"
    static let removeAccount = host + "user"
    static let ping = host + "ping"
    static let authFacebook = host + "authenticate/facebook"
    static let authGoogle = host + "authenticate/google"
    
    // Lists
    static let lists = host + "lists"
    static let listsWithItemsSync = host + "lists/sync"
    static let listInvitation = host + "list/invitation"
    static let listsOrder = host + "lists/order"

    // List items
    static let listItems = host + "listItems"
    static let addListItem = host + "addListItem"
    static let addListItems = host + "addListItems" // TODO server
    static let listItem = host + "listItem"
    static let section = host + "section"
    static let list = host + "list"
    static let updateListItemsStatus = host + "listItems/ups"
    static let incrementListItem = host + "listItem/incr"
    static let listItemsSync = host + "listItem/sync"
    static let pullListProducts = host + "pullListProducts"
    
    // Inventory
    static let inventoryItems = host + "inventoryItems"
    static let inventory = host + "inventory"
    static let inventories = host + "inventories"
    static let inventoriesOrder = host + "inventories/order"
    static let inventorySync = host + "inventory/sync"
    static let inventoriesWithItemsSync = host + "inventories/sync"
    static let incrementInventoryItem = host + "inventoryItem/incr"
    static let inventoryItem = host + "inventoryItem"
    static let inventoryInvitation = host + "inventory/invitation"
    static let pullInventoryProducts = host + "pullInvProducts"

    // History
    static let historyItems = host + "historyItems"
    static let historyItemsSync = host + "historyItems/sync"
    static let historyItem = host + "historyItem"
    
    // Plan
    static let planItems = host + "planItems"
    static let planItem = host + "planItem"
    
    // Group
    static let groups = host + "groups"
    static let group = host + "group"
    static let groupItems = host + "groupItems"
    static let groupItem = host + "groupItem"
    static let incrementGroupItem = host + "groupItem/incr"
    
    // Product
    static let products = host + "products"
    static let product = host + "product"
    
    // Product category
    static let productCategories = host + "productCategories"
    static let productCategory = host + "productCategory"
    
    // Error report
    static let error = host + "errorRep"
}

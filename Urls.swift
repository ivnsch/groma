//
//  Urls.swift
//  shoppin
//
//  Created by ischuetz on 22/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct Urls {

    private static let host: String = "http://192.168.0.20:9000/"

    static let products = host + "products"
    static let productWithUnique = host + "productWithUnique"
    static let sectionWithUnique = host + "sectionWithUnique"
    static let listItems = host + "listItems"
    static let allListItems = host + "allListItems"
    static let sections = host + "sections"
    static let lists = host + "lists"

    static let addListItem = host + "addListItem"

    static let listItem = host + "listItem"
    static let section = host + "section"
    static let list = host + "list"

    static let removeAll = host + "debug_clearAll"
    
    static let register = host + "register"
    static let login = host + "login"
    static let logout = host + "logout"
    
    // Inventory
    static let inventory = host + "inventory"
}

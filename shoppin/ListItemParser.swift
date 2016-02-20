//
//  ListItemParser.swift
//  shoppin
//
//  Created by ischuetz on 29/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO!!!! failable initialisers maybe just use directly the remote classes in dispatcher and delete these websocket specific parser classes
class ListItemParser {

    class func parseProductCategory(json: AnyObject) -> ProductCategory {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        let colorStr = json.valueForKeyPath("color") as! String
        let color = UIColor(hexString: colorStr) ?? {
            print("Error: Invalid category color: \(colorStr)")
            return UIColor.blackColor()
        }()
        return ProductCategory(uuid: uuid, name: name, color: color)
    }
    
    class func parseProduct(json: AnyObject) -> Product {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        let price = json.valueForKeyPath("price") as! Float
        let categoryJson = json.valueForKeyPath("category")!
        let category = parseProductCategory(categoryJson)
        let baseQuantity = json.valueForKeyPath("baseQuantity") as! Float
        let unitInt = json.valueForKeyPath("unit") as! Int
        let unit = ProductUnit(rawValue: unitInt)!
        let brand = json.valueForKeyPath("brand") as! String
        return Product(uuid: uuid, name: name, price: price, category: category, baseQuantity: baseQuantity, unit: unit, brand: brand)
    }

    class func parseSection(json: AnyObject) -> Section {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        
        // TODO!!!! server
        let listJson = json.valueForKeyPath("list")!
        let list = parseList(listJson)
        
        let todoOrder = json.valueForKeyPath("todoOrder") as! Int
        let doneOrder = json.valueForKeyPath("doneOrder") as! Int
        let stashOrder = json.valueForKeyPath("stashOrder") as! Int
        return Section(uuid: uuid, name: name, list: list, todoOrder: todoOrder, doneOrder: doneOrder, stashOrder: stashOrder)
    }

    class func parseList(json: AnyObject) -> List {
        let lists = RemoteListsWithDependencies(representation: json)!
        let parsed = ListMapper.listsWithRemote(lists)
        return parsed.first!
    }

    class func parseArray(jsonArray: [AnyObject]) -> [ListItem] {
        var listItems: [ListItem] = []
        for json in jsonArray {
            listItems.append(parse(json))
        }
        return listItems
    }
    
    class func parse(json: AnyObject) -> ListItem {
        let uuid = json.valueForKeyPath("uuid") as! String
        
        let todoQuantity = json.valueForKeyPath("todoQuantity") as! Int
        let todoOrder = json.valueForKeyPath("todoOrder") as! Int
        let doneQuantity = json.valueForKeyPath("doneQuantity") as! Int
        let doneOrder = json.valueForKeyPath("doneOrder") as! Int
        let stashQuantity = json.valueForKeyPath("stashQuantity") as! Int
        let stashOrder = json.valueForKeyPath("stashOrder") as! Int
        
        let productJson = json.valueForKeyPath("productInput")!
        let product = parseProduct(productJson)

        let sectionJson = json.valueForKeyPath("sectionInput")!
        let section = parseSection(sectionJson)

//        let listJson = json.valueForKeyPath("list")!
//        let list = parseList(listJson)

        let listUuid = json.valueForKeyPath("listUuid") as! String
        let listName = json.valueForKeyPath("listName") as! String
        let listColor = UIColor.blackColor() // TODO
        let listOrder = 0 // TODO
        let inventory = Inventory(uuid: "123", name: "123 TODO", users: [], bgColor: UIColor.blackColor(), order: 0) // TODO!!!
        let list = List(uuid: listUuid, name: listName, listItems: [], users: [], bgColor: listColor, order: listOrder, inventory: inventory)
        
//        let order = json.valueForKeyPath("order") as! Int
        let note = json.valueForKeyPath("note") as! String
//        let lastUpdate = NSDate(timeIntervalSince1970: json.valueForKeyPath("lastUpdate") as! Double)
        
        return ListItem(uuid: uuid, product: product, section: section, list: list, note: note, todoQuantity: todoQuantity, todoOrder: todoOrder, doneQuantity: doneQuantity, doneOrder: doneOrder, stashQuantity: stashQuantity, stashOrder: stashOrder
        )
    }
}
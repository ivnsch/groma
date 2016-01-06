//
//  ListItemParser.swift
//  shoppin
//
//  Created by ischuetz on 29/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

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
        return Product(uuid: uuid, name: name, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
    }

    class func parseSection(json: AnyObject) -> Section {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        let order = json.valueForKeyPath("order") as! Int
        return Section(uuid: uuid, name: name, order: order)
    }

    class func parseList(json: AnyObject) -> List {
        let uuid = json.valueForKeyPath("uuid") as! String
        let name = json.valueForKeyPath("name") as! String
        let order = json.valueForKeyPath("order") as! Int
        let bgColor = UIColor.blackColor() // TODO
        let inventoryJson = json.valueForKeyPath("inventory")!
        let inventory = WSInventoryParser.parseInventory(inventoryJson)
        return List(uuid: uuid, name: name, listItems: [], users: [], bgColor: bgColor, order: order, inventory: inventory)
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
        let statusInt = json.valueForKeyPath("status") as! Int
        let status = ListItemStatus(rawValue: statusInt)!
        let quantity = json.valueForKeyPath("quantity") as! Int
        
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
        
        let order = json.valueForKeyPath("order") as! Int
        let note = json.valueForKeyPath("note") as! String? // TODO is this correct way for optional here?
//        let lastUpdate = NSDate(timeIntervalSince1970: json.valueForKeyPath("lastUpdate") as! Double)
        
        return ListItem(uuid: uuid, status: status, quantity: quantity, product: product, section: section, list: list, order: order, note: note)
    }
}
//
//  RemoteGroup.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteGroup: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let lastUpdate: NSDate
    let order: Int
    let color: UIColor
    let fav: Int
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.name = representation.valueForKeyPath("name") as! String
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)
        self.order = representation.valueForKeyPath("order") as! Int
        let colorStr = representation.valueForKeyPath("color") as! String
        self.color = UIColor(hexString: colorStr) ?? {
            print("Error: RemoteList.init: Invalid color hex: \(colorStr)")
            return UIColor.blackColor()
        }()
        self.fav = representation.valueForKeyPath("fav") as! Int
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteGroup] {
        var items = [RemoteGroup]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroup(response: response, representation: obj) {
                items.append(item)
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), color: \(color.hexStr), lastUpdate: \(lastUpdate), fav: \(fav)}"
    }
}
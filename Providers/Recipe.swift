//
//  ProductGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RecipesContainer: Object { // to be able to hold recipes in realm's list
    
    let recipes: RealmSwift.List<Recipe> = RealmSwift.List<Recipe>()
}

public class Recipe: Object, Identifiable {
    
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var bgColorHex: String = "000000"
    @objc public dynamic var fav: Int = 0
    @objc public dynamic var text: String = ""

    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }
    
    public convenience init(uuid: String, name: String, color: UIColor, fav: Int = 0, text: String = "") {
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.color = color
        self.fav = fav
        self.text = text
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterName(_ name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterUuids(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "uuid IN {\(uuidsStr)}"
    }
    
    // MARK: - Update
    

    public override static func ignoredProperties() -> [String] {
        return ["color"]
    }
    
    public func same(_ rhs: Recipe) -> Bool {
        return uuid == rhs.uuid
    }
    
    public override var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), bgColor: \(color.hexStr), fav: \(fav)}"
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, bgColor: UIColor? = nil, fav: Int? = nil, text: String? = nil) -> Recipe {
        return Recipe(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            color: bgColor ?? self.color,
            fav: fav ?? self.fav,
            text: text ?? self.text
        )
    }
}

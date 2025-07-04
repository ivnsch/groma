//
//  ProductGroup.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class Recipe: Object, Identifiable, WithUuid {
    
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var bgColorHex: String = "000000"
    @objc public dynamic var fav: Int = 0
    @objc public dynamic var text: String = ""
    public var textAttributeSpans = RealmSwift.List<DBTextSpan>()

    public var color: UIColor {
        get {
            return UIColor(hexString: bgColorHex)
        }
        set {
            bgColorHex = newValue.hexStr
        }
    }

    public convenience init(uuid: String, name: String, color: UIColor, fav: Int = 0, text: String = "", spans: [TextSpan]) {
        let dbSpans = spans.map { span in
            DBTextSpan(start: span.start, length: span.length, attribute: span.attribute.rawValue)
        }
        self.init(uuid: uuid, name: name, color: color, fav: fav, text: text, spans: dbSpans)
    }

    public convenience init(uuid: String, name: String, color: UIColor, fav: Int = 0, text: String = "", spans: [DBTextSpan]) {
        self.init(uuid: uuid, name: name, color: color, fav: fav, text: text)
        for span in spans {
            textAttributeSpans.append(span)
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

    static func createFilter(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }

    static func createFilterName(_ name: String) -> NSPredicate {
        return NSPredicate(format: "name = %@", name)
    }
    
    static func createFilterNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "name CONTAINS[c] %@", text)
    }
    
    static func createFilterUuids(_ uuids: [String]) -> NSPredicate {
        return NSPredicate(format: "uuid IN %@", uuids)
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

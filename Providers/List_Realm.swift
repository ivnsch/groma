//
//  List2.swift
//  shoppin
//
//  Created by Ivan Schütz on 07/12/2016.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

extension RealmSwift.List {
    
    // TODO
//    convenience init(_ array: [T]) {
//        self.init()
//        add(array)
//    }
    
    public func add(_ array: [Element]) {
        for element in array {
            self.append(element)
        }
    }
    
    public func toArray() -> [Element] {
        return self.map{$0}
    }
    
    public static func list(_ array: [Element]) -> RealmSwift.List<Element> {
        let l = RealmSwift.List<Element>()
        for element in array {
            l.append(element)
        }
        return l
    }

    public func remove(_ obj: Element) -> Bool {
        if let index = index(of: obj) {
            remove(at: index)
            return true
        }
        return false
    }
}

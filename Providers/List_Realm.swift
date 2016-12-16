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
    
    public func add(_ array: [T]) {
        for element in array {
            self.append(element)
        }
    }
    
    public func toArray() -> [T] {
        return self.map{$0}
    }
    
    public static func list(_ array: [T]) -> RealmSwift.List<T> {
        let l = RealmSwift.List<T>()
        for element in array {
            l.append(element)
        }
        return l
    }
}

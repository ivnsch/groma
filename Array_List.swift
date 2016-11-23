//
//  Array_List.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: List {

    /**
    Sorts increasingly by order
    */
    func sortedByOrder() -> [List] {
        return sorted {
            switch ($0.order, $1.order) {
            case let (lhs, rhs) where lhs == rhs: // this should normally not happen, but just in case, get a fixed ordering anyway
                return $0.name < $1.name
            case let (lhs, rhs):
                return lhs < rhs
            }
        }
    }
    
    func equalsExcludingSyncAttributes(_ rhs: [List]) -> Bool {
        guard self.count == rhs.count else {return false}
        for i in 0..<self.count {
            let list = self[i]
            let otherList = rhs[i]
            if !list.equalsExcludingSyncAttributes(otherList) {
                return false
            }
        }
        return true
    }
}

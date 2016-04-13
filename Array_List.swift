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
        return self.sort {$0.order <= $1.order}
    }
    
    func equalsExcludingSyncAttributes(rhs: [List]) -> Bool {
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
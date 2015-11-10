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
}
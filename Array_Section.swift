//
//  Array_Section.swift
//  shoppin
//
//  Created by ischuetz on 02/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

extension Array where Element: Section {

    func inOrder(status: ListItemStatus) -> [Section] {
        return sort {$0.order(status) < $1.order(status)}
    }
}
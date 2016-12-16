//
//  Array_Section.swift
//  shoppin
//
//  Created by ischuetz on 02/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array where Element: Section {

    public func inOrder(_ status: ListItemStatus) -> [Section] {
        return sorted {$0.order(status) < $1.order(status)}
    }
}

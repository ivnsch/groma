//
//  Identifiable.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public protocol Identifiable {
    
    /**
    If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
    */
    func same(_ rhs: Self) -> Bool
}

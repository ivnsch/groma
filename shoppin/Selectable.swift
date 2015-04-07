//
//  Selectable.swift
//  shoppin
//
//  Created by ischuetz on 07/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class Selectable<T> {
    
    let model: T
    let selected: Bool
    
    init(model: T, selected: Bool = false) {
        self.model = model
        self.selected = selected
    }
}

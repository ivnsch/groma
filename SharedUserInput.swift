//
//  SharedUserInput.swift
//  shoppin
//
//  Created by ischuetz on 10/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// For now this is used only when adding/editting lists. Review structure/rename if we use shared users for something else (e.g. inventory)
class SharedUserInput {
   
    let email: String
    
    init(email: String) {
        self.email = email
    }
}

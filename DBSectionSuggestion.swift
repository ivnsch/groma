//
//  DBSectionSuggestion.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBSectionSuggestion: Object {
    
    dynamic var name: String = ""
    
    override static func primaryKey() -> String? {
        return "name"
    }
}

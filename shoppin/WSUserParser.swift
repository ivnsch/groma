//
//  WSUserParser.swift
//  shoppin
//
//  Created by ischuetz on 10/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct WSUserParser {
    
    static func parseSharedUser(json: AnyObject) -> SharedUser {
        let email = json.valueForKeyPath("email") as! String
        return SharedUser(email: email)
    }
}

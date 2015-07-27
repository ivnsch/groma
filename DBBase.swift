//
//  DBBase.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBBase: Object {
    dynamic var lastUpdated: NSDate = NSDate()
}

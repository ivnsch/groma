//
//  shoppin.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

@objc(CDProduct)
class CDProduct: NSManagedObject {
    @NSManaged var uuid: String
    @NSManaged var name: String
    @NSManaged var price: NSNumber

}

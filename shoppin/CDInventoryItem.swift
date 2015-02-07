//
//  CDInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

@objc(CDInventoryItem)
class CDInventoryItem: NSManagedObject {

    @NSManaged var quantity: NSNumber
    @NSManaged var product: CDProduct

}

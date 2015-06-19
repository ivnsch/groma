//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 07.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

@objc(CDListItem)
class CDListItem: NSManagedObject {

    @NSManaged var uuid: String
    @NSManaged var done: Bool
    @NSManaged var quantity: NSNumber
    @NSManaged var section: CDSection
    @NSManaged var product: CDProduct
    @NSManaged var list: CDList
    @NSManaged var order: NSNumber
}

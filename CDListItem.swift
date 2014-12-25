//
//  ListItem.swift
//  shoppin
//
//  Created by ischuetz on 07.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

class CDListItem: NSManagedObject {

    @NSManaged var done: Bool
    @NSManaged var section: shoppin.CDSection
    @NSManaged var product: shoppin.CDProduct

}

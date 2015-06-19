//
//  CDSection.swift
//  shoppin
//
//  Created by ischuetz on 23.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

@objc(CDSection)
class CDSection: NSManagedObject {

    @NSManaged var uuid: String
    @NSManaged var name: String
    @NSManaged var listItem: NSSet

}

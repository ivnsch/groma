//
//  CDList.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

@objc(CDList)
class CDList: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var listItems: NSSet

}

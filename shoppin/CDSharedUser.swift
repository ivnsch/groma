//
//  CDSharedUser.swift
//  
//
//  Created by ischuetz on 08/07/15.
//
//

import Foundation
import CoreData

class CDSharedUser: NSManagedObject {

    @NSManaged var email: String
    @NSManaged var uuid: String
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var list: CDList

}

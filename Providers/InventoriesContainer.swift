//
//  InventoriesContainer.swift
//  Providers
//
//  Created by Ivan Schuetz on 06/02/2017.
//
//

import UIKit
import RealmSwift

class InventoriesContainer: Object {
    
    var inventories = RealmSwift.List<DBInventory>()
}

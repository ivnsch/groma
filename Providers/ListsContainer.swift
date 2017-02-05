//
//  ListsContainer.swift
//  Providers
//
//  Created by Ivan Schuetz on 05/02/2017.
//
//

import UIKit
import RealmSwift

class ListsContainer: Object {
    
    var lists = RealmSwift.List<List>()
}

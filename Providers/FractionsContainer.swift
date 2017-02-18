//
//  FractionsContainer.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import UIKit
import RealmSwift

class FractionsContainer: Object {
    
    var fractions = RealmSwift.List<DBFraction>()
}

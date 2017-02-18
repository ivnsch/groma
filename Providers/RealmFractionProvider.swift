//
//  RealmFractionProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class RealmFractionProvider: RealmProvider {

    func fractions() -> RealmSwift.List<DBFraction>? {
        guard let fractionsContainer: FractionsContainer = loadSync(predicate: nil)?.first else {
            QL4("Invalid state: no container")
            return nil
        }
        return fractionsContainer.fractions
    }
    
    func findFraction(numerator: Int, denominator: Int) -> DBFraction? {
        return withRealmSync {realm in
            return realm.objects(DBFraction.self).filter(DBFraction.createFilter(numerator: numerator, denominator: denominator)).first
        }
    }
    
    func add(fraction: DBFraction) -> (success: Bool, isNew: Bool) {

        if findFraction(numerator: fraction.numerator, denominator: fraction.denominator) != nil {
            return (true, false)
            
        } else {
            guard let fractionsContainer: FractionsContainer = loadSync(predicate: nil)?.first else {
                QL4("Invalid state: no container")
                return (false, false)
            }
            
            let successMaybe = doInWriteTransactionSync {realm -> Bool in
                realm.add(fraction, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
                fractionsContainer.fractions.append(fraction)
                return true
            }
            return successMaybe.map{($0, true)} ?? (false, true)
        }
    }
    
    func remove(fraction: DBFraction) -> Bool {
        let successMaybe = doInWriteTransactionSync {realm -> Bool in
            realm.delete(realm.objects(DBFraction.self).filter(DBFraction.createFilter(fraction: fraction)))
            return true
        }
        return successMaybe ?? false
    }
}

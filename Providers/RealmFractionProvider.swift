//
//  RealmFractionProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 18/02/2017.
//
//

import UIKit
import RealmSwift


class RealmFractionProvider: RealmProvider {

    func fractions() -> RealmSwift.List<DBFraction>? {
        guard let fractionsContainer: FractionsContainer = loadSync(predicate: nil)?.first else {
            logger.e("Invalid state: no container")
            return nil
        }
        return fractionsContainer.fractions
    }
    
    func findFraction(numerator: Int, denominator: Int) -> DBFraction? {
        return withRealmSync {realm in
            return realm.objects(DBFraction.self).filter(DBFraction.createFilter(numerator: numerator, denominator: denominator)).first
        }
    }
    
    func add(fraction: DBFraction, doTransaction: Bool = true) -> (success: Bool, isNew: Bool) {

        if findFraction(numerator: fraction.numerator, denominator: fraction.denominator) != nil {
            return (true, false)
            
        } else {
            guard let fractionsContainer: FractionsContainer = loadSync(predicate: nil)?.first else {
                logger.e("Invalid state: no container")
                return (false, false)
            }

            func transactionContent(realm: Realm) -> Bool {
                realm.add(fraction, update: true) // it's necessary to do this additionally to append, see http://stackoverflow.com/a/40595430/930450
                fractionsContainer.fractions.append(fraction)
                return true
            }

            let successMaybe: Bool? = {
                if doTransaction {
                    return doInWriteTransactionSync { realm -> Bool in
                        return transactionContent(realm: realm)
                    }
                } else {
                    do {
                        let realm = try RealmConfig.realm()
                        return transactionContent(realm: realm)
                    } catch (let e) {
                        logger.e("Couldn't create realm: \(e)", .db)
                        return false
                    }
                }
            } ()

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

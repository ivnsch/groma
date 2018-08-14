//
// Created by Ivan Schuetz on 15.08.18.
//

import XCTest
import RealmSwift
@testable import Providers

protocol ResultMatches {
    func getTestResultWithOneObject<T: Object>(predicate: NSPredicate) -> T
}

extension ResultMatches where Self: RealmTestCase {
    func getTestResultWithOneObject<T: Object>(predicate: NSPredicate) -> T {
        let results = testRealm.objects(T.self).filter(predicate)
        XCTAssert(results.count == 1)
        return results[0]
    }
}

//
// Created by Ivan Schuetz on 15.08.18.
//

import XCTest
import RealmSwift
@testable import Providers

protocol EmptyOrInvalidResultsTest {

    associatedtype ObjectType: Object

    func testEmptyOrInvalidResults(filter: NSPredicate)
}

extension EmptyOrInvalidResultsTest where Self: RealmTestCase {

    func testEmptyOrInvalidResults(filter: NSPredicate) {
        let results = realm.objects(ObjectType.self).filter(filter)
        XCTAssert(results.count == 0)
        XCTAssert(results.isEmpty)
    }
}

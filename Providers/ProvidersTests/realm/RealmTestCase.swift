//
//  WithTestRealm.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 14.08.18.
//

import XCTest
import RealmSwift
@testable import Providers

class RealmTestCase: XCTestCase {

    fileprivate var documentsDirectoryUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }

    lazy var realm: Realm = self.createRealm()

    fileprivate func createRealm() -> Realm {
        let documentsDirectory = documentsDirectoryUrl
        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            try! FileManager.default.createDirectory(atPath: documentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
        }
        let realmUrl = documentsDirectoryUrl.appendingPathComponent("testRealm.realm")

        print("Test Realm path: \(realmUrl)")
        return try! Realm(fileURL: realmUrl)
    }

    override func setUp() {
        super.setUp()

        RealmConfig.setTestConfiguration()

        // Put setup code here. This method is called before the invocation of each test method in the class.
        clearRealm()
    }

    // Ensure all db state is empty
    fileprivate func clearRealm() {
        realm.beginWrite()
        realm.deleteAll()
        try! realm.commitWrite()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        clearRealm()
        super.tearDown()
    }

}

//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class ListItemsSectionsTests: RealmTestCase {

    fileprivate let provider = RealmSectionProviderSync()

    func testLoadSectionWithUnique() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let result1 = provider.loadSectionWithUnique(obj1.unique)
        XCTAssertNotNil(result1)
        EqualityTests.equals(obj1: result1!, obj2: obj1)

        let result2 = provider.loadSectionWithUnique(obj2.unique)
        XCTAssertNotNil(result2)
        EqualityTests.equals(obj1: result2!, obj2: obj2)
    }

    func testLoadSectionWithName() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let result1 = provider.loadSection(obj1.name, list: obj1.list)
        XCTAssertNotNil(result1)
        EqualityTests.equals(obj1: result1!, obj2: obj1)

        let result2 = provider.loadSection(obj2.name, list: obj2.list)
        XCTAssertNotNil(result2)
        EqualityTests.equals(obj1: result2!, obj2: obj2)
    }

    func testLoadSections() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let provResult: ProvResult<Results<Section>, DatabaseError> = provider.loadSections([obj1.name, obj2.name], list: obj1.list)
        XCTAssertTrue(provResult.isOk)
        let results = provResult.getOk()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
    }

    func testLoadSectionsFromAllListsByName() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let results1 = provider.loadSections(obj1.name)
        XCTAssertNotNil(results1!)
        XCTAssertEqual(results1!.count, 1)
        EqualityTests.equals(obj1: results1![0], obj2: obj1)

        let results2 = provider.loadSections(obj2.name)
        XCTAssertNotNil(results2!)
        XCTAssertEqual(results2!.count, 1)
        EqualityTests.equals(obj1: results2![0], obj2: obj2)
    }

    func testSaveTodoSections() {
        // Prepare
        realm.beginWrite()
        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)
        let list = List(uuid: uuid(), name: "list", users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store1")
        realm.add(list)
        try! realm.commitWrite()
        let obj1 = Section(name: "section1", color: UIColor.red, list: list, status: .todo)
        let obj2 = Section(name: "section2", color: UIColor.blue, list: list, status: .todo)

        // Test
        let success = provider.saveSections([obj1, obj2])
        XCTAssertTrue(success)

        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
    }

    func testSaveDoneSections() {
        // Prepare
        realm.beginWrite()
        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)
        let list = List(uuid: uuid(), name: "list", users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store1")
        realm.add(list)
        try! realm.commitWrite()
        let obj1 = Section(name: "section1", color: UIColor.red, list: list, status: .done)
        let obj2 = Section(name: "section2", color: UIColor.blue, list: list, status: .done)

        // Test
        let success = provider.saveSections([obj1, obj2])
        XCTAssertTrue(success)

        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
    }

    func testSaveTodoAndDoneSections() {
        // Prepare
        realm.beginWrite()
        let inventory = DBInventory(uuid: uuid(), name: "inventory", users: [], bgColor: UIColor.black, order: 0)
        realm.add(inventory)
        let list = List(uuid: uuid(), name: "list", users: [], color: UIColor.red, order: 0, inventory: inventory, store: "store1")
        realm.add(list)
        try! realm.commitWrite()
        let obj1 = Section(name: "section1", color: UIColor.red, list: list, status: .todo)
        let obj2 = Section(name: "section2", color: UIColor.blue, list: list, status: .done)

        // Test
        let success = provider.saveSections([obj1, obj2])
        XCTAssertTrue(success)

        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: obj1)
        EqualityTests.equals(obj1: results![1], obj2: obj2)
    }

    func testRemoveSection() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let success = provider.remove(obj1, notificationTokens: [], markForSync: false)
        XCTAssertTrue(success)
        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj2)

        // TODO test dependencies (list items) removal
    }

    func testRemoveSectionByUnique() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let success = provider.remove(obj1.unique, notificationTokens: [], markForSync: false)
        XCTAssertTrue(success)
        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 1)
        EqualityTests.equals(obj1: results![0], obj2: obj2)

        // TODO test dependencies (list items) removal
    }

    func testUpdateSection() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let input = SectionInput(name: "new name", color: UIColor.purple)
        let updatedSection = provider.update(obj1, input: input)
        XCTAssertNotNil(updatedSection)
        XCTAssertEqual(updatedSection!.name, input.name)
        // XCTAssertEqual(updatedSection!.color, input.color) // the (ui)colors diverge a little, why?
        XCTAssertEqual(updatedSection!.bgColorHex, input.color.hexStr)

        let results = provider.loadAllSections()
        XCTAssertNotNil(results)
        XCTAssertEqual(results!.count, 2)
        EqualityTests.equals(obj1: results![0], obj2: updatedSection!)
    }

    func testSectionSuggestionsContainingText() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        realm.beginWrite()
        let anotherSection = Section(name: "foo1", color: UIColor.red, list: obj1.list, status: .done)
        realm.add(anotherSection)
        let category1 = ProductCategory(uuid: uuid(), name: "foo2", color: UIColor.red)
        realm.add(category1)
        let category2 = ProductCategory(uuid: uuid(), name: "foo3", color: UIColor.blue)
        realm.add(category2)
        try! realm.commitWrite()

        // Test
        let suggestions1 = provider.sectionSuggestionsContainingText("obj")
        XCTAssertEqual(suggestions1.count, 2)
        XCTAssertEqual(suggestions1[0], obj1.name)
        XCTAssertEqual(suggestions1[1], obj2.name)

        let suggestions2 = provider.sectionSuggestionsContainingText("fo")
        XCTAssertEqual(suggestions2.count, 3)
        XCTAssertEqual(suggestions2[0], anotherSection.name)
        XCTAssertEqual(suggestions2[1], category1.name)
        XCTAssertEqual(suggestions2[2], category2.name)
    }

    func testRemoveSectionIfEmpty() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2ListItems(realm: realm, status: .todo)

        // TODO - when list item provider is sync - remove list items - check that sections are removed too

        // Test
    }

    func testMergeOrCreateTodoSectionUpdate() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)
        let newColor = UIColor.yellow
        let mergeResult = provider.mergeOrCreateSection(obj1.name,
                                      sectionColor: newColor,
                                      overwriteColorIfAlreadyExists: true,
                                      status: .todo,
                                      list: obj1.list,
                                      realmData: nil,
                                      doTransaction: true)

        // Test
        XCTAssertTrue(mergeResult.isOk)
        XCTAssertNotNil(mergeResult.getOk())
        XCTAssertEqual(mergeResult.getOk()!.section, obj1)
        // Update obj1 to compare with the  updated result
        let updatedObj1 = obj1.copy(color: newColor)
        EqualityTests.equals(obj1: mergeResult.getOk()!.section, obj2: updatedObj1)
    }

    func testMergeOrCreateDoneSectionUpdate() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .done)
        let newColor = UIColor.yellow
        let mergeResult = provider.mergeOrCreateSection(obj1.name,
                                                        sectionColor: newColor,
                                                        list: obj1.list,
                                                        status: .done,
                                                        realmData: nil,
                                                        doTransaction: true)

        // Test
        XCTAssertTrue(mergeResult.isOk)
        XCTAssertNotNil(mergeResult.getOk())
        XCTAssertEqual(mergeResult.getOk()!.section, obj1)
        // Update obj1 to compare with the  updated result
        let updatedObj1 = obj1.copy(color: newColor)
        EqualityTests.equals(obj1: mergeResult.getOk()!.section, obj2: updatedObj1)
    }

    func testMergeOrCreateTodoSectionCreate() {
        // TODO
    }

    func testMergeOrCreateDoneSectionCreate() {
        // TODO
    }

    func testMergeOrCreateTodoSectionCalledWithDoneReturnsError() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)
        let newColor = UIColor.yellow
        let mergeResult = provider.mergeOrCreateSection(obj1.name,
                                                        sectionColor: newColor,
                                                        overwriteColorIfAlreadyExists: true,
                                                        status: .done,
                                                        list: obj1.list,
                                                        realmData: nil,
                                                        doTransaction: true)

        // Test
        XCTAssertTrue(mergeResult.isErr)
        XCTAssertNil(mergeResult.getOk())
        XCTAssertEqual(mergeResult.getErr(), DatabaseError.invalidInput)
    }

    func testMergeOrCreateDoneSectionCalledWithTodoReturnsError() {
        // Prepare
        let (obj1, _) = DummyTestObjects.insert2Sections(realm: realm, status: .done)
        let newColor = UIColor.yellow
        let mergeResult = provider.mergeOrCreateSection(obj1.name,
                                                        sectionColor: newColor,
                                                        list: obj1.list,
                                                        status: .todo,
                                                        realmData: nil,
                                                        doTransaction: true)

        // Test
        XCTAssertTrue(mergeResult.isErr)
        XCTAssertNil(mergeResult.getOk())
        XCTAssertEqual(mergeResult.getErr(), DatabaseError.invalidInput)
    }
    // TODO test above method when the sections to be updated have wrong status too

    func testMoveSection() {
        // TODO
    }

    func testGetOrCreateTodo() {
        // TODO
    }

    func testGetSections() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Sections(realm: realm, status: .todo)

        // Test
        let sections = provider.sections(list: obj1.list, status: .todo)
        XCTAssertNotNil(sections)
        XCTAssertEqual(sections!.count, 2)
        XCTAssertEqual(sections![0], obj1)
        XCTAssertEqual(sections![1], obj2)
    }


    // TODO more tests - current methods are done but need corner cases etc
}

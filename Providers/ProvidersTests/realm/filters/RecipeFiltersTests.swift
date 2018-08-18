//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
@testable import Providers

class RecipeFiltersTests: RealmTestCase, ResultMatches, EmptyOrInvalidResultsTest {
    typealias ObjectType = Recipe

    // MARK: - Basic

    func testUuidFilter() {
        // Prepare
        let (recipe1, recipe2) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilter(recipe1.uuid)), obj2: recipe1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilter(recipe2.uuid)), obj2: recipe2)
    }

    func testNameFilter() {
        // Prepare
        let (recipe1, recipe2) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilterName(recipe1.name)), obj2: recipe1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilterName(recipe2.name)), obj2: recipe2)
    }

    func testNameInvalidCharsFilter() {
        // Prepare
        let (obj1, obj2) = DummyTestObjects.insert2Recipes(realm: realm, specialCharsName: true)

        // Test
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilterName(obj1.name)), obj2: obj1)
        EqualityTests.equals(obj1: getTestResultWithOneObject(predicate: Recipe.createFilterName(obj2.name)), obj2: obj2)
    }

    // MARK: -

    func testUuidFilterEmpty() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Recipe.createFilter(nonExistentString))
    }

    func testNameFilterEmpty() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Recipe.createFilterName(nonExistentString))
    }

    func testUuidFilterInvalidChars() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Recipe.createFilter(specialCharsTestString))
    }

    func testNameFilterInvalidChars() {
        // Prepare
        let (_, _) = DummyTestObjects.insert2Recipes(realm: realm)

        // Test
        testEmptyOrInvalidResults(filter: Recipe.createFilterName(specialCharsTestString))
    }
}

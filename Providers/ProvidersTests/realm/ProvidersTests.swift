//
//  ProvidersTests.swift
//  ProvidersTests
//
//  Created by Ivan Schuetz on 07.01.18.
//

import XCTest
import RealmSwift
//import Providers
@testable import Providers

// TODO Move these tests to new class "RealmMigrationTests"
class ProvidersTests: XCTestCase {

    let srcRealm = try! Realm(fileURL: ProvidersTests.localRealmUrl(fileName: "srcRealm.realm"))
    let dstRealm = try! Realm(fileURL: ProvidersTests.localRealmUrl(fileName: "targetRealm.realm"))

    fileprivate static var documentsDirectoryUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }

    fileprivate static func localRealmUrl(fileName: String) -> URL {
        return documentsDirectoryUrl.appendingPathComponent(fileName)
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        clearRealms()
    }

    // Ensure all db state is empty
    fileprivate func clearRealms() {
        srcRealm.beginWrite()
        srcRealm.deleteAll()
        try! srcRealm.commitWrite()
        dstRealm.beginWrite()
        dstRealm.deleteAll()
        try! dstRealm.commitWrite()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        clearRealms()
        super.tearDown()
    }

    func testDeleteAll() {
        let realm = try! Realm(fileURL: ProvidersTests.localRealmUrl(fileName: "myrealm.realm"))

        realm.beginWrite()
        let firstCategory = ProductCategory(uuid: "1", name: "foo", color: "#000000")
        realm.add(firstCategory)
        realm.add(ProductCategory(uuid: "2", name: "bar", color: "#000000"))
        realm.add(Item(uuid: "1", name: "foo", category: firstCategory, fav: 0))
        realm.add(Providers.Unit(uuid: "1", name: "foo", id: .none, buyable: false))
        try! realm.commitWrite()

        XCTAssert(realm.objects(ProductCategory.self).count == 2)
        XCTAssert(realm.objects(Item.self).count == 1)
        XCTAssert(realm.objects(Providers.Unit.self).count == 1)

        realm.beginWrite()
        realm.deleteAll()
        try! realm.commitWrite()

        XCTAssert(realm.objects(ProductCategory.self).count == 0)
        XCTAssert(realm.objects(Item.self).count == 0)
        XCTAssert(realm.objects(Providers.Unit.self).count == 0)
        XCTAssert(realm.isEmpty)
    }

    fileprivate func extractAllItems(quantifiableProducts: [QuantifiableProduct]) -> [Item] {
        let items = quantifiableProducts.map { $0.product.item }
        return Array(Set(items))
    }

    fileprivate func extractAllProducts(quantifiableProducts: [QuantifiableProduct]) -> [Product] {
        let products = quantifiableProducts.map { $0.product }
        return Array(Set(products))
    }

    func testFullMigration() {

        let realm = srcRealm

        //////////////////////////////////////////////////////////////////////////////////////
        // Add stuff
        //////////////////////////////////////////////////////////////////////////////////////

        realm.beginWrite()

        // Get containers

        let listsContainer = ListsContainer()
        realm.add(listsContainer)
        let inventoriesContainer = InventoriesContainer()
        realm.add(inventoriesContainer)
        let recipesContainer = RecipesContainer()
        realm.add(recipesContainer)
        let unitsContainer = UnitsContainer()
        realm.add(unitsContainer)
        let baseQuantitiesContainer = BaseQuantitiesContainer()
        realm.add(baseQuantitiesContainer)
        let fractionsContainer = FractionsContainer()
        realm.add(fractionsContainer)

        // Add units
        let units = RealmUnitProvider().predefinedUnits
        realm.add(units)
        unitsContainer.units.add(units)

        // Add base quantities
        let baseQuantities = RealmUnitProvider().defaultBaseQuantities
        var inputDbBaseQuantities: [BaseQuantity] = []
        for base in baseQuantities {
            let dbBase = BaseQuantity(base)
            inputDbBaseQuantities.append(dbBase)
            realm.add(dbBase)
            baseQuantitiesContainer.bases.append(dbBase)
        }

        // Add fractions
        let fractions = RealmUnitProvider().defaultFractions
        var inputDbFractions: [DBFraction] = []
        for fraction in fractions {
            let dbFraction = DBFraction(numerator: fraction.numerator, denominator: fraction.denominator)
            inputDbFractions.append(dbFraction)
            realm.add(dbFraction)
            fractionsContainer.fractions.append(dbFraction)
        }

        // Add categories and quantifiable products (which adds items and products as well)
        let prefiller = SuggestionsPrefiller()
        let (categories, quantifiableProducts) = prefiller.prefillProducts("en", defaultUnits: units, trFunction: { key, lang in
            return key // just use the translation key as name
        })
        for category in categories {
            realm.add(category, update: false)
        }
        for quantifiableProduct in quantifiableProducts {
            realm.add(quantifiableProduct, update: false)
        }

        // Add inventory
        let inventory = DBInventory(uuid: UUID().uuidString, name: "my inventory", bgColor: UIColor.blue, order: 0)
        realm.add(inventory)
        let inventories = [inventory]
        inventoriesContainer.inventories.add([inventory])

        // Add some inventory items
        let inventoryItem1 = InventoryItem(uuid: "1", quantity: 1, product: quantifiableProducts[0], inventory: inventories[0])
        let inventoryItem2 = InventoryItem(uuid: "2", quantity: 1, product: quantifiableProducts[0], inventory: inventories[0])
        let inventoryItems = [inventoryItem1, inventoryItem2]
        realm.add(inventoryItems)

        // Add list
        let list = List(uuid: UUID().uuidString, name: "my list", color: UIColor.orange, order: 0, inventory: inventory, store: nil)
        realm.add(list)
        let lists = [list]
        listsContainer.lists.add([list])

        // Add some store products
        let sp1 = StoreProduct(uuid: "1", refPrice: 1, refQuantity: 1, product: quantifiableProducts[0])
        let sp2 = StoreProduct(uuid: "2", refPrice: 2, refQuantity: 2, product: quantifiableProducts[1])
        let sp3 = StoreProduct(uuid: "3", refPrice: 3, refQuantity: 3, product: quantifiableProducts[2])
        let storeProducts = [sp1, sp2, sp3]
        for storeProduct in storeProducts {
            realm.add(storeProduct)
        }

        // Add some sections
        let section1 = Section(name: "section1", color: UIColor.blue, list: list, order: ListItemStatusOrder(status: .todo, order: 0), status: .todo)
        let section2 = Section(name: "section2", color: UIColor.red, list: list, order: ListItemStatusOrder(status: .done, order: 0), status: .done)
        let sections = [section1, section2]
        for section in sections {
            realm.add(section)
        }
        let todoSections = [section1]
        let doneSections = [section2]
        list.todoSections.add(todoSections)

        // Add some list items
        let listItem1 = ListItem(uuid: "1", product: sp1, section: section1, list: list, note: "note1", quantity: 1)
        let listItem2 = ListItem(uuid: "2", product: sp2, section: section1, list: list, note: "note2", quantity: 2)
        let listItem3 = ListItem(uuid: "3", product: sp3, section: section2, list: list, note: "note3", quantity: 3)
        let listItems = [listItem1, listItem2, listItem3]
        for listItem in listItems {
            realm.add(listItem)
        }
        let todoListItems = [listItem1, listItem2]
        let doneListItems = [listItem3]
        section1.listItems.add(todoListItems)
        section2.listItems.add(doneListItems)
        list.doneListItems.add(doneListItems) // this causes a EXC_BAD_ACCESS in RLMObjectBase.maybeInitObjectSchemaForUnmanaged, no idea why. Also when commenting `section2.listItems.add(doneListItems)` TODO find reason / fix?

        // Add some history items
        let sharedUser = DBSharedUser(email: "")
        let historyItem1 = HistoryItem(uuid: "1", inventory: inventory, product: quantifiableProducts[0], addedDate: Date().toMillis(), quantity: 1, user: sharedUser, paidPrice: 1)
        let historyItem2 = HistoryItem(uuid: "2", inventory: inventory, product: quantifiableProducts[1], addedDate: Date().toMillis(), quantity: 2, user: sharedUser, paidPrice: 2)
        let historyItem3 = HistoryItem(uuid: "4", inventory: inventory, product: quantifiableProducts[2], addedDate: Date().toMillis(), quantity: 3, user: sharedUser, paidPrice: 3)
        let historyItems = [historyItem1, historyItem2, historyItem3]
        for historyItem in historyItems {
            realm.add(historyItem)
        }

        // Add text spans
        let textSpan1 = DBTextSpan(start: 0, length: 3, attribute: TextAttribute.bold.rawValue)
        let textSpan2 = DBTextSpan(start: 4, length: 10, attribute: TextAttribute.bold.rawValue)
        let textSpans = [textSpan1, textSpan2]
        realm.add(textSpans, update: false)

        // Add Recipe
        let recipe = Recipe(uuid: UUID().uuidString, name: "my recipe", color: UIColor.blue, fav: 2, text: "foo bar", spans: textSpans)
        realm.add(recipe)
        let recipes = [recipe]
        recipesContainer.recipes.add([recipe])

        // Add some ingredients
        let item = quantifiableProducts[0].product.item
        let ingredient1 = Ingredient(uuid: "1", quantity: 1, fraction: fractions[0], unit: units[0], item: item, recipe: recipe)
        let ingredient2 = Ingredient(uuid: "2", quantity: 1, fraction: fractions[0], unit: units[0], item: item, recipe: recipe)
        let ingredient3 = Ingredient(uuid: "3", quantity: 1, fraction: fractions[0], unit: units[0], item: item, recipe: recipe)
        let ingredients = [ingredient1, ingredient2, ingredient3]
        realm.add(ingredients)

        try! realm.commitWrite()

        //////////////////////////////////////////////////////////////////////////////////////
        // Read added stuff and check that everything is as expected
        //////////////////////////////////////////////////////////////////////////////////////

        func testResultState(realm: Realm) {

            // Containers
            let listsContainers = realm.objects(ListsContainer.self)
            XCTAssertEqual(listsContainers.count, 1)
            let inventoriesContainers = realm.objects(InventoriesContainer.self)
            XCTAssertEqual(inventoriesContainers.count, 1)
            let recipesContainers = realm.objects(RecipesContainer.self)
            XCTAssertEqual(recipesContainers.count, 1)
            let unitsContainers = realm.objects(UnitsContainer.self)
            XCTAssertEqual(unitsContainers.count, 1)
            let baseQuantitiesContainers = realm.objects(BaseQuantitiesContainer.self)
            XCTAssertEqual(baseQuantitiesContainers.count, 1)
            let fractionsContainers = realm.objects(FractionsContainer.self)
            XCTAssertEqual(fractionsContainers.count, 1)

            // Units
            let dbUnits = realm.objects(Unit.self)
            XCTAssertEqual(dbUnits.count, units.count)
            EqualityTests.equals(arr1: units.sortedByUuid(), arr2: dbUnits.toArray().sortedByUuid())
            XCTAssertEqual(unitsContainers.first!.units.count, units.count)
            EqualityTests.equals(arr1: units.sortedByUuid(), arr2: unitsContainers.first!.units.toArray().sortedByUuid())

            // Base quantities
            let dbBaseQuantities = realm.objects(BaseQuantity.self)
            XCTAssertEqual(dbBaseQuantities.count, baseQuantities.count)
            EqualityTests.equals(arr1: inputDbBaseQuantities.sortedByVal(), arr2: dbBaseQuantities.toArray().sortedByVal())
            XCTAssertEqual(baseQuantitiesContainers.first!.bases.count, baseQuantities.count)
            EqualityTests.equals(arr1: inputDbBaseQuantities.sortedByVal(), arr2: baseQuantitiesContainers.first!.bases.toArray().sortedByVal())

            // Items
            let items = extractAllItems(quantifiableProducts: quantifiableProducts)
            let dbItems = realm.objects(Item.self)
            XCTAssertEqual(dbItems.count, items.count)
            EqualityTests.equals(arr1: items.sortedByUuid(), arr2: dbItems.toArray().sortedByUuid())

            // Categories
            let dbCategories = realm.objects(ProductCategory.self)
            XCTAssertEqual(dbCategories.count, categories.count)
            EqualityTests.equals(arr1: categories.sortedByUuid(), arr2: dbCategories.toArray().sortedByUuid())

            // Products
            let products = extractAllProducts(quantifiableProducts: quantifiableProducts)
            let dbProducts = realm.objects(Product.self)
            XCTAssertEqual(dbProducts.count, products.count)
            EqualityTests.equals(arr1: products.sortedByUuid(), arr2: dbProducts.toArray().sortedByUuid())

            // Quantifiable products
            let dbQuantifiableProducts = realm.objects(QuantifiableProduct.self)
            XCTAssertEqual(dbQuantifiableProducts.count, quantifiableProducts.count)
            EqualityTests.equals(arr1: quantifiableProducts.sortedByUuid(), arr2: dbQuantifiableProducts.toArray().sortedByUuid())

            // Store products
            let dbStoreProducts = realm.objects(StoreProduct.self)
            XCTAssertEqual(dbStoreProducts.count, storeProducts.count)
            EqualityTests.equals(arr1: storeProducts.sortedByUuid(), arr2: dbStoreProducts.toArray().sortedByUuid())

            // Inventories
            let dbInventories = realm.objects(DBInventory.self)
            XCTAssertEqual(dbInventories.count, 1)
            EqualityTests.equals(arr1: [inventory].sortedByUuid(), arr2: dbInventories.toArray().sortedByUuid())

            // Inventory items
            let dbInventoryItems = realm.objects(InventoryItem.self)
            XCTAssertEqual(dbInventoryItems.count, inventoryItems.count)
            EqualityTests.equals(arr1: inventoryItems.sortedByUuid(), arr2: dbInventoryItems.toArray().sortedByUuid())

            // Lists
            let dbLists = realm.objects(List.self)
            XCTAssertEqual(dbLists.count, 1)
            EqualityTests.equals(arr1: lists.sortedByUuid(), arr2: dbLists.toArray().sortedByUuid())
            XCTAssertEqual(listsContainers.first!.lists.count, lists.count)
            EqualityTests.equals(arr1: lists.sortedByUuid(), arr2: listsContainers.first!.lists.toArray().sortedByUuid())

            // Sections
            let dbSections = realm.objects(Section.self)
            XCTAssertEqual(dbSections.count, sections.count)
            EqualityTests.equals(arr1: sections.sortedByName(), arr2: dbSections.toArray().sortedByName())
            XCTAssertEqual(lists.first!.todoSections.count, todoSections.count)
            EqualityTests.equals(arr1: lists.first!.todoSections.toArray().sortedByName(), arr2: todoSections.sortedByName())
            let dbTodoSections = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: lists.first!.uuid, status: .todo))

            XCTAssertEqual(dbTodoSections.count, todoSections.count)
            EqualityTests.equals(arr1: dbTodoSections.toArray().sortedByName(), arr2: todoSections.sortedByName())
            let dbDoneSections = realm.objects(Section.self).filter(Section.createFilterListStatus(listUuid: lists.first!.uuid, status: .done))
            XCTAssertEqual(dbDoneSections.count, doneSections.count)
            EqualityTests.equals(arr1: dbDoneSections.toArray().sortedByName(), arr2: doneSections.sortedByName())

            // List items
            let dbListItems = realm.objects(ListItem.self)
            XCTAssertEqual(dbListItems.count, listItems.count)
            EqualityTests.equals(arr1: listItems.sortedByUuid(), arr2: dbListItems.toArray().sortedByUuid(), compareLists: true)
//            XCTAssertEqual(lists.first!.doneListItems.count, 1) // See todo on commented code adding list item, to see why this is commented
            EqualityTests.equals(arr1: lists.first!.doneListItems.toArray().sortedByUuid(), arr2: doneListItems.sortedByUuid(), compareLists: true)
            EqualityTests.equals(arr1: dbTodoSections.first!.listItems.toArray().sortedByUuid(), arr2: todoListItems.sortedByUuid(), compareLists: true)
            EqualityTests.equals(arr1: dbDoneSections.first!.listItems.toArray().sortedByUuid(), arr2: doneListItems.sortedByUuid(), compareLists: true)

            // History items
            let dbHistoryItems = realm.objects(HistoryItem.self)
            XCTAssertEqual(dbHistoryItems.count, historyItems.count)
            EqualityTests.equals(arr1: historyItems.sortedByUuid(), arr2: dbHistoryItems.toArray().sortedByUuid())

            // Recipes
            let dbRecipes = realm.objects(Recipe.self)
            XCTAssertEqual(dbRecipes.count, 1)
            EqualityTests.equals(arr1: recipes.sortedByUuid(), arr2: dbRecipes.toArray().sortedByUuid())
            XCTAssertEqual(recipesContainers.first!.recipes.count, recipes.count)
            EqualityTests.equals(arr1: recipes.sortedByUuid(), arr2: recipesContainers.first!.recipes.toArray().sortedByUuid())

            // Text spans
            let dbTextSpans = realm.objects(DBTextSpan.self)
            XCTAssertEqual(dbTextSpans.count, textSpans.count)
            EqualityTests.equals(arr1: textSpans.sortedByStart(), arr2: dbTextSpans.toArray().sortedByStart())

            // Ingredients
            let dbIngredients = realm.objects(Ingredient.self)
            XCTAssertEqual(dbIngredients.count, ingredients.count)
            EqualityTests.equals1(arr1: ingredients.sortedByUuid(), arr2: dbIngredients.toArray().sortedByUuid())
        }

        // Check src realm state is as expected
        testResultState(realm: realm)

        // Ensure dst realm is empty
        XCTAssert(dstRealm.isEmpty)

        // Copy src realm in dst realm
        RealmGlobalProvider().migrate(srcRealm: srcRealm, targetRealm: dstRealm)

        // Verify dst realm has same state
        testResultState(realm: dstRealm)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

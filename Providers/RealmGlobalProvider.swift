    //
//  RealmGlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

    
class RealmGlobalProvider: RealmProvider {

    // TODO map db objects directly to dicts, mapping to our plain objects is not necessary
    func loadGlobalSync(_ isMatchSync: Bool, handler: @escaping ([String: AnyObject]?) -> Void) {
        
        withRealm({realm in

            let productCategories = realm.objects(ProductCategory.self).filter(ProductCategory.createFilterDirtyAndValid())
            let products = realm.objects(Product.self).filter(Product.createFilterDirtyAndValid())
            let storeProducts = realm.objects(StoreProduct.self).filter(StoreProduct.createFilterDirtyAndValid())
            let lists = realm.objects(List.self).filter(DBSyncable.dirtyFilter())
            let sections = realm.objects(Section.self).filter(DBSyncable.dirtyFilter())
            let listsItems = realm.objects(ListItem.self).filter(DBSyncable.dirtyFilter())
            let inventories = realm.objects(DBInventory.self).filter(DBSyncable.dirtyFilter())
            let inventoryItems = realm.objects(InventoryItem.self).filter(DBSyncable.dirtyFilter())
            let groups = realm.objects(ProductGroup.self).filter(DBSyncable.dirtyFilter())
            let groupItems = realm.objects(GroupItem.self).filter(DBSyncable.dirtyFilter())
            let history = realm.objects(HistoryItem.self).filter(DBSyncable.dirtyFilter())

            let categoriesToSync = productCategories.map{$0.toDict()}
            let productsToSync = products.map{$0.toDict()}
            let storeProductsToSync = storeProducts.map{$0.toDict()}
            let listsToSync = lists.map{$0.toDict()}
            let sectionsToSync = sections.map{$0.toDict()}
            let listItemsToSync = listsItems.map{$0.toDict()}
            
            // For inventory we need to filter out inventories where I'm not authorised, otherwise the sync fails. The reason we have these inventories in the client is that they can be referenced by lists. A participant of a list doesn't necessarily have access to its associated inventory. But the list references it so we store it in "read only mode" (note that this is only about the inventory object, we of course don't get its items).
            let inventoriesToSync = inventories.filter{inventory in
                let sharedUsers = Array(inventory.users.map{SharedUserMapper.sharedUserWithDB($0)})
                // for now allow empty participants, this should be the case when the inventory was never shared (TODO confirm. If in all possible cases is guaranteed that the inventory has shared users we can remove this).
                return sharedUsers.isEmpty || sharedUsers.containsMe()
            }.map{$0.toDict()}
            let inventoryItemsToSync = inventoryItems.map{$0.toDict()}
            let groupsToSync = groups.map{$0.toDict()}
            let groupItemsToSync = groupItems.map{$0.toDict()}
            let historyToSync = history.map{$0.toDict()}
            
            let categoriesToRemove = realm.objects(DBRemoveProductCategory.self).map{$0.toDict()}
            let productsToRemove = realm.objects(ProductToRemove.self).map{$0.toDict()}
            let storeProductsToRemove = realm.objects(StoreProductToRemove.self).map{$0.toDict()}
            let listsToRemove = realm.objects(DBRemoveList.self).map{$0.toDict()}
            let sectionsToRemove = realm.objects(SectionToRemove.self).map{$0.toDict()}
            let listItemsToRemove = realm.objects(DBRemoveListItem.self).map{$0.toDict()}
            let inventoriesToRemove = realm.objects(DBRemoveInventory.self).map{$0.toDict()}
            let inventoryItemsToRemove = realm.objects(DBRemoveInventoryItem.self).map{$0.toDict()}
            let groupsToRemove = realm.objects(DBRemoveProductGroup.self).map{$0.toDict()}
            let groupItemsToRemove = realm.objects(DBRemoveGroupItem.self).map{$0.toDict()}
            let historyToRemove = realm.objects(DBRemoveHistoryItem.self).map{$0.toDict()}
            
            let categoriesDict = ["categories": categoriesToSync as AnyObject, "toRemove": categoriesToRemove as AnyObject]
            let productsDict = ["products": productsToSync as AnyObject, "toRemove": productsToRemove as AnyObject]
            let storeProductsDict = ["storeProducts": storeProductsToSync as AnyObject, "toRemove": storeProductsToRemove as AnyObject]
            let listsDict = ["lists": listsToSync as AnyObject, "toRemove": listsToRemove as AnyObject]
            let sectionsDict = ["sections": sectionsToSync as AnyObject, "toRemove": sectionsToRemove as AnyObject]
            let listItemsDict = ["listItems": listItemsToSync as AnyObject, "toRemove": listItemsToRemove as AnyObject]
            let inventoriesDict = ["inventories": inventoriesToSync as AnyObject, "toRemove": inventoriesToRemove as AnyObject]
            let inventoryItemsDict = ["inventoryItems": inventoryItemsToSync as AnyObject, "toRemove": inventoryItemsToRemove as AnyObject]
            let gropsDict = ["groups": groupsToSync as AnyObject, "toRemove": groupsToRemove as AnyObject]
            let groupItemsDict = ["groupItems": groupItemsToSync as AnyObject, "toRemove": groupItemsToRemove as AnyObject]
            let historyDict = ["historyItems": historyToSync as AnyObject, "toRemove": historyToRemove as AnyObject]
            
            var syncDict = [String: AnyObject]()
            syncDict["productCategories"] = categoriesDict as AnyObject
            syncDict["products"] = productsDict as AnyObject
            syncDict["storeProducts"] = storeProductsDict as AnyObject
            syncDict["lists"] = listsDict as AnyObject
            syncDict["sections"] = sectionsDict as AnyObject
            syncDict["listItems"] = listItemsDict as AnyObject
            syncDict["inventories"] = inventoriesDict as AnyObject
            syncDict["inventoryItems"] = inventoryItemsDict as AnyObject
            syncDict["groups"] = gropsDict as AnyObject
            syncDict["groupsItems"] = groupItemsDict as AnyObject
            syncDict["history"] = historyDict as AnyObject
            
            syncDict["isMatch"] = isMatchSync as AnyObject
            
            return syncDict
            
            }) { (globalSyncMaybe: [String: AnyObject]?) -> Void in
                if let globalSync = globalSyncMaybe {
                    handler(globalSync)
                    
                } else {
                    print("Error: RealmGlobalProvider.loadGlobalSync: couldn't load global sync.")
                    handler(nil)
                }
        }
    }
    
    func saveSyncResult(_ syncResult: RemoteSyncResult, handler: @escaping (Bool) -> Void) {
        handler(true)
        
        
        // Commented because structural changes
        
//        // Maps an array of dictionaries(object representations from server) to an array of objects T by applying mapper to each dictionary
//        // Returns, together with the array also a dictionary which maps a unique identifier of the object to the object, for quick access.
//        func toObjs<T: DBSyncable>(_ dictArray: [[String: AnyObject]], mapper: ([String: AnyObject]) -> T, idExtractor: (T) -> String) -> ([T], [String: T]) {
//            var objArray = [T]()
//            var objDict = [String: T]()
//            for dict in dictArray {
//                let element = mapper(dict)
//                objArray.append(element)
//                objDict[idExtractor(element)] = element
//            }
//            return (objArray, objDict)
//        }
//        
//        doInWriteTransaction({[weak self] realm in
//
//            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
//            // TODO!!!! write this code with proper optional handling and error logging
//            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
//            
//            let (productCategoriesArr, productCategoriesDict): ([ProductCategory], [String: ProductCategory]) = toObjs(syncResult.productCategories, mapper: {ProductCategory.fromDict($0)}, idExtractor: {$0.uuid})
//            
//            let (productsArr, productsDict): ([Product], [String: Product]) = toObjs(syncResult.products, mapper: {Product.fromDict($0, category: productCategoriesDict[$0["categoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//
//            let (storeProductsArr, storeProductsDict): ([StoreProduct], [String: StoreProduct]) = toObjs(syncResult.storeProducts, mapper: {StoreProduct.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//
//            let (inventoriesArr, inventoriesDict): ([DBInventory], [String: DBInventory]) = toObjs(syncResult.inventories, mapper: {DBInventory.fromDict($0)}, idExtractor: {$0.uuid})
//            
//            let (inventoryItemsArr, inventoryItemsDict): ([InventoryItem], [String: InventoryItem]) = toObjs(syncResult.inventoriesItems, mapper: {InventoryItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//            
//            let (listsArr, listsDict): ([List], [String: List]) = toObjs(syncResult.lists, mapper: {List.fromDict($0, inventory: inventoriesDict[$0["list"]!["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//            
//            let (sectionsArr, sectionsDict): ([Section], [String: Section]) = toObjs(syncResult.sections, mapper: {Section.fromDict($0, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//            
//            let (listItemsArr, listItemsDict): ([ListItem], [String: ListItem]) = toObjs(syncResult.listsItems, mapper: {ListItem.fromDict($0, section: sectionsDict[$0["sectionUuid"]! as! String]!, product: storeProductsDict[$0["storeProductUuid"]! as! String]!, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//            
//            //        // TODO!!!! set BOTH group in groups items and group items in group Realm needs both set to save correctly ............ this is needed also for lists and inventories probably
//            let (groupsArr, groupsDict): ([ProductGroup], [String: ProductGroup]) = toObjs(syncResult.groups, mapper: {ProductGroup.fromDict($0)}, idExtractor: {$0.uuid})
//            let (groupItemsArr, groupItemsDict): ([GroupItem], [String: GroupItem]) = toObjs(syncResult.groupsItems, mapper: {GroupItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, group: groupsDict[$0["groupUuid"]! as! String]!)}, idExtractor: {$0.uuid})
//            
//            let (historyItemsArr, historyItemsDict): ([HistoryItem], [String: HistoryItem]) = toObjs(syncResult.history, mapper: {HistoryItem.fromDict($0, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!, product: productsDict[$0["productUuid"] as! String]!)}, idExtractor: {$0.uuid})
//            
//            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
//            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
//            
//            self?.clearAllDataSync(realm)
//            
//            func saveObjs(_ objs: [Object]) {
//                for obj in objs {
//                    realm.add(obj, update: true)
//                }
//            }
//            saveObjs(productCategoriesArr)
//            saveObjs(productsArr)
//            saveObjs(storeProductsArr)
//            saveObjs(sectionsArr)
//            saveObjs(inventoriesArr)
//            saveObjs(inventoryItemsArr)
//            saveObjs(listsArr)
//            saveObjs(listItemsArr)
//            saveObjs(groupsArr)
//            saveObjs(groupItemsArr)
//            saveObjs(historyItemsArr)
//            
//            
//            return true
//            }) { (successMaybe: Bool?) in
//                if let success = successMaybe {
//                    handler(success)
//
//                } else {
//                    print("Error: RealmGlobalProvider.saveSyncResult: no success result")
//                    handler(false)
//                }
//        }
    }
    
    func clearAllDataSync() {
        doInWriteTransactionSync() {[weak self] realm in
            self?.clearAllDataSync(realm)
        }
    }

    // NOTE: Outdated
    fileprivate func clearAllDataSync(_ realm: Realm) {
        realm.delete(realm.objects(GroupItem.self))
        realm.delete(realm.objects(ListItem.self))
        realm.delete(realm.objects(InventoryItem.self))
        realm.delete(realm.objects(HistoryItem.self))
        
        realm.delete(realm.objects(Section.self))
        
        realm.delete(realm.objects(ProductGroup.self))
        realm.delete(realm.objects(List.self))
        realm.delete(realm.objects(DBInventory.self))
        
        realm.delete(realm.objects(StoreProduct.self))
        realm.delete(realm.objects(Product.self))
        realm.delete(realm.objects(ProductCategory.self))

        realm.delete(realm.objects(DBSharedUser.self))

        // tombstones
        realm.delete(realm.objects(DBRemoveGroupItem.self))
        realm.delete(realm.objects(DBRemoveListItem.self))
        realm.delete(realm.objects(DBRemoveInventoryItem.self))
        realm.delete(realm.objects(DBRemoveHistoryItem.self))

        realm.delete(realm.objects(SectionToRemove.self))
        
        realm.delete(realm.objects(DBRemoveProductGroup.self))
        realm.delete(realm.objects(DBRemoveList.self))
        realm.delete(realm.objects(DBRemoveInventory.self))

        realm.delete(realm.objects(StoreProductToRemove.self))
        realm.delete(realm.objects(ProductToRemove.self))
        realm.delete(realm.objects(DBRemoveProductCategory.self))

        realm.delete(realm.objects(DBRemoveSharedUser.self))
    }
    
    func clearAllData(_ handler: @escaping (Bool) -> Void) {
        
        doInWriteTransaction({[weak self] realm in
            
            self?.clearAllDataSync(realm)
            return true
            
            }) {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                    
                } else {
                    logger.e("No success result")
                    handler(false)
                }
        }
    }
    
    func markAllDirty(_ handler: @escaping (Bool) -> Void) {
        // Outdated implementation (section uuid -> unique)
//
//        func markObjsDirty<T: Object>(_ realm: Realm, obj: T.Type, idExtractor: (T) -> String) {
//            for obj in realm.objects(T.self) {
//                realm.create(T.self, value: ["uuid": idExtractor(obj), "dirty": true], update: true)
//            }
//        }
//
//        func markAllDirtySync(_ realm: Realm) {
//            markObjsDirty(realm, obj: GroupItem.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: ListItem.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: InventoryItem.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: HistoryItem.self, idExtractor: {$0.uuid})
//
//            markObjsDirty(realm, obj: Section.self, idExtractor: {$0.uuid})
//
//            markObjsDirty(realm, obj: ProductGroup.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: List.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: DBInventory.self, idExtractor: {$0.uuid})
//
//            markObjsDirty(realm, obj: StoreProduct.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: Product.self, idExtractor: {$0.uuid})
//            markObjsDirty(realm, obj: ProductCategory.self, idExtractor: {$0.uuid})
//
////            this is not synced
////            markObjsDirty(realm, obj: DBSharedUser.self, idExtractor: {$0.uuid})
//        }
//
//        doInWriteTransaction({realm in
//            markAllDirtySync(realm)
//            return true
//
//        }) {(successMaybe: Bool?) in
//            if let success = successMaybe {
//                handler(success)
//
//            } else {
//                logger.e("No success result")
//                handler(false)
//            }
//        }
    }

    fileprivate func initContainers(realm: Realm) {

        let fractionsContainer: FractionsContainer? = self.loadFirstSync()
        if fractionsContainer == nil {
            realm.add(FractionsContainer())
        }

        let inventoriesContainer: InventoriesContainer? = self.loadFirstSync()
        if inventoriesContainer == nil {
            realm.add(InventoriesContainer())
        }

        let listsContainer: ListsContainer? = self.loadFirstSync()
        if listsContainer == nil {
            realm.add(ListsContainer())
        }

        let recipesContainer: RecipesContainer? = self.loadFirstSync()
        if recipesContainer == nil {
            realm.add(RecipesContainer())
        }

        let baseQuantitiesContainer: BaseQuantitiesContainer? = self.loadFirstSync()
        if baseQuantitiesContainer == nil {
            realm.add(BaseQuantitiesContainer())
        }

        let unitsContainer: UnitsContainer? = self.loadFirstSync()
        if unitsContainer == nil {
            realm.add(UnitsContainer())
        }
    }

    func initContainers(handler: @escaping (Bool) -> Void) {
        
        doInWriteTransaction({ [weak self] realm in
            realm.deleteAll() // This is only for debugging, to avoid multiple instances of prefill objects. During debugging we can force-show intro, which will prefill each time the database. Note that this assumes initContainers is executed before adding the prefill objects. This is a well founded assumption as the containers are a requirements for the pre-fill to work or most other database operations. In production this operation has no effect, as this will be executed only once (intro is shown only first time the user starts the app), and this being the first database write operation, there's nothing to delete.
            logger.v("Cleared realm")
            self?.initContainers(realm: realm)

            return true
        }) {successMaybe in
            handler(successMaybe ?? false)
        }
    }

    func migrate(srcRealm: Realm, targetRealm: Realm) {

        doInWriteTransactionWithRealmSync(targetRealm) { realm in

            initContainers(realm: targetRealm)
            guard let listsContainer = targetRealm.objects(ListsContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }
            guard let inventoriesContainer = targetRealm.objects(InventoriesContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }
            guard let recipesContainer = targetRealm.objects(RecipesContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }
            guard let unitsContainer = targetRealm.objects(UnitsContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }
            guard let baseQuantitiesContainer = targetRealm.objects(BaseQuantitiesContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }
            guard let fractionsContainer = targetRealm.objects(FractionsContainer.self).first else {
                logger.e("Can't migrate - missing container", .db)
                return
            }

            // Units
            let srcUnits: Results<Unit> = srcRealm.objects(Unit.self)
            var addedUnits = [String: Unit]()
            for srcUnit in srcUnits {
                let unit = targetRealm.create(Unit.self, value: srcUnit, update: true)
                addedUnits[unit.uuid] = unit
                unitsContainer.units.append(unit)
            }

            // Base quantities
            let srcBaseQuantities: Results<BaseQuantity> = srcRealm.objects(BaseQuantity.self)
            var addedBaseQuantities = [Float: BaseQuantity]()
            for srcBaseQuantity in srcBaseQuantities {
                let baseQuantity = targetRealm.create(BaseQuantity.self, value: srcBaseQuantity, update: true)
                addedBaseQuantities[baseQuantity.val] = baseQuantity
                baseQuantitiesContainer.bases.append(baseQuantity)
            }

            // Fractions
            let srcFractions: Results<DBFraction> = srcRealm.objects(DBFraction.self)
            var addedFractions = [String: DBFraction]()
            for srcFraction in srcFractions {
                let fraction = targetRealm.create(DBFraction.self, value: srcFraction, update: true)
                addedFractions[fraction.compoundKeyValue()] = fraction
                fractionsContainer.fractions.append(fraction)
            }

            // Categories
            let srcCategories: Results<ProductCategory> = srcRealm.objects(ProductCategory.self)
            var addedCategories = [String: ProductCategory]()
            for srcCategory in srcCategories {
                let category = targetRealm.create(ProductCategory.self, value: srcCategory, update: true)
                addedCategories[category.uuid] = category
            }

            // Items
            let srcItems: Results<Item> = srcRealm.objects(Item.self)
            var addedItems = [String: Item]()
            for srcItem in srcItems {
                guard let category = addedCategories[srcItem.category.uuid] else {
                    logger.e("Couldn't find category! Skipping item.", .db)
                    continue
                }
                let item = targetRealm.create(Item.self, value: srcItem.toRealmMigrationDict(category: category), update: true)
                addedItems[item.uuid] = item
            }

            // Products
            let srcProducts: Results<Product> = srcRealm.objects(Product.self)
            var addedProducts = [String: Product]()
            for srcProduct in srcProducts {
                guard let item = addedItems[srcProduct.item.uuid] else {
                    logger.e("Couldn't find item! Skipping item.", .db)
                    continue
                }
                let product = targetRealm.create(Product.self, value: srcProduct.toRealmMigrationDict(item: item), update: true)
                addedProducts[product.uuid] = product
            }

            // Quantifiable products
            let srcQuantifiableProducts: Results<QuantifiableProduct> = srcRealm.objects(QuantifiableProduct.self)
            var addedQuantifiableProducts = [String: QuantifiableProduct]()
            for srcQuantifiableProduct in srcQuantifiableProducts {
                guard let product = addedProducts[srcQuantifiableProduct.product.uuid] else {
                    logger.e("Couldn't find product! Skipping item.", .db)
                    continue
                }
                guard let unit = addedUnits[srcQuantifiableProduct.unit.uuid] else {
                    logger.e("Couldn't find unit! Skipping item.", .db)
                    continue
                }
                let quantifiableProduct = targetRealm.create(QuantifiableProduct.self, value: srcQuantifiableProduct.toRealmMigrationDict(product: product, unit: unit), update: true)
                quantifiableProduct.secondBaseQuantity.value = srcQuantifiableProduct.secondBaseQuantity.value
                addedQuantifiableProducts[quantifiableProduct.uuid] = quantifiableProduct
            }

            // Store products
            let srcStoreProducts: Results<StoreProduct> = srcRealm.objects(StoreProduct.self)
            var addedStoreProducts = [String: StoreProduct]()
            for srcStoreProduct in srcStoreProducts {
                guard let quantifiableProduct = addedQuantifiableProducts[srcStoreProduct.product.uuid] else {
                    logger.e("Couldn't find quantifiable product! Skipping item.", .db)
                    continue
                }
                let storeProduct = targetRealm.create(StoreProduct.self, value: srcStoreProduct.toRealmMigrationDict(quantifiableProduct: quantifiableProduct), update: true)
                addedStoreProducts[storeProduct.uuid] = storeProduct
            }

            // Inventories
            let srcInventories: Results<DBInventory> = srcRealm.objects(DBInventory.self)
            var addedInventories = [String: DBInventory]()
            for srcInventory in srcInventories {
                let inventory = targetRealm.create(DBInventory.self, value: srcInventory, update: true)
                addedInventories[inventory.uuid] = inventory
                inventoriesContainer.inventories.append(inventory)
            }

            // Inventory items
            let srcInventoryItems: Results<InventoryItem> = srcRealm.objects(InventoryItem.self)
            for srcInventoryItem in srcInventoryItems {
                guard let product = addedQuantifiableProducts[srcInventoryItem.product.uuid] else {
                    logger.e("Couldn't find product! Skipping item.", .db)
                    continue
                }
                guard let inventory = addedInventories[srcInventoryItem.inventory.uuid] else {
                    logger.e("Couldn't find inventory! Skipping item.", .db)
                    continue
                }
                _ = targetRealm.create(InventoryItem.self, value: srcInventoryItem.toRealmMigrationDict(product: product, inventory: inventory), update: true)
            }

            // Recipes
            let srcRecipes: Results<Recipe> = srcRealm.objects(Recipe.self)
            var addedRecipes = [String: Recipe]()
            for srcRecipe in srcRecipes {
                let recipe = targetRealm.create(Recipe.self, value: srcRecipe, update: true)
                addedRecipes[recipe.uuid] = recipe
                recipesContainer.recipes.append(recipe)
            }

            // Text spans
            let srcTextSpans: Results<DBTextSpan> = srcRealm.objects(DBTextSpan.self)
            for srcTextSpan in srcTextSpans {
                _ = targetRealm.create(DBTextSpan.self, value: srcTextSpan, update: true)
            }

            // Ingredients
            let srcIngredients: Results<Ingredient> = srcRealm.objects(Ingredient.self)
            for srcIngredient in srcIngredients {
                guard let recipe = addedRecipes[srcIngredient.recipe.uuid] else {
                    logger.e("Couldn't find recipe! Skipping item.", .db)
                    continue
                }
                guard let unit = addedUnits[srcIngredient.unit.uuid] else {
                    logger.e("Couldn't find unit! Skipping item.", .db)
                    continue
                }
                guard let item = addedItems[srcIngredient.item.uuid] else {
                    logger.e("Couldn't find item! Skipping item.", .db)
                    continue
                }
                _ = targetRealm.create(Ingredient.self, value: srcIngredient.toRealmMigrationDict(recipe: recipe, unit: unit, item: item), update: true)
           }

            // Lists
            let lists: Results<List> = srcRealm.objects(List.self)
            var addedLists = [String: List]()
            for srcList in lists {
                guard let  inventory = addedInventories[srcList.inventory.uuid] else {
                    logger.e("Couldn't find inventory! Skipping item.", .db)
                    continue
                }
                let list = targetRealm.create(List.self, value: srcList.toRealmMigrationDict(inventory: inventory), update: true)
                addedLists[list.uuid] = list
                listsContainer.lists.append(list)
            }

            // Sections
            let srcSections: Results<Section> = srcRealm.objects(Section.self)
            var addedSections = [String: Section]()
            for srcSection in srcSections {
                guard let list = addedLists[srcSection.list.uuid] else {
                    logger.e("Couldn't find list! Skipping item.", .db)
                    continue
                }

                let section = targetRealm.create(Section.self, value: srcSection.toRealmMigrationDict(list: list), update: true)

                switch section.status {
                case .todo:
                    list.todoSections.append(section)
                case .done, .stash: break // done and stash sections exist but aren't stored in lists (this is not necessary since we don't display / don't need reordering of these sections)
                }
                addedSections[section.unique.toString()] = section
            }

            // List items
            let srcListItems: Results<ListItem> = srcRealm.objects(ListItem.self)
            for srcListItem in srcListItems {
                guard let list = addedLists[srcListItem.list.uuid] else {
                    logger.e("Couldn't find list! Skipping item.", .db)
                    continue
                }
                guard let section = addedSections[srcListItem.section.unique.toString()] else {
                    logger.e("Couldn't find section! Skipping item.", .db)
                    continue
                }
                guard let storeProduct = addedStoreProducts[srcListItem.product.uuid] else {
                    logger.e("Couldn't find store product! Skipping item.", .db)
                    continue
                }
                let listItem = targetRealm.create(ListItem.self, value: srcListItem.toRealmMigrationDict(section: section, storeProduct: storeProduct, list: list), update: true)
                section.listItems.append(listItem)
                switch section.status {
                case .done: list.doneListItems.append(listItem)
                case .stash: list.stashListItems.append(listItem)
                case .todo: break // .todo uses sections
                }
            }

            // Users
            let srcUsers: Results<DBSharedUser> = srcRealm.objects(DBSharedUser.self)
            var addedUsers = [String: DBSharedUser]()
            for srcUser in srcUsers {
                let user = targetRealm.create(DBSharedUser.self, value: srcUser, update: true)
                addedUsers[user.email] = user
            }

            // History items
            let srcHistoryItems: Results<HistoryItem> = srcRealm.objects(HistoryItem.self)
            for srcHistoryItem in srcHistoryItems {
                guard let inventory = addedInventories[srcHistoryItem.inventory.uuid] else {
                    logger.e("Error!", .db)
                    continue
                }
                guard let quantifiableProduct = addedQuantifiableProducts[srcHistoryItem.product.uuid] else {
                    logger.e("Couldn't find quantifiable product! Skipping item.", .db)
                    continue
                }
                let user = addedUsers[srcHistoryItem.user.email] ?? {
                    logger.i("Couldn't find user! Using default shared user.", .db)
                    return DBSharedUser(email: "")
                    } ()
                _ = targetRealm.create(HistoryItem.self, value: srcHistoryItem.toRealmMigrationDict(inventory: inventory, quantifiableProduct: quantifiableProduct, user: user), update: true)
            }
        }
    }

    // MARK: - UI Tests

    public func clearAppForUITests() {
        doInWriteTransactionSync() { [weak self] realm in
            realm.deleteAll() // This is only for debugging, to avoid multiple instances of prefill objects. During debugging we can force-show intro, which will prefill each time the database. Note that this assumes initContainers is executed before adding the prefill objects. This is a well founded assumption as the containers are a requirements for the pre-fill to work or most other database operations. In production this operation has no effect, as this will be executed only once (intro is shown only first time the user starts the app), and this being the first database write operation, there's nothing to delete.
            logger.v("Cleared realm")
            self?.initContainers(realm: realm)

            guard let inventoriesContainer: InventoriesContainer = loadSync(predicate: nil)?.first else {
                logger.e("Invalid state: no container")
                return
            }
            let inventory = DBInventory(uuid: UUID().uuidString, name: "Test inventory", bgColor: UIColor.flatRed, order: 0)
            realm.add(inventory)
            logger.d("Added test inventory!", .db)
            inventoriesContainer.inventories.append(inventory)

            guard let listsContainer: ListsContainer = loadSync(predicate: nil)?.first else {
                logger.e("Invalid state: no container")
                return
            }

            let list = List(uuid: UUID().uuidString, name: "Test list", color: UIColor.flatRed, order: 0, inventory: inventory, store: nil)
            realm.add(list)
            logger.d("Added test list!", .db)
            listsContainer.lists.append(list)
        }
    }
}

//
//  RealmConfig.swift
//  Providers
//
//  Created by Ivan Schuetz on 16/12/2016.
//
//

import Foundation
import RealmSwift
import Realm
import Realm.Dynamic

public struct RealmConfig {

    #if (arch(i386) || arch(x86_64)) && os(iOS)
        fileprivate static let syncHost = "127.0.0.1"
    #else // device
        fileprivate static let syncHost = "192.168.0.208"
    #endif
    fileprivate static let syncRealmPath = "groma4"

    static let syncAuthURL = URL(string: "http://\(syncHost):9080")!
    static let syncServerURL = URL(string: "realm://\(syncHost):9080/~/\(syncRealmPath)")!

    fileprivate static var documentsDirectoryUrl: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }

    fileprivate static var localRealmUrl: URL? {
        return documentsDirectoryUrl.appendingPathComponent("default.realm")
    }

    public static var config = Realm.Configuration(
        // Set the new schema version. This must be greater than the previously used
        // version (if you've never set a schema version before, the version is 0).
        schemaVersion: 26,
        
        // Set the block which will be called automatically when opening a Realm with
        // a schema version lower than the one set above
        migrationBlock: { migration, oldSchemaVersion in
            // We haven’t migrated anything yet, so oldSchemaVersion == 0
            if (oldSchemaVersion < 1) {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
    })

    static var localRealmConfig: Realm.Configuration {
        var config = RealmConfig.config
        config.fileURL = localRealmUrl
        return config
    }

    static func syncedRealmConfigutation(user: SyncUser) -> Realm.Configuration {
        var config = RealmConfig.config

        config.syncConfiguration = SyncConfiguration(user: user, realmURL: syncServerURL)
        config.objectTypes = [List.self, DBInventory.self, Section.self, Product.self, DBSharedUser.self,
                              DBRemoveList.self, DBRemoveInventory.self, ListItem.self, InventoryItem.self,
                              DBSyncable.self, HistoryItem.self, DBPlanItem.self, ProductGroup.self, GroupItem.self,
                              ProductCategory.self, StoreProduct.self, Recipe.self, Ingredient.self,
                              SectionToRemove.self, ProductToRemove.self, StoreProductToRemove.self,
                              DBRemoveSharedUser.self, DBRemoveGroupItem.self, DBRemoveProductCategory.self,
                              DBRemoveInventoryItem.self, DBRemoveProductGroup.self, Item.self, Unit.self,
                              QuantifiableProduct.self, RecipesContainer.self, InventoriesContainer.self,
                              ListsContainer.self, BaseQuantitiesContainer.self, BaseQuantity.self
        ]

        return config
    }
}

// MARK: RLM
// (Obj-C api, needed to copy local realm to synced realm https://github.com/realm/realm-cocoa/issues/5381)

extension RealmConfig {

    static var localRlmRealmConfig: RLMRealmConfiguration {

        let configuration = RLMRealmConfiguration()
        configuration.fileURL = localRealmUrl
        configuration.dynamic = true
        configuration.readOnly = true
        return configuration
    }

    // Util

    static func copyLocalToSyncRealm(user: RLMSyncUser, onFinish: @escaping () -> Void) {
        logger.d("Start copying local realm to synced realm", .auth, .sync)

        let localConfig = localRlmRealmConfig

        logger.d("Path of local realm: \(String(describing: localConfig.fileURL))", .auth, .sync)

        RLMRealm.asyncOpen(with: localConfig, callbackQueue: .main) { realm, error in
            if let realm = realm {
                copyToSyncRealmWithRealm(localRlmRealm: realm, user: user)
                logger.i("Finished copying local realm to synced realm", .auth, .sync)
                onFinish()
            } else {
                logger.e("Error opening realm: \(String(describing: error))", .db)
                onFinish()
            }
        }
    }

    fileprivate static func copyToSyncRealmWithRealm(localRlmRealm: RLMRealm, user: RLMSyncUser) {
        let syncConfig = RLMRealmConfiguration()
        syncConfig.syncConfiguration = RLMSyncConfiguration(user: user, realmURL: syncServerURL)
        syncConfig.customSchema = localRlmRealm.schema

        let syncRealm = try! RLMRealm(configuration: syncConfig)
        syncRealm.schema = syncConfig.customSchema!
        try! syncRealm.transaction {
            let objectSchema = syncConfig.customSchema!.objectSchema
            for schema in objectSchema {
                let allObjects = localRlmRealm.allObjects(schema.className)
                for i in 0..<allObjects.count {
                    let object = allObjects[i]
                    RLMCreateObjectInRealmWithValue(syncRealm, schema.className, object, true)
                }
            }
        }
    }
}

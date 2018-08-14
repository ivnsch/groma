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

    fileprivate static let remoteSyncHost = "gr.us1.cloud.realm.io"

    #if targetEnvironment(simulator)
        fileprivate static let syncHost = remoteSyncHost
    #else // device
        fileprivate static let syncHost = remoteSyncHost
    #endif

    static let syncAuthURL = URL(string: "https://\(syncHost)")!
    static let syncServerURL = URL(string: "realms://\(syncHost)/~/default")!
    static let syncUserUrl = URL(string: "https://\(syncHost)/user/")!

    fileprivate static var localRealmDirectoryPreV2_1: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    }

    fileprivate static var localRealmDirectory: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.co.groma")
    }

    fileprivate static var localRealmUrlPreV2_1: URL? {
        return localRealmDirectoryPreV2_1.flatMap { localRealmUrlFor(directory: $0) }
    }

    fileprivate static var localRealmUrl: URL? {
        return localRealmDirectory.flatMap { localRealmUrlFor(directory: $0) }
    }

    fileprivate static func localRealmUrlFor(directory: URL) -> URL? {
        return directory.appendingPathComponent("default.realm")
    }

    fileprivate static let schemaVersion: UInt64 = 2

    public static var config = Realm.Configuration(
        // Set the new schema version. This must be greater than the previously used
        // version (if you've never set a schema version before, the version is 0).
        schemaVersion: RealmConfig.schemaVersion,

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

    public static func setDefaultConfiguration() {
        if let user = SyncUser.current {
            logger.i("Realm user exists: \(String(describing: user.identity)), initializing synced realm.", .db)
            Realm.Configuration.defaultConfiguration = RealmConfig.syncedRealmConfigutation(user: user)
        } else {
            Realm.Configuration.defaultConfiguration = RealmConfig.localRealmConfig
        }

        logger.i("Realm path: \(String(describing: Realm.Configuration.defaultConfiguration.fileURL))", .db)
    }
    
    /**
     * For app versions pre-2.1 Realm has to be moved to share folder.
     * Shared folder is necessary to share Realm with SiriKit extension.
     */
    public static func moveRealmToSharedFolderIfNecessary() {
        let fileManager = FileManager.default

        guard let localRealmUrlPreV2_1 = localRealmUrlPreV2_1 else {
            logger.e("FATAL No localRealmUrlPreV2_1 - can't move Realm", .db)
            return
        }

        guard let localRealmUrl = localRealmUrl else {
            logger.e("FATAL No localRealmUrl - can't move Realm", .db)
            return
        }

        func sourceRealmExists() -> Bool {
            return fileManager.fileExists(atPath: localRealmUrlPreV2_1.absoluteString)
        }

        func destinationRealmExists() -> Bool {
            return fileManager.fileExists(atPath: localRealmUrl.absoluteString)
        }


        if (sourceRealmExists() && !destinationRealmExists()) {
            do {
                try fileManager.moveItem(atPath: localRealmUrlPreV2_1.absoluteString, toPath: localRealmUrl.absoluteString)

                // Set Realm path to the new directory
                Realm.Configuration.defaultConfiguration.fileURL = localRealmUrl
                logger.i("Moved Realm to shared folder: \(localRealmUrl)")

            } catch let e {
                logger.e("FATAL: Couldn't move Realm to shared folder. " +
                        "Source Realm exists: \(sourceRealmExists()), " +
                        "destination Realm exists: \(destinationRealmExists()). " +
                        "Error: \(e). " +
                        "Will be ignored hoping that it's detected in logs and user doesn't use SiriKit.", .db)
            }
        } else {
            #if DEBUG
                logger.v("It was not needed to move Realm." +
                        "Source Realm exists: \(sourceRealmExists()), " +
                        "destination Realm exists: \(destinationRealmExists()).", .db)
            #endif
        }
    }

    public static var localRealmConfig: Realm.Configuration {
        var config = RealmConfig.config
        config.fileURL = localRealmUrl
        return config
    }

    static func localRealm() -> Realm? {
        do {
            return try Realm(configuration: localRealmConfig)
        } catch (let e) {
            logger.e("Error instantiating local realm: \(e)", .db)
            return nil
        }
    }

    /// Loads realm with asyncOpen, which executes the callback after all the data is available.
    static func syncedRealm(user: SyncUser, onReady: @escaping (Realm?) -> Void) {
        Realm.asyncOpen(configuration: syncedRealmConfigutation(user: user)) { realm, error in
            guard let realm = realm else {
                logger.e("Error instantiating synced realm: \(String(describing: error))", .db)
                onReady(nil)
                return
            }
            onReady(realm)
        }
    }

    static func syncedRealm(user: SyncUser) -> Realm? {
        do {
            return try Realm(configuration: syncedRealmConfigutation(user: user))
        } catch (let e) {
            logger.e("Error instantiating synced realm: \(e)", .db)
            return nil
        }
    }

    public static func syncedRealmConfigutation(user: SyncUser) -> Realm.Configuration {
        var config = Realm.Configuration()
        
        RealmSwift.SyncManager.shared.logLevel = SyncLogLevel.all

        config.syncConfiguration = SyncConfiguration(user: user, realmURL: syncServerURL)
        config.objectTypes = [List.self, DBInventory.self, Section.self, Product.self, DBSharedUser.self,
                              ListItem.self, InventoryItem.self,
                              DBSyncable.self, HistoryItem.self, ProductGroup.self, GroupItem.self,
                              ProductCategory.self, StoreProduct.self, Recipe.self, Ingredient.self, Item.self, Unit.self,
                              QuantifiableProduct.self, RecipesContainer.self, InventoriesContainer.self,
                              ListsContainer.self, BaseQuantitiesContainer.self, BaseQuantity.self, UnitsContainer.self,
                              DBTextSpan.self, DBFraction.self, FractionsContainer.self
        ]

        return config
    }

    public static func realm() throws -> Realm {
        return try Realm()
    }

}

// MARK: RLM
// (Obj-C api, needed to copy local realm to synced realm https://github.com/realm/realm-cocoa/issues/5381)

extension RealmConfig {

    static var localRlmRealmConfig: RLMRealmConfiguration {

        let configuration = RLMRealmConfiguration()
        configuration.schemaVersion = RealmConfig.schemaVersion
        configuration.fileURL = localRealmUrl
//        configuration.dynamic = true
        //configuration.readOnly = true
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

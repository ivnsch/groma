//
//  RealmSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmSectionProvider: RealmProvider {

    fileprivate let syncProvider = RealmSectionProviderSync()

    func loadSectionWithUnique(_ unique: SectionUnique, handler: @escaping (Section?) -> Void) {
        handler(syncProvider.loadSectionWithUnique(unique))
    }
    
    func loadSection(_ name: String, list: List, handler: @escaping (Section?) -> ()) {
        handler(syncProvider.loadSection(name, list: list))
    }

    func loadSections(_ names: [String], list: List, handler: @escaping (ProvResult<Results<Section>, DatabaseError>) -> Void) {
        handler(syncProvider.loadSections(names, list: list))
    }

    func saveSections(_ sections: [Section], handler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async(execute: {
            handler(self.syncProvider.saveSections(sections))
        })
    }
    
    func remove(_ section: Section, notificationTokens: [NotificationToken], markForSync: Bool, handler: @escaping (Bool) -> Void) {
        handler(syncProvider.remove(section.unique, notificationTokens: notificationTokens, markForSync: markForSync))
    }
    
    func removeAllWithName(_ sectionName: String, markForSync: Bool, handler: @escaping ([Section]?) -> Void) {
        handler(syncProvider.removeAllWithName(sectionName, markForSync: markForSync))
    }
    
    func remove(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool, handler: @escaping (Bool) -> Void) {
        handler(syncProvider.removeSectionAndDependencies(sectionUnique, notificationTokens: notificationTokens, markForSync: markForSync))
    }
    
    func removeSectionAndDependenciesSync(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool) -> Bool {
        return syncProvider.removeSectionAndDependencies(sectionUnique, notificationTokens: notificationTokens, markForSync: markForSync)
    }
    
    func removeSectionAndDependenciesSync(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {
        return syncProvider.removeSectionAndDependencies(realm, sectionUnique: sectionUnique, markForSync: markForSync)
    }
    
    func removeSectionDependenciesSync(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {
        return syncProvider.removeSectionDependencies(realm, sectionUnique: sectionUnique, markForSync: markForSync)
    }

    func update(_ section: Section, input: SectionInput) -> Section? {
        return syncProvider.update(section, input: input)
    }
    
    func sectionSuggestionsContainingText(_ text: String, handler: @escaping ([String]) -> Void) {
        handler(syncProvider.sectionSuggestionsContainingText(text))
    }
    
    func removeSectionIfEmptySync(_ realm: Realm, sectionUnique: SectionUnique) {
        syncProvider.removeSectionIfEmpty(realm, sectionUnique: sectionUnique)
    }

    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, overwriteColorIfAlreadyExists: Bool = true, status: ListItemStatus, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionResult, DatabaseError> {
        return syncProvider.mergeOrCreateSection(sectionName, sectionColor: sectionColor, overwriteColorIfAlreadyExists: overwriteColorIfAlreadyExists, status: status, list: list, realmData: realmData, doTransaction: doTransaction)
    }
    
    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, list: List, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionPlainResult, DatabaseError> {
        return syncProvider.mergeOrCreateSection(sectionName, sectionColor: sectionColor, list: list, status: status, realmData: realmData, doTransaction: doTransaction)
    }
    
    public func move(from: Int, to: Int, sections: RealmSwift.List<Section>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        handler(syncProvider.move(from: from, to: to, sections: sections, notificationToken: notificationToken))
    }
    
    func getOrCreateTodo(name: String, color: UIColor, list: List, notificationTokens: [NotificationToken], realm: Realm, doTransaction: Bool = true) -> Section? {
        return syncProvider.getOrCreateTodo(name: name, color: color, list: list, notificationTokens: notificationTokens, realm: realm, doTransaction: doTransaction)
    }
    
    func getOrCreateCartStash(name: String, color: UIColor, list: List, status: ListItemStatus, notificationTokens: [NotificationToken], realm: Realm, doTransaction: Bool = true) -> Section? {
        return syncProvider.getOrCreateCartStash(name: name, color: color, list: list, status: status, notificationTokens: notificationTokens, realm: realm, doTransaction: doTransaction)
    }
    
    func clearSectionsTombstones(_ uuids: [String], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            for uuid in uuids {
                self?.clearSectionTombstoneSync(realm, uuid: uuid)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    // TODO remove manual sync code?

    fileprivate func clearSectionTombstoneSync(_ realm: Realm, uuid: String) {
        realm.deleteForFilter(DBRemoveSection.self, DBRemoveSection.createFilter(uuid))
    }

    func clearSectionTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.clearSectionTombstoneSync(realm, uuid: uuid)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    func updateLastSyncTimeStamps(_ sectionsUpdateDicts: [[String: AnyObject]], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for dict in sectionsUpdateDicts {
                logger.v("Saving dictionaries for section updates: \(sectionsUpdateDicts)")
                realm.create(Section.self, value: dict, update: true)
            }
            return true
        }, finishHandler: {success in
            handler(success ?? false)
        })
    }
}

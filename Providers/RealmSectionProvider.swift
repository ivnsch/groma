//
//  RealmSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift



public struct AddSectionResult {
    public let section: Section
    public let isNew: Bool
    public let index: Int
}

// Sections added only to realm but not ordered RealmSwift.List
public struct AddSectionPlainResult {
    public let section: Section
    public let isNew: Bool
}

public struct SectionInput {
    public let name: String
    public let color: UIColor
    
    public init(name: String, color: UIColor) {
        self.name = name
        self.color = color
    }
}


class RealmSectionProvider: RealmProvider {
    
    func sections(list: List, handler: @escaping (ProvResult<RealmSwift.List<Section>, DatabaseError>) -> Void) {
        handler(loadSectionsSync(list: list))
    }
    
    func loadSectionWithUnique(_ unique: SectionUnique, handler: @escaping (Section?) -> Void) {
        handler(loadFirstSync(predicate: Section.createFilter(unique: unique)))
    }
    
    func loadSection(_ name: String, list: List, handler: @escaping (Section?) -> ()) {
        handler(loadSectionSync(name, list: list).getOk()?.flatMap{$0}) // backwards compatibility - transform result to optional. Note that we should change all these methods to use result
    }
    
    // TODO use database specific result types to return, signal error, instead of tuple with success
    func loadSectionSync(_ name: String, list: List) -> ProvResult<Section?, DatabaseError> {
        return loadSectionsSync([name], list: list).map{$0?.first}
    }

    func loadSectionsSync(_ names: [String], list: List) -> ProvResult<Results<Section>?, DatabaseError> {
        return .ok(loadSync(predicate: Section.createFilterWithNames(names, listUuid: list.uuid)))
    }
    
    func loadSectionsSync(list: List) -> ProvResult<RealmSwift.List<Section>, DatabaseError> {
        fatalError("Remove this?")
//        if let list: RealmSwift.List<Section> = loadSync(filter: Section.createFilterList(list.uuid)) { // if let - backwards compatibility (TODO return Results also in RealmProvider methods)
//            return .ok(sections)
//        } else {
//            return .err(.unknown)
//        }
    }
    
    func loadSections(_ names: [String], list: List, handler: @escaping (Results<Section>?) -> Void) {
        handler(loadSync(predicate: Section.createFilterWithNames(names, listUuid: list.uuid)))
    }

    // Loads sections with given name from all the lists
    func loadSections(_ name: String, handler: @escaping (Results<Section>?) -> Void) {
        handler(loadSync(predicate: Section.createFilterWithName(name)))
    }

    func saveSection(_ section: Section, handler: @escaping (Bool) -> ()) {
        let dbSection = Section()
        dbSection.name = section.name
        dbSection.status = section.status
        dbSection.list = section.list
        self.saveObj(dbSection, handler: handler)
    }
    
    func saveSections(_ sections: [Section], handler: @escaping (Bool) -> ()) {
        let sections: [Section] = sections.map{$0.copy()}
        saveObjs(sections, update: true, handler: handler)
    }
    
    func remove(_ section: Section, notificationTokens: [NotificationToken], markForSync: Bool, handler: @escaping (Bool) -> Void) {
        remove(section.unique, notificationTokens: notificationTokens, markForSync: markForSync, handler: handler)
    }
    
    func removeAllWithName(_ sectionName: String, markForSync: Bool, handler: @escaping ([Section]?) -> Void) {
        loadSections(sectionName) { [weak self] sections in guard let weakSelf = self else { return }
            guard let sections = sections else { logger.v("Sections is nil"); handler(nil); return }
            if !sections.isEmpty {
                _ = weakSelf.doInWriteTransactionSync({(realm: Realm) -> Results<Section> in
                    for section in sections {
                        _ = weakSelf.removeSectionAndDependenciesSync(realm, sectionUnique: section.unique, markForSync: markForSync)
                    }
                    return sections
                })
                handler(sections.toArray())
            } else {
                logger.d("No sections with name: \(sectionName) - nothing to remove") // this is not an error, this can be used e.g. in the autosuggestions where we list also category names.
                handler([])
            }
        }
    }
    
    func remove(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool, handler: @escaping (Bool) -> Void) {
        handler(removeSectionAndDependenciesSync(sectionUnique, notificationTokens: notificationTokens, markForSync: markForSync))
    }
    
    func removeSectionAndDependenciesSync(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool) -> Bool {
        return doInWriteTransactionSync(withoutNotifying: notificationTokens) {[weak self] realm in
            if let weakSelf = self {
                _ = weakSelf.removeSectionAndDependenciesSync(realm, sectionUnique: sectionUnique, markForSync: markForSync)
                return true
            } else {
                logger.e("self is nil")
                return false
            }
        } ?? false
    }
    
    // Expected to be executed in a transaction
    func removeSectionAndDependenciesSync(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {
        
        _ = removeSectionDependenciesSync(realm, sectionUnique: sectionUnique, markForSync: markForSync)
        
        // delete section
        if let dbSection = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique)).first {
//            if markForSync {
//                let toRemove = SectionToRemove(dbSection) // create this before the delete or it crashes TODO!!!! also in other places of the app, this error is in several other providers
//                realm.add(toRemove, update: true)
//            }
            realm.delete(dbSection)
            return true
        } else {
            logger.w("Didn't find section to be deleted: \(sectionUnique)")
            return false
        }
    }
    
    func removeSectionDependenciesSync(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {
        // delete list items referencing the section
        let dbListItems = realm.objects(ListItem.self).filter(ListItem.createFilterWithSection(sectionUnique))
        if markForSync {
            let toRemoveListItems = Array(dbListItems.map{DBRemoveListItem($0)}) // create this before the delete or it crashes
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        realm.delete(dbListItems)
        return true
    }

    func update(_ section: Section, input: SectionInput) -> Section? {
        return doInWriteTransactionSync {realm in
            section.name = input.name
            section.color = input.color
            return section
        }
    }
    
    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(_ text: String, handler: @escaping ([String]) -> Void) {
        withRealm({ realm in

            // Sections
            let unfilteredSections = realm.objects(Section.self)
            let sectionFilterMaybe: NSPredicate? = text.isEmpty ? nil : Section.createFilterNameContains(text)
            let filteredSections: Results<Section> = sectionFilterMaybe.map { unfilteredSections.filter($0) }
                ?? unfilteredSections
            let sectionNames: [String] = filteredSections.map{$0.name}

            // Categories
            let unfilteredCategories = realm.objects(ProductCategory.self)
            let categoryFilterMaybe: NSPredicate? = text.isEmpty ? nil : ProductCategory.createFilterNameContains(text)
            let filteredCategories: Results<ProductCategory> = categoryFilterMaybe.map {
                unfilteredCategories.filter($0)} ?? unfilteredCategories
            let categoryNames: [String] = filteredCategories.map{$0.name}

            let allNames: [String] = (sectionNames + categoryNames).distinct()
            return allNames
            
            }) { (allNamesMaybe: [String]?) -> Void in
                if let allNames = allNamesMaybe {
                    handler(allNames)
                } else {
                    print("Error: RealmListItemProvider.loadSectionSuggestions: Couldn't load section suggestions")
                    handler([])
                }
        }
    }
    
    func removeSectionIfEmptySync(_ realm: Realm, sectionUnique: SectionUnique) {
        if realm.objects(ListItem.self).filter(ListItem.self.createFilterWithSection(sectionUnique)).isEmpty { // if no list items reference the section
            let dbSection = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique))
            realm.delete(dbSection)
        }
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
    
    // add/update and save (TODO better method name)
    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, overwriteColorIfAlreadyExists: Bool = true, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionResult, DatabaseError> {
        
        guard let sections = sectionsSync(list: list, status: status) else {
            logger.e("Couldn't retrieve the sections for list: \(list.uuid): \(list.name)")
            return .err(.unknown)
        }

        func transactionContent(realm: Realm) -> ProvResult<AddSectionResult, DatabaseError>? {
            
            let addResult: AddSectionResult = {
                let sectionUnique = SectionUnique(name: sectionName, listUuid: list.uuid, status: status)
                if let section = sections.filter(Section.createFilter(unique: sectionUnique)).first, let index = sections.index(of: section) {
                    if overwriteColorIfAlreadyExists {
                        section.color = sectionColor
                    }
                    realm.add(section, update: true) // TODO is this necessary?
                    return AddSectionResult(section: section, isNew: false, index: index)
                } else { // New section
                    let section = Section(name: sectionName, color: sectionColor, list: list, order: (status: status, order: 123), status: status) // TODO!!!!!!!!!!!!!! order for now leaving this out because it's not clear how list items / sections will be re-implemented to support real time sync. If we use RealmSwift.List, order field can be removed.
                    sections.append(section)
                    return AddSectionResult(section: section, isNew: true, index: sections.count - 1)
                }
            }()
            
            return .ok(addResult)
        }
        
        let resultMaybe: ProvResult<AddSectionResult, DatabaseError>? = {
            if doTransaction {
                return self.doInWriteTransactionSync(realmData: realmData) {realm in
                    return transactionContent(realm: realm)
                }
            } else {
                return self.withRealmSync(realm: realmData?.realm) {realm in
                    return transactionContent(realm: realm)
                }
            }
        }()

        return resultMaybe ?? .err(.unknown)
    }
    
    // add/update and save (TODO better method name)
    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, possibleNewOrder: ListItemStatusOrder?, list: List, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionPlainResult, DatabaseError> {
        
        func transactionContent(realm: Realm) -> ProvResult<AddSectionPlainResult, DatabaseError>? {
            
            let addResult: AddSectionPlainResult = {
                let sectionUnique = SectionUnique(name: sectionName, listUuid: list.uuid, status: status)
                if let section = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique)).first { // exists
                    section.color = sectionColor
                    realm.add(section, update: true) // TODO is this necessary?
                    return AddSectionPlainResult(section: section, isNew: false)
                } else { // doesn't exist
                    let section = Section(name: sectionName, color: sectionColor, list: list, order: (status: .done, order: 123), status: status) // TODO!!!!!!!!!!!!!! order for now leaving this out because it's not clear how list items / sections will be re-implemented to support real time sync. If we use RealmSwift.List, order field can be removed.
//                    sections.append(section)
                    realm.add(section, update: true)
                    return AddSectionPlainResult(section: section, isNew: true)
                }
            }()
            
            return .ok(addResult)
        }
        
        let resultMaybe: ProvResult<AddSectionPlainResult, DatabaseError>? = {
            if doTransaction {
                return self.doInWriteTransactionSync(realmData: realmData) {realm in
                    return transactionContent(realm: realm)
                }
            } else {
                return self.withRealmSync(realm: realmData?.realm) {realm in
                    return transactionContent(realm: realm)
                }
            }
        }()
        
        return resultMaybe ?? .err(.unknown)
    }
    
    public func move(from: Int, to: Int, sections: RealmSwift.List<Section>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: sections.realm) {realm -> Bool in
            sections.move(from: from, to: to)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    // MARK: - Sync
    
    /// Get or create for .todo (takes into consideration that section is in a RealmSwift.List)
    func getOrCreateTodo(name: String, color: UIColor, list: List, notificationTokens: [NotificationToken], realm: Realm, doTransaction: Bool = true) -> Section? {
        
        let status: ListItemStatus = .todo
        
        func appendSection(section: Section) -> Section? {
            
            func transactionContent(realm: Realm) -> Section? {
                list.sections(status: status).append(section)
                return section
            }
            
            
            let sectionMaybe: Section? = {
                if doTransaction {
                    return doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: realm, {realm in
                        return transactionContent(realm: realm)
                    })
                } else {
                    return transactionContent(realm: realm)
                }
            }()
         
            return sectionMaybe
        }
        
        let sectionUnique = SectionUnique(name: name, listUuid: list.uuid, status: status)
        
        if let section = list.sections(status: status).filter(Section.createFilter(unique: sectionUnique)).first { // The target status already contains the section
            return section
        
        }  else { // The section doesn't exist in the target status
            let section = Section(name: name, color: color, list: list, order: ListItemStatusOrder(status: status, order: 0), status: status) // TODO!!!!!!!!! remove order from sections
            return appendSection(section: section)
        }
    }
    
    /// Get or create for .cart and .stash (section is not in a RealmSwift.List)
    func getOrCreateCartStash(name: String, color: UIColor, list: List, status: ListItemStatus, notificationTokens: [NotificationToken], realm: Realm, doTransaction: Bool = true) -> Section? {
        func transactionContent(realm: Realm) -> Section? {
            let sectionUnique = SectionUnique(name: name, listUuid: list.uuid, status: status)
            if let section = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique)).first { // The target status already contains the section
                return section

            } else {
                let section = Section(name: name, color: color, list: list, order: ListItemStatusOrder(status: status, order: 0), status: status) // TODO!!!!!!!!! remove order from sections
                realm.add(section, update: true)
                return section
            }
        }
        
            
        let sectionMaybe: Section? = {
            if doTransaction {
                return doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: realm, {realm in
                    return transactionContent(realm: realm)
                })
            } else {
                return transactionContent(realm: realm)
            }
        }()
        
        return sectionMaybe
    }
    
    // Load the sections directly from Realm - to ensure the resulting RealmSwift.List references a realm (which is not the case when using "copy") as well as it's fetched from the current thread.
    // RealmSwift.List not referencing a Realm currently results in an exception when calling filter on it - "This method may only be called on RLMArray instances retrieved from an RLMRealm"
    func sectionsSync(list: List, status: ListItemStatus) -> RealmSwift.List<Section>? {
        if let l: List = loadSync(predicate: List.createFilter(uuid: list.uuid))?.first {
            return l.sections(status: status)
        } else {
            return nil
        }
    }
}

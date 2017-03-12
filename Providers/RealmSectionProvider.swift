//
//  RealmSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs


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
    
    func loadSectionWithUuid(_ uuid: String, handler: @escaping (Section?) -> Void) {
        handler(loadFirstSync(filter: Section.createFilter(uuid)))
    }
    
    func loadSection(_ name: String, list: List, handler: @escaping (Section?) -> ()) {
        handler(loadSectionSync(name, list: list).getOk()?.flatMap{$0}) // backwards compatibility - transform result to optional. Note that we should change all these methods to use result
    }
    
    // TODO use database specific result types to return, signal error, instead of tuple with success
    func loadSectionSync(_ name: String, list: List) -> ProvResult<Section?, DatabaseError> {
        return loadSectionsSync([name], list: list).map{$0?.first}
    }

    func loadSectionsSync(_ names: [String], list: List) -> ProvResult<Results<Section>?, DatabaseError> {
        return .ok(loadSync(filter: Section.createFilterWithNames(names, listUuid: list.uuid)))
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
        handler(loadSync(filter: Section.createFilterWithNames(names, listUuid: list.uuid)))
    }

    // Loads sections with given name from all the lists
    func loadSections(_ name: String, handler: @escaping (Results<Section>?) -> Void) {
        handler(loadSync(filter: Section.createFilterWithName(name)))
    }

    func saveSection(_ section: Section, handler: @escaping (Bool) -> ()) {
        let dbSection = Section()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        
        self.saveObj(dbSection, handler: handler)
    }
    
    func saveSections(_ sections: [Section], handler: @escaping (Bool) -> ()) {
        let sections = sections.map{$0.copy()}
        saveObjs(sections, update: true, handler: handler)
    }
    
    func remove(_ section: Section, markForSync: Bool, handler: @escaping (Bool) -> ()) {
        remove(section.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeAllWithName(_ sectionName: String, markForSync: Bool, handler: @escaping ([Section]?) -> Void) {
        loadSections(sectionName) {[weak self] sections in guard let weakSelf = self else {return}
            guard let sections = sections else {QL1("Sections is nil"); handler(nil); return}
            if !sections.isEmpty {
                weakSelf.doInWriteTransaction({(realm: Realm) -> Results<Section> in
                    for section in sections {
                        _ = weakSelf.removeSectionAndDependenciesSync(realm, sectionUuid: section.uuid, markForSync: markForSync)
                    }
                    return sections
                }, finishHandler: {removedSectionsResult in
                    handler(removedSectionsResult?.toArray())
                })
                
            } else {
                QL2("No sections with name: \(sectionName) - nothing to remove") // this is not an error, this can be used e.g. in the autosuggestions where we list also category names.
                handler([])
            }
        }
    }
    
    func remove(_ sectionUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        removeSectionAndDependencies(sectionUuid, markForSync: markForSync, handler: handler)
    }
    
    func removeSectionAndDependencies(_ sectionUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                _ = weakSelf.removeSectionAndDependenciesSync(realm, sectionUuid: sectionUuid, markForSync: markForSync)
                return true
            } else {
                QL4("self is nil")
                return false
            }
        }, finishHandler: {success in
            handler(success ?? false)
        })
    }
    
    // Expected to be executed in a transaction
    func removeSectionAndDependenciesSync(_ realm: Realm, sectionUuid: String, markForSync: Bool) -> Bool {
        
        _ = removeSectionDependenciesSync(realm, sectionUuid: sectionUuid, markForSync: markForSync)
        
        // delete section
        if let dbSection = realm.objects(Section.self).filter(Section.createFilter(sectionUuid)).first {
            if markForSync {
                let toRemove = SectionToRemove(dbSection) // create this before the delete or it crashes TODO!!!! also in other places of the app, this error is in several other providers
                realm.add(toRemove, update: true)
            }
            realm.delete(dbSection)
            return true
        } else {
            QL3("Didn't find section to be deleted: \(sectionUuid)")
            return false
        }
    }
    
    func removeSectionDependenciesSync(_ realm: Realm, sectionUuid: String, markForSync: Bool) -> Bool {
        // delete list items referencing the section
        let dbListItems = realm.objects(ListItem.self).filter(ListItem.createFilterWithSection(sectionUuid))
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
            let sectionNames: [String] = realm.objects(Section.self).filter(Section.createFilterNameContains(text)).map{$0.name}
            let categoryNames: [String] = realm.objects(ProductCategory.self).filter(ProductCategory.createFilterNameContains(text)).map{$0.name}
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
    
    func removeSectionIfEmptySync(_ realm: Realm, sectionUuid: String) {
        if realm.objects(ListItem.self).filter(ListItem.self.createFilterWithSection(sectionUuid)).isEmpty { // if no list items reference the section
            let dbSection = realm.objects(Section.self).filter(Section.createFilter(sectionUuid))
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
                QL1("Saving dictionaries for section updates: \(sectionsUpdateDicts)")
                realm.create(Section.self, value: dict, update: true)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // add/update and save (TODO better method name)
    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionResult, DatabaseError> {
        
        guard let sections = sectionsSync(list: list, status: status) else {
            QL4("Couldn't retrieve the sections for list: \(list.uuid):\(list.name)")
            return .err(.unknown)
        }

        func transactionContent(realm: Realm) -> ProvResult<AddSectionResult, DatabaseError>? {
            
            let addResult: AddSectionResult = {
                if let section = sections.filter(Section.createFilter(sectionName, listUuid: list.uuid)).first, let index = sections.index(of: section)
                
                {
                    
                    section.color = sectionColor
                    realm.add(section, update: true) // TODO is this necessary?
                    return AddSectionResult(section: section, isNew: false, index: index)
                } else {
                    let section = Section(uuid: UUID().uuidString, name: sectionName, color: sectionColor, list: list, order: (status: status, order: 123)) // TODO!!!!!!!!!!!!!! order for now leaving this out because it's not clear how list items / sections will be re-implemented to support real time sync. If we use RealmSwift.List, order field can be removed.
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
    func mergeOrCreateSectionSync(_ sectionName: String, sectionColor: UIColor, possibleNewOrder: ListItemStatusOrder?, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionPlainResult, DatabaseError> {
        
        func transactionContent(realm: Realm) -> ProvResult<AddSectionPlainResult, DatabaseError>? {
            
            let addResult: AddSectionPlainResult = {
                if let section = realm.objects(Section.self).filter(Section.createFilter(sectionName, listUuid: list.uuid)).first
                    
                {
                    section.color = sectionColor
                    realm.add(section, update: true) // TODO is this necessary?
                    return AddSectionPlainResult(section: section, isNew: false)
                } else {
                    let section = Section(uuid: UUID().uuidString, name: sectionName, color: sectionColor, list: list, order: (status: .done, order: 123)) // TODO!!!!!!!!!!!!!! order for now leaving this out because it's not clear how list items / sections will be re-implemented to support real time sync. If we use RealmSwift.List, order field can be removed.
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
    
    func getOrCreate(name: String, color: UIColor, list: List, status: ListItemStatus, notificationToken: NotificationToken, realm: Realm, doTransaction: Bool = true) -> Section? {
        
        func appendSection(section: Section) -> Section? {
            
            func transactionContent(realm: Realm) -> Section? {
                list.sections(status: status).append(section)
                return section
            }
            
            
            let sectionMaybe: Section? = {
                if doTransaction {
                    return doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: realm, {realm in
                        return transactionContent(realm: realm)
                    })
                } else {
                    return transactionContent(realm: realm)
                }
            }()
         
            return sectionMaybe
        }
        
        
        if let section = list.sections(status: status).filter(Section.createFilterWithName(name)).first { // The target status already contains the section
            return section
        
        } else if let section = loadSectionSync(name, list: list).getOk().flatMap({$0}) { // The target status doesn't contain the section, but it exists
            return appendSection(section: section)
            
        } else { // The section doesn't exist
            let section = Section(uuid: UUID().uuidString, name: name, color: color, list: list, order: ListItemStatusOrder(status: status, order: 0)) // TODO!!!!!!!!! remove order from sections
            return appendSection(section: section)
        }
    }
    
    // Load the sections directly from Realm - to ensure the resulting RealmSwift.List references a realm (which is not the case when using "copy") as well as it's fetched from the current thread.
    // RealmSwift.List not referencing a Realm currently results in an exception when calling filter on it - "This method may only be called on RLMArray instances retrieved from an RLMRealm"
    func sectionsSync(list: List, status: ListItemStatus) -> RealmSwift.List<Section>? {
        if let l: List = loadSync(filter: List.createFilter(list.uuid))?.first {
            return l.sections(status: status)
        } else {
            return nil
        }
    }
}

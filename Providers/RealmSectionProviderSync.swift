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

class RealmSectionProviderSync: RealmProvider {

    func loadSectionWithUnique(_ unique: SectionUnique) -> Section? {
        return loadFirstSync(predicate: Section.createFilter(unique: unique))
    }

    func loadSection(_ name: String, list: List) -> Section? {
        return loadSections([name], list: list).map{ $0.first }.getOk()?.flatMap{ $0 } // backwards compatibility - transform result to optional. Note that we should change all these methods to use result
    }

    func loadSections(_ names: [String], list: List) -> ProvResult<Results<Section>, DatabaseError> {
        if let sections: Results<Section> = loadSync(predicate: Section.createFilterWithNames(names, listUuid: list.uuid)) {
            return .ok(sections)
        } else {
            return .err(.unknown)
        }
    }

    // Loads sections with given name from all the lists
    func loadSections(_ name: String) -> Results<Section>? {
        return loadSync(predicate: Section.createFilterWithName(name))
    }

    // For unit tests
    func loadAllSections() -> Results<Section>? {
        return loadSync(predicate: nil)
    }

    func saveSections(_ sections: [Section]) -> Bool {
        let sections: [Section] = sections.map{$0.copy()}
        return saveObjsSync(sections, update: true)
    }

    func remove(_ section: Section, notificationTokens: [NotificationToken], markForSync: Bool) -> Bool {
        return remove(section.unique, notificationTokens: notificationTokens, markForSync: markForSync)
    }

    func removeAllWithName(_ sectionName: String, markForSync: Bool) -> [Section]? {
        guard let sections = loadSections(sectionName) else { logger.v("Sections is nil"); return nil }
        if !sections.isEmpty {
            _ = doInWriteTransactionSync({ realm -> Results<Section> in
                for section in sections {
                    _ = removeSectionAndDependencies(realm, sectionUnique: section.unique, markForSync: markForSync)
                }
                return sections
            })
            return sections.toArray()
        } else {
            logger.d("No sections with name: \(sectionName) - nothing to remove") // this is not an error, this can be used e.g. in the autosuggestions where we list also category names.
            return []
        }
    }

    func remove(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool) -> Bool {
        return removeSectionAndDependencies(sectionUnique, notificationTokens: notificationTokens, markForSync: markForSync)
    }

    func removeSectionAndDependencies(_ sectionUnique: SectionUnique, notificationTokens: [NotificationToken], markForSync: Bool) -> Bool {
        return doInWriteTransactionSync(withoutNotifying: notificationTokens) {[weak self] realm in
            if let weakSelf = self {
                _ = weakSelf.removeSectionAndDependencies(realm, sectionUnique: sectionUnique, markForSync: markForSync)
                return true
            } else {
                logger.e("self is nil")
                return false
            }
        } ?? false
    }

    // Expected to be executed in a transaction
    func removeSectionAndDependencies(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {

        _ = removeSectionDependencies(realm, sectionUnique: sectionUnique, markForSync: markForSync)

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

    func removeSectionDependencies(_ realm: Realm, sectionUnique: SectionUnique, markForSync: Bool) -> Bool {
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
    func sectionSuggestionsContainingText(_ text: String) -> [String] {

        return withRealmSync({ realm in

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
        }) ?? []
    }

    func removeSectionIfEmpty(_ realm: Realm, sectionUnique: SectionUnique) {
        if realm.objects(ListItem.self).filter(ListItem.self.createFilterWithSection(sectionUnique)).isEmpty { // if no list items reference the section
            let dbSection = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique))
            realm.delete(dbSection)
        }
    }
    
    // add/update and save (TODO better method name)
    // Used for .todo status (list has .todo sections)
    func mergeOrCreateSection(_ sectionName: String, sectionColor: UIColor, overwriteColorIfAlreadyExists: Bool = true, status: ListItemStatus, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionResult, DatabaseError> {

        if status != .todo {
            // This method works only for .todo - it updates the list's .todo sections (.done and .stash have to sections list in the list)
            return .err(.invalidInput)
        }

        guard let sections = sections(list: list, status: status) else {
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
                    let section = Section(name: sectionName, color: sectionColor, list: list, status: status)
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
    // Used for .done / .stash status (list has only .todo sections)
    func mergeOrCreateSection(_ sectionName: String, sectionColor: UIColor, list: List, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> ProvResult<AddSectionPlainResult, DatabaseError> {

        if status == .todo {
            // This method currently doesn't support a .todo status, since it doesn't take care of appending the section to the list's .todo sections
            // for .todo use the other mergeOrCreateSection version
            return .err(.invalidInput)
        }

        func transactionContent(realm: Realm) -> ProvResult<AddSectionPlainResult, DatabaseError>? {

            let addResult: AddSectionPlainResult = {
                let sectionUnique = SectionUnique(name: sectionName, listUuid: list.uuid, status: status)
                if let section = realm.objects(Section.self).filter(Section.createFilter(unique: sectionUnique)).first { // exists
                    section.color = sectionColor
                    realm.add(section, update: true) // TODO is this necessary?
                    return AddSectionPlainResult(section: section, isNew: false)
                } else { // doesn't exist
                    let section = Section(name: sectionName, color: sectionColor, list: list, status: status)
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

    public func move(from: Int, to: Int, sections: RealmSwift.List<Section>, notificationToken: NotificationToken) -> Bool {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: sections.realm) {realm -> Bool in
            sections.move(from: from, to: to)
            return true
        }
        return successMaybe ?? false
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
            let section = Section(name: name, color: color, list: list, status: status)
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
                let section = Section(name: name, color: color, list: list, status: status)
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
    func sections(list: List, status: ListItemStatus) -> RealmSwift.List<Section>? {
        if let l: List = loadSync(predicate: List.createFilter(uuid: list.uuid))?.first {
            return l.sections(status: status)
        } else {
            return nil
        }
    }
}

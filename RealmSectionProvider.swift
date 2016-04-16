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

class RealmSectionProvider: RealmProvider {
    
    func loadSectionWithUuid(uuid: String, handler: Section? -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.loadFirst(mapper, filter: DBSection.createFilter(uuid), handler: handler)
    }
    
    func loadSection(name: String, list: List, handler: Section? -> ()) {
        loadSections([name], list: list) {sections in
            handler(sections.first)
        }
    }
    
    func loadSections(names: [String], list: List, handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.load(mapper, filter: DBSection.createFilterWithNames(names, listUuid: list.uuid), handler: handler)
    }

    // Loads sections with given name from all the lists
    func loadSections(name: String, handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.load(mapper, filter: DBSection.createFilterWithName(name), handler: handler)
    }

    
    func saveSection(section: Section, handler: Bool -> ()) {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        
        self.saveObj(dbSection, handler: handler)
    }
    
    func saveSections(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    func remove(section: Section, markForSync: Bool, handler: Bool -> ()) {
        remove(section.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeAllWithName(sectionName: String, markForSync: Bool, handler: Bool -> ()) {
        loadSections(sectionName) {[weak self] sections in guard let weakSelf = self else {return}
            if !sections.isEmpty {
                weakSelf.doInWriteTransaction({realm in
                    for section in sections {
                        weakSelf.removeSectionAndDependenciesSync(realm, sectionUuid: section.uuid, markForSync: markForSync)
                    }
                    return true
                }, finishHandler: {success in
                    handler(success ?? false)
                })
                
            } else {
                QL3("Didn't find the section to be removed: \(sectionName)")
                handler(false)
            }
        }
    }
    
    func remove(sectionUuid: String, markForSync: Bool, handler: Bool -> Void) {
        removeSectionAndDependencies(sectionUuid, markForSync: markForSync, handler: handler)
    }
    
    func removeSectionAndDependencies(sectionUuid: String, markForSync: Bool, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                weakSelf.removeSectionAndDependenciesSync(realm, sectionUuid: sectionUuid, markForSync: markForSync)
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
    func removeSectionAndDependenciesSync(realm: Realm, sectionUuid: String, markForSync: Bool) -> Bool {
        
        // delete list items referencing the section
        let dbListItems = realm.objects(DBListItem).filter(DBListItem.createFilterWithSection(sectionUuid))
        let toRemoveListItems = dbListItems.map{DBRemoveListItem($0)} // create this before the delete or it crashes
        realm.delete(dbListItems)
        if markForSync {
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        
        // delete section
        if let dbSection = realm.objects(DBSection).filter(DBSection.createFilter(sectionUuid)).first {
            let toRemove = DBSectionToRemove(dbSection) // create this before the delete or it crashes TODO!!!! also in other places of the app, this error is in several other providers
            realm.delete(dbSection)
            if markForSync {
                realm.add(toRemove, update: true)
            }
            return true
        } else {
            QL3("Didn't find section to be deleted: \(sectionUuid)")
            return false
        }
    }
    
    func update(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(text: String, handler: [String] -> Void) {
        withRealm({ realm in
            let sectionNames: [String] = realm.objects(DBSection).filter(DBSection.createFilterNameContains(text)).map{$0.name}
            let categoryNames: [String] = realm.objects(DBProductCategory).filter(DBProductCategory.createFilterNameContains(text)).map{$0.name}
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
    
    func removeSectionIfEmptySync(realm: Realm, sectionUuid: String) {
        if realm.objects(DBListItem).filter(DBListItem.createFilterWithSection(sectionUuid)).isEmpty { // if no list items reference the section
            let dbSection = realm.objects(DBSection).filter(DBSection.createFilter(sectionUuid))
            realm.delete(dbSection)
        }
    }
    
    func clearSectionTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveSection.self, DBRemoveSection.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamps(sectionsUpdateDicts: [[String: AnyObject]], handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for dict in sectionsUpdateDicts {
                QL1("Saving dictionaries for section updates: \(sectionsUpdateDicts)")
                realm.create(DBSection.self, value: dict, update: true)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}

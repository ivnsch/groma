//
//  SectionProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs
import RealmSwift

class SectionProviderImpl: SectionProvider {
    
    let dbProvider = RealmListItemProvider()
    let remoteProvider = RemoteSectionProvider()
    
    func loadSection(_ name: String, list: List, handler: @escaping (ProviderResult<Section?>) -> ()) {
        DBProv.sectionProvider.loadSection(name, list: list) {dbSectionMaybe in
            handler(ProviderResult(status: .success, sucessResult: dbSectionMaybe))
            
            //            // TODO is this necessary here?
            //            self.remoteProvider.section(name, list: list) {remoteResult in
            //
            //                if let remoteSection = remoteResult.successResult {
            //                    let section = SectionMapper.SectionWithRemote(remoteSection)
            //                    handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: section))
            //                } else {
            //                    print("Error getting remote product, status: \(remoteResult.status)")
            //                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            //                    handler(ProviderResult(status: providerStatus))
            //                }
            //            }
        }
    }
    
    func remove(_ sectionUuid: String, notificationTokens: [NotificationToken], listUuid: String?, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.sectionProvider.remove(sectionUuid, notificationTokens: notificationTokens, markForSync: true) {removed in
            handler(ProviderResult(status: removed ? .success : .databaseUnknown))
//            if removed {
//                
//                Prov.listItemsProvider.removeSectionFromListItemsMemCacheIfExistent(sectionUuid, listUuid: listUuid) {result in
//                    if !result.success {
//                        QL4("Couldn't remove section from mem cache: \(result)")
//                    }
//                }
//                
//                if remote {
//                    self?.remoteProvider.removeSection(sectionUuid) {remoteResult in
//                        if remoteResult.success {
//                            DBProv.sectionProvider.clearSectionTombstone(sectionUuid) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    QL4("Couldn't delete tombstone for section: \(sectionUuid)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
//            }
        }
    }
    
    func remove(_ section: Section, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<Any>) -> ()) {
        remove(section.uuid, notificationTokens: notificationTokens, listUuid: section.list.uuid, remote: true) {result in
            if result.success {
                handler(result)
            } else {
                QL3("Couldn't remove section: \(section), result: \(result)")
                handler(result)
            }
        }
    }
    
    func removeAllWithName(_ sectionName: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {

        DBProv.sectionProvider.removeAllWithName(sectionName, markForSync: remote) {[weak self] removedSectionsMaybe in
            if let removedSections = removedSectionsMaybe {
                
                Prov.listItemsProvider.invalidateMemCache()
                
                handler(ProviderResult(status: .success))
                
                if remote {
                    self?.remoteProvider.removeSectionsWithName(sectionName) {remoteResult in
                        if remoteResult.success {
                            
                            let removedSectionsUuids = removedSections.map{$0.uuid}
                            DBProv.sectionProvider.clearSectionsTombstones(removedSectionsUuids) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstones for sections: \(removedSections)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Couldn't remove sections from db for name: \(sectionName)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func update(_ section: Section, input: SectionInput, _ handler: @escaping (ProviderResult<Section>) -> Void) {
        if let updateSection = DBProv.sectionProvider.update(section, input: input) {
            handler(ProviderResult(status: .success, sucessResult: updateSection))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }

    func sectionSuggestionsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> ()) {
        DBProv.sectionProvider.sectionSuggestionsContainingText(text) {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: dbSuggestions))
        }
    }

    func sections(_ names: [String], list: List, handler: @escaping (ProviderResult<[Section]>) -> ()) {
        DBProv.sectionProvider.loadSections(names, list: list) {sections in
            if let sections = sections {
                handler(ProviderResult(status: .success, sucessResult: sections.toArray()))
            } else {
                QL4("Couldn't load items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func mergeOrCreateSection(_ sectionName: String, sectionColor: UIColor, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, _ handler: @escaping (ProviderResult<Section>) -> Void) {
        
        // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
        loadSection(sectionName, list: list) {result in
            
            // TODO!!!! check if the optional section from db works otherwise return to using .Success / .NotFound with non optional
            // load section and update or create one
            // if we find a section with the name we update it - this is for the case the user changes the color of section when editing item
             if let existingSectionMaybe = result.sucessResult {
                if let existingSection = existingSectionMaybe {
                    let updatedSection = existingSection.copy(color: sectionColor)
                    handler(ProviderResult(status: .success, sucessResult: updatedSection))
                    
                } else {
                    if let order = possibleNewOrder {
                        let section = Section(uuid: UUID().uuidString, name: sectionName, color: sectionColor, list: list, order: order, status: status)
                        handler(ProviderResult(status: .success, sucessResult: section))
                        
                    } else { // no order known in advance - fetch listItems to count how many sections, order at the end
                        
                        Prov.listItemsProvider.listItems(list, sortOrderByStatus: status, fetchMode: ProviderFetchModus.first) {result in
                            
                            if let listItems = result.sucessResult {
                                let order = listItems.sectionCount(status)
                                
                                let section = Section(uuid: UUID().uuidString, name: sectionName, color: sectionColor, list: list, order: ListItemStatusOrder(status: status, order: order), status: status)
                                
                                QL1("Section: \(sectionName) doesn't exist, will create a new one. New uuid: \(section.uuid). List uuid: \(list.uuid)")
                                handler(ProviderResult(status: .success, sucessResult: section))
                                
                            } else {
                                print("Error: loading section: \(result.status)")
                                handler(ProviderResult(status: .databaseUnknown))
                            }
                        }
                    }
                }
                
            } else {
                print("Error: loading section: \(result.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    
    public func move(from: Int, to: Int, sections: RealmSwift.List<Section>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.sectionProvider.move(from: from, to: to, sections: sections, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
}

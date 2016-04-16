//
//  SectionProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class SectionProviderImpl: SectionProvider {
    
    let dbProvider = RealmListItemProvider()
    let remoteProvider = RemoteSectionProvider()
    
    func loadSection(name: String, list: List, handler: ProviderResult<Section?> -> ()) {
        DBProviders.sectionProvider.loadSection(name, list: list) {dbSectionMaybe in
            handler(ProviderResult(status: .Success, sucessResult: dbSectionMaybe))
            
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
    
    func remove(sectionUuid: String, listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        
        DBProviders.sectionProvider.remove(sectionUuid, markForSync: true) {[weak self] removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseUnknown))
            if removed {
                
                Providers.listItemsProvider.removeSectionFromListItemsMemCacheIfExistent(sectionUuid, listUuid: listUuid) {result in
                    if !result.success {
                        QL4("Couldn't remove section from mem cache: \(result)")
                    }
                }
                
                if remote {
                    self?.remoteProvider.removeSection(sectionUuid) {remoteResult in
                        if remoteResult.success {
                            DBProviders.sectionProvider.clearSectionTombstone(sectionUuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for section: \(sectionUuid)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            }
        }
    }
    
    func remove(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        remove(section.uuid, listUuid: section.list.uuid, remote: remote) {result in
            if result.success {
                handler(result)
            } else {
                QL3("Couldn't remove section: \(section), result: \(result)")
                handler(result)
            }
        }
    }
    
    func removeAllWithName(sectionName: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        Providers.listItemsProvider.invalidateMemCache()
        DBProviders.sectionProvider.removeAllWithName(sectionName, markForSync: true) {removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseUnknown))
            if removed && remote {
                // TODO!! server
            }
        }
    }
    
    func update(sections: [Section], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        DBProviders.sectionProvider.update(sections) {[weak self] updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
            if updated && remote {
                
                self?.remoteProvider.updateSections(sections) {remoteResult in
                    if let timestamp = remoteResult.successResult {
                        let updateDicts: [[String: AnyObject]] = sections.map {
                            DBSyncable.timestampUpdateDict($0.uuid, lastServerUpdate: timestamp)
                        }
                        DBProviders.sectionProvider.updateLastSyncTimeStamps(updateDicts) {success in
                            if !success {
                                QL4("Couldn't update last server update timestamps for sections: \(sections)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Remote call no success: \(remoteResult) items: \(sections)")
                            Providers.listItemsProvider.invalidateMemCache()
                            handler(result)
                        })
                    }
                }
            }
        }
    }

    func update(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        update([section], remote: remote, handler)
    }
    
    func sectionSuggestionsContainingText(text: String, _ handler: ProviderResult<[String]> -> ()) {
        DBProviders.sectionProvider.sectionSuggestionsContainingText(text) {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }

    func sections(names: [String], list: List, handler: ProviderResult<[Section]> -> ()) {
        DBProviders.sectionProvider.loadSections(names, list: list) {dbSections in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSections))
        }
    }
    
    func mergeOrCreateSection(sectionName: String, sectionColor: UIColor, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, _ handler: ProviderResult<Section> -> Void) {
        
        // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
        loadSection(sectionName, list: list) {result in
            
            // TODO!!!! check if the optional section from db works otherwise return to using .Success / .NotFound with non optional
            // load section and update or create one
            // if we find a section with the name we update it - this is for the case the user changes the color of section when editing item
             if let existingSectionMaybe = result.sucessResult {
                if let existingSection = existingSectionMaybe {
                    let updatedSection = existingSection.copy(color: sectionColor)
                    handler(ProviderResult(status: .Success, sucessResult: updatedSection))
                    
                } else {
                    if let order = possibleNewOrder {
                        let section = Section(uuid: NSUUID().UUIDString, name: sectionName, color: sectionColor, list: list, order: order)
                        handler(ProviderResult(status: .Success, sucessResult: section))
                        
                    } else { // no order known in advance - fetch listItems to count how many sections, order at the end
                        
                        Providers.listItemsProvider.listItems(list, sortOrderByStatus: .Stash, fetchMode: ProviderFetchModus.First) {result in
                            
                            if let listItems = result.sucessResult {
                                let order = listItems.sectionCount(status)
                                
                                let section = Section(uuid: NSUUID().UUIDString, name: sectionName, color: sectionColor, list: list, order: ListItemStatusOrder(status: status, order: order))
                                
                                QL1("Section: \(sectionName) doesn't exist, will create a new one. New uuid: \(section.uuid). List uuid: \(list.uuid)")
                                handler(ProviderResult(status: .Success, sucessResult: section))
                                
                            } else {
                                print("Error: loading section: \(result.status)")
                                handler(ProviderResult(status: .DatabaseUnknown))
                            }
                        }
                    }
                }
                
            } else {
                print("Error: loading section: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
}


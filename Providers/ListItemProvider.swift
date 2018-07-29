//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO own file
// TODO review if it's really necessary to pass the realm with the token (instead of simply doing Realm() where it's needed)
// if it's not necessary, remove RealmData and pass only the notification token.
public struct RealmData {
    public var realm: Realm
    public var tokens: [NotificationToken]

    public init(realm: Realm, token: NotificationToken) {
        self.init(realm: realm, tokens: [token])
    }

    public init(realm: Realm, tokens: [NotificationToken]) {
        self.realm = realm
        self.tokens = tokens
    }

    public func invalidateTokens() {
        tokens.forEach { $0.invalidate() }
    }
}

public enum SwitchListItemMode {case single, all}

public protocol ListItemProvider {
  
    func remove(_ listItem: ListItem, remote: Bool, token: RealmToken?, _ handler: @escaping (ProviderResult<Any>) -> ())

    func removeListItem(_ listItemUuid: String, listUuid: String, remote: Bool, token: RealmToken?, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func remove(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

//    func add(listItem: ListItem, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<ListItem> -> ())

//    func add(listItems: [ListItem], status: ListItemStatus, remote: Bool, _ handler: ProviderResult<[ListItem]> -> ())
    
    /**
    Adds a new list item
    The corresponding product and section will be added if no one with given unique exists
    - parameter list: list where the list item is
    - parameter order:  position of listitem in section. If nil will be appended at the end TODO always pass
    - parameter possibleNewSectionOrder: if the section is determined to be new, position of section in list. If the section already exists this is not used. If nil this will be at the end of the list (an additional database fetch will be made to count the sections).
    - parameter handler
    */
    func add(_ listItemInput: ListItemInput, status: ListItemStatus, list: List, order orderMaybe: Int?, possibleNewSectionOrder: ListItemStatusOrder?, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void)

    func add(_ listItemInputs: [ListItemInput], status: ListItemStatus, list: List, order orderMaybe: Int?, possibleNewSectionOrder: ListItemStatusOrder?, token: RealmToken?, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void)
    
    // product/section same logic as add(listItemInput) (see doc above). TODO review other update methods maybe these should be removed or at least made private, since they don't have this product/section logic and there's no reason from outside of the provider to use a different logic (which would be to update the linked product/section directly).
    func update(_ listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, _ remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<(listItem: ListItem, replaced: Bool)>) -> Void)
    
    func addListItem(_ product: QuantifiableProduct, status: ListItemStatus, sectionName: String, sectionColor: UIColor, quantity: Float, list: List, note: String?, order orderMaybe: Int?, storeProductInput: StoreProductInput?, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void)
    
    // TODO what are note and order parameters here if we are adding an array?
    func add(_ prototypes: [ListItemPrototype], status: ListItemStatus, list: List, note: String?, order orderMaybe: Int?, token: RealmToken?, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void)

    func update(_ listItem: ListItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func update(_ listItems: [ListItem], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())
    
    func updateListItemsOrder(_ listItems: [ListItem], status: ListItemStatus, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // The counterpart of updateListItemsOrder to process the update when it comes via websocket. We need a special service because websockets sends us a reduced payload (only the order and sections).
    func updateListItemsOrderLocal(_ orderUpdates: [RemoteListItemReorder], sections: [Section], status: ListItemStatus, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // TODO rename sortOrderByStatus in only status since now this also filters by status
    func listItems(_ list: List, sortOrderByStatus: ListItemStatus, fetchMode: ProviderFetchModus, _ handler: @escaping (ProviderResult<Results<ListItem>>) -> Void)

    func listItems(_ uuids: [String], _ handler: @escaping (ProviderResult<[ListItem]>) -> Void)
    
    // This is currently used only to retrieve possible product's list item on receiving a websocket notification with a product update
    func listItem(_ product: Product, list: List, _ handler: @escaping (ProviderResult<ListItem?>) -> ())
    
    func increment(_ listItem: ListItem, status: ListItemStatus, delta: Float, remote: Bool, tokens: [NotificationToken], _ handler: @escaping (ProviderResult<ListItem>) -> ())

    func increment(_ increment: RemoteListItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<ListItem>) -> ())
    
    func listItems<T>(list: List, ingredient: Ingredient, mapper: @escaping (Results<ListItem>) -> T, _ handler: @escaping (ProviderResult<T>) -> Void)
    
    /**
    Updates done status of listItems, and their "order" field such that they are positioned at the end of the new section.
    ** Note ** word SWITCH: done expected to be != all listItem.done. This operation is meant to be used to append the items at the end of the section corresponding to new "done" state
    so we must not use it against the same tableview/state where we already are, because the items will update "order" field incorrectly by basically being appended after themselves.
    TODO cleaner implementation, maybe split in smaller methods. The method should not lead to inconsistent result when used in wrong context (see explanation above)
    param: orderInDstStatus: To override default dst order with a manual order. This is used for undo cell, where we want to the item to be inserted back at the original position.
    */
    func switchStatus(_ listItem: ListItem, list: List, status1: ListItemStatus, status: ListItemStatus, orderInDstStatus: Int?, remote: Bool, _ handler: @escaping (ProviderResult<ListItem>) -> Void)
    
    func switchAllToStatus(_ listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void)
    
    // Websocket list item switch
    func switchStatusLocal(_ listItemUuid: String, status1: ListItemStatus, status: ListItemStatus, _ handler: @escaping (ProviderResult<ListItem>) -> Void)

    // Websocket all list item switch
    func switchAllStatusLocal(_ result: RemoteSwitchAllListItemsLightResult, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // Adds inventory + history items and moves list items to stash
    func buyCart(_ listItems: [ListItem], list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    // Websocket
    func storeBuyCartResult(_ switchedResult: RemoteBuyCartResult, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func invalidateMemCache()
    
    // MARK: - GroupItem / ListItem
    
    /**
    * Converts group items in list items and adds them to list
    */
    func add(_ groupItems: [GroupItem], status: ListItemStatus, list: List, _ handler: @escaping (ProviderResult<[ListItem]>) -> ())

    func addGroupItems(_ group: ProductGroup, status: ListItemStatus, list: List, _ handler: @escaping (ProviderResult<[ListItem]>) -> ())
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(_ status: ListItemStatus, list: List, fetchMode: ProviderFetchModus, _ handler: @escaping (ProviderResult<Int>) -> Void)
    
    func removeSectionFromListItemsMemCacheIfExistent(_ sectionUuid: String, listUuid: String?, handler: @escaping (ProviderResult<Any>) -> Void)
    
    
    
    /// Quick add
    func addNew(quantifiableProduct: QuantifiableProduct, store: String, list: List, quantity: Float, note: String?, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<AddListItemResult>) -> Void)
    
    func addNew(listItemInput: ListItemInput, list: List, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<AddListItemResult>) -> Void)

    func addNewStoreProduct(listItemInput: ListItemInput, list: List, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<(StoreProduct, Bool)>) -> Void)
    
    func addNew(listItemInputs: [ListItemInput], list: List, status: ListItemStatus, overwriteColorIfAlreadyExists: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<[(listItem: ListItem, isNew: Bool)]>) -> Void)

    /// Quick add
    func addToCart(quantifiableProduct: QuantifiableProduct, store: String, list: List, quantity: Float, realmData: RealmData, _ handler: @escaping (ProviderResult<AddCartListItemResult>) -> Void)
    
    func updateNew(_ listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<(UpdateListItemResult)>) -> Void)
    
    func deleteNew(indexPath: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<DeleteListItemResult>) -> Void)
    
    /// Move which takes section into account (currently only used by .todo)
    func move(from: IndexPath, to: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<MoveListItemResult>) -> Void)
    
    /// Move without section (cart/stash)
    func moveCartOrStash(from: IndexPath, to: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func calculateCartStashAggregate(list: List, _ handler: @escaping (ProviderResult<ListItemsCartStashAggregate>) -> Void)
    
    // MARK: - Buy
    
    func buyCart(list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // MARK: - Switch
    
    func switchTodoToCartSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<SwitchListItemResult>) -> Void)
    
    func switchCartToStashSync(listItems: [ListItem], list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func switchStashToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func switchCartToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func removePossibleSectionDuplicates(list: List, status: ListItemStatus, _ handler: @escaping (ProviderResult<Bool>) -> Void)
}

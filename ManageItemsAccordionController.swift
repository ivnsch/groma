//
//  ManageItemsAccordionController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift
import Providers


class ManageItemsAccordionController: UIViewController {

    fileprivate var tableViewController: UITableViewController!
    fileprivate var tableView: UITableView! {
        return tableViewController.tableView
    }
    
    fileprivate var items: Results<Item>?
    fileprivate var realmData: RealmData?

    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<AddEditNameNameColorController>?

    fileprivate var itemsRows = [String: ItemSectionRows]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        load()
        
        topEditSectionControllerManager = initEditSectionControllerManager()

//        addEditButton()
        
        tableView.register(UINib(nibName: "ManageItemsSectionView", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
    }
    
    fileprivate func initEditSectionControllerManager() -> ExpandableTopViewController<AddEditNameNameColorController> {
        let top: CGFloat = 0 // we currently use the system's nav bar so there's no offset (view controller starts below it)
        let manager: ExpandableTopViewController<AddEditNameNameColorController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickEditItemHeight, animateTableViewInset: true, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.addEditNameNameColorController()
            controller.delegate = self
            return controller
        }
//        manager.delegate = self
        return manager
    }
    
    fileprivate func load() {
        Prov.itemsProvider.items(sortBy: .alphabetic, successHandler{[weak self] items in
            self?.items = items
            self?.initNotifications()
        })
    }
    
    fileprivate func initNotifications() {
        guard let items = items else {logger.e("No sections"); return}
        guard let realm = items.realm else {logger.e("No realm"); return}

        realmData?.invalidateTokens()
        
        let notificationToken = items.observe {changes in
            
            switch changes {
            case .initial: break
            case .update(_, let deletions, let insertions, let modifications):
                logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        realmData = RealmData(realm: realm, token: notificationToken)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destination as? UITableViewController
            tableViewController?.tableView.dataSource = self
            tableViewController?.tableView.delegate = self
            
            tableViewController?.tableView.backgroundColor = Theme.defaultTableViewBGColor
            
            tableViewController?.tableView.reloadData()
        }
    }
    
    deinit {
        logger.v("Deinit mange items controller")
    }
    
    
    // MARK: - Editing
    
    fileprivate func addEditButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "tb_edit"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(onEditTap(_:)))
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableViewController.setEditing(editing, animated: animated)
    }
    
    @objc func onEditTap(_ sender: UIBarButtonItem) {
        setEditing(!isEditing, animated: true)
    }
    
    // MARK: - 
    
    fileprivate func onItemTapInEditMode(section: Int) {
        guard let items = items else {logger.e("No items"); return}
        let item = items[section]
        
        topEditSectionControllerManager?.expand(true)
        
        topEditSectionControllerManager?.controller?.config(prefillData: AddEditNameNameColorControllerInputs(
            name: item.name,
            buttonSelected: item.edible,
            nameColorName: item.category.name,
            nameColorColor: item.category.color

            ), settings: AddEditNameNameColorControllerSettings(
                namePlaceholder: trans("placeholder_name"),
                nameEmptyValidationMessage: trans("validation_name_not_empty"),
                buttonTitle: trans("edible_button_title"),
                nameNameColorPlaceholder: trans("placeholder_category_name"),
                nameNameColorEmptyValidationMessage: trans("validation_category_name_not_empty")
                
            ), editingObj: item
        )
        //        topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
    }
    
    /// For now we prefer to avoid having to store
    
    
    fileprivate func getSectionIndex(itemUuid: String) -> Int? {
        guard let items = items else {logger.e("No items"); return nil}
        for (index, item) in items.enumerated() {
            if item.uuid == itemUuid {
                return index
            }
        }
        return nil
    }
    
    fileprivate func onItemTapInNormalMode(section: Int) {
        guard let items = items else {logger.e("No items"); return}
        let item = items[section]
        
//        for (itemUuid, productForExpandedItem) in productsForExpandedItems {
//            /// close currently expanded
//            if let sectionIndex = getSectionIndex(itemUuid: itemUuid) {
//                productsForExpandedItems[itemUuid] = nil
//                tableView.reloadSections(IndexSet([sectionIndex]), with: Theme.defaultRowAnimation)
//            }
//        }
        
        if itemsRows[item.uuid] == nil { // it's closed - open it
            
            Prov.productProvider.products(itemUuid: item.uuid, successHandler{[weak self] products in
                let sectionRows = ItemSectionRows()
                sectionRows.rows = products.toArray()
                self?.itemsRows[item.uuid] = sectionRows
                self?.tableView.reloadSections(IndexSet([section]), with: .none)
            })
            
        } else { // it's already open - close it
            
            itemsRows[item.uuid] = nil
            tableView.reloadSections(IndexSet([section]), with: .none)
        }
    }
    
    fileprivate func onRowTap(indexPath: IndexPath) {
        
        guard let items = items else {logger.e("No items"); return}
        
        let item = items[indexPath.section]
        if let itemRows = itemsRows[item.uuid] {
            let row = itemRows.rows[indexPath.row]
            if let product = row as? Product {
                onProductTap(indexPath: indexPath, product: product, item: item)
                
            } else if let quantifiableProduct = row as? QuantifiableProduct {
                onQuantifiableProductTap(indexPath: indexPath, quantifiableProduct: quantifiableProduct, item: item)
            }

        } else {
            logger.e("Invalid state: No item rows for item uuid: \(item.uuid)")
        }
    }
    
    fileprivate func onProductTap(indexPath: IndexPath, product: Product, item: Item) {
        
        func reloadSection() {
            tableView.reloadSections(IndexSet([indexPath.section]), with: .none)
        }
        
        if let itemRows = itemsRows[item.uuid] {
            
            if itemRows.isExpanded(productUuid: product.uuid) {
                itemRows.close(productUuid: product.uuid)
                reloadSection()

            } else {
                Prov.productProvider.quantifiableProducts(product: product, successHandler {[weak self] quantifiableProducts in
                    self?.itemsRows[item.uuid]?.insert(productUuid: product.uuid, quantifiableProducts: quantifiableProducts)
                    //                self?.quantifiableProducts[product.uuid] = quantifiableProducts
                    reloadSection()
                })
            }
 
        } else {
            logger.e("Invalid state: No item rows for item uuid: \(item.uuid)")
        }
    }

    fileprivate func onQuantifiableProductTap(indexPath: IndexPath, quantifiableProduct: QuantifiableProduct, item: Item) {
        print("quantifiable tap!")
        
        func reloadSection() {
            tableView.reloadSections(IndexSet([indexPath.section]), with: .none)
        }
        
        if let itemRows = itemsRows[item.uuid] {
            
            if itemRows.isExpanded(quantifiableProductUuid: quantifiableProduct.uuid) {
                itemRows.close(quantifiableProductUuid: quantifiableProduct.uuid)
                reloadSection()
                
            } else {
                Prov.productProvider.storeProducts(quantifiableProduct: quantifiableProduct, successHandler {[weak self] storeProducts in
                    self?.itemsRows[item.uuid]?.insert(quantifiableProductUuid: quantifiableProduct.uuid, storeProducts: storeProducts)
                    //                self?.quantifiableProducts[product.uuid] = quantifiableProducts
                    reloadSection()
                })
            }
            
        } else {
            logger.e("Invalid state: No item rows for item uuid: \(item.uuid)")
        }
    }
}



extension ManageItemsAccordionController: UITableViewDataSource, UITableViewDelegate, ManageItemsSectionViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as! ManageItemsSectionView
        
        guard let items = items else {logger.e("No item"); return sectionView}
        
        sectionView.sectionIndex = section
        sectionView.config(item: items[section], editing: isEditing)
        sectionView.delegate = self
        
        return sectionView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = items else {logger.e("No items"); return 0}
        let item = items[section]
        return itemsRows[item.uuid]?.rows.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        guard let items = items else {logger.e("No items"); return UITableViewCell()}

        let item = items[indexPath.section]
        if let itemRows = itemsRows[item.uuid] {
            let row = itemRows.rows[indexPath.row]
            
            if let product = row as? Product {
                let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! ManageItemsProductCell
                cell.config(product: product)
                return cell
                
            } else if let quantifiableProduct = row as? QuantifiableProduct {
                let cell = tableView.dequeueReusableCell(withIdentifier: "quantProductCell", for: indexPath) as! ManageItemsQuantifiableProductCell
                cell.config(quantifiableProduct: quantifiableProduct)
                return cell
                
            } else if let storeProduct = row as? StoreProduct {
                let cell = tableView.dequeueReusableCell(withIdentifier: "storeProductCell", for: indexPath) as! ManageItemsStoreProductCell
                cell.config(storeProduct: storeProduct)
                return cell
            }
            
            
        } else {
            logger.e("Invalid state: No products for item uuid: \(item.uuid)")
        }
            
        logger.e("Illegal state - should have returned cell")
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.ingredientsCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DimensionsManager.ingredientsCellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let items = items else {logger.e("No items"); return}
            let item = items[indexPath.section]
            if let rows = itemsRows[item.uuid] {
                let row = rows.rows[indexPath.row]
                
                if let product = row as? Product {
                    Prov.productProvider.delete(product, remote: true, successHandler{[weak self] in
                        self?.itemsRows[item.uuid]?.delete(productUuid: product.uuid)
                        self?.tableView.reloadSections(IndexSet([indexPath.section]), with: .none)
                    })
                    
                    
                } else if let quantifiableProduct = row as? QuantifiableProduct {
                    Prov.productProvider.deleteQuantifiableProduct(uuid: quantifiableProduct.uuid, remote: true, successHandler{[weak self] in
                        self?.itemsRows[item.uuid]?.delete(quantifiableProductUuid: quantifiableProduct.uuid)
                        self?.tableView.reloadSections(IndexSet([indexPath.section]), with: .none)
                    })
                    
                    
                } else if let storeProduct = row as? StoreProduct {
                    Prov.productProvider.delete(storeProduct, remote: true, successHandler {[weak self] in
                        self?.itemsRows[item.uuid]?.delete(storeProductUuid: storeProduct.uuid)
                        self?.tableView.reloadSections(IndexSet([indexPath.section]), with: .none)

                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        onRowTap(indexPath: indexPath)
    }
    
    
    // MARK: - ManageItemsSectionViewDelegate
    
    func onHeaderTap(section: Int, view: ManageItemsSectionView) {
        // There's currently no way to know that we are in edit mode (the sections don't get delete or reorder overlay), so we will just not use it and use long tap/single tap instead.
//        if isEditing {
//            onItemTapInEditMode(section: section)
//        } else {
            onItemTapInNormalMode(section: section)
//        }
    }

    func onHeaderLongTap(section: Int, view: ManageItemsSectionView) {
        onItemTapInEditMode(section: section)
    }
    
    func onDeleteSectionTap(section: Int, view: ManageItemsSectionView) {
        guard let items = items else {logger.e("No items"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        Prov.itemsProvider.delete(itemUuid: items[section].uuid, realmData: realmData, successHandler{[weak self] in
            self?.tableView.deleteSections(IndexSet([section]), with: Theme.defaultRowAnimation)
            
            /// Update section index for other headers (the not visible headers will be udpated when calling cellForRowAt)
            self?.tableView.applyToVisibleSections(f: {sectionIndex, view in
                
                let sectionView = (view as! ManageItemsSectionView)
                
                logger.w("apply to section at index: \(sectionIndex), name in cell: \(String(describing: sectionView.nameLabel.text)), item name at index: \(items[sectionIndex].name)")
                (view as! ManageItemsSectionView).sectionIndex = sectionIndex
            })
        })
    }
}

// MARK: - EditSectionViewControllerDelegate

extension ManageItemsAccordionController: AddEditNameNameColorControllerDelegate {
    
    func onSubmitAddEditNameNameColor(result: AddEditNameNameColorResult) {
        print("Submitted result: \(result)")
        // TODO
    }
}



fileprivate class ItemSectionRows {
    
    var rows: [Any] = []
    
    // TODO refactor quantifiable/store product methods. Are identical, except of types.
    
    // Quantifiable products
    
    func insert(productUuid: String, quantifiableProducts: [QuantifiableProduct]) {
        for (index, row) in rows.enumerated() {
            if ((row as? Product).map{$0.uuid == productUuid}) ?? false {
                rows.insertAll(index: index + 1, arr: quantifiableProducts)
            }
        }
    }
    
    func isExpanded(productUuid: String) -> Bool {
        for (index, row) in rows.enumerated() {
            if ((row as? Product).map{$0.uuid == productUuid}) ?? false {
                if let next = rows[safe: index + 1] {
                    if next is QuantifiableProduct {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func close(productUuid: String) {
        for (index, row) in rows.enumerated() {
            if ((row as? Product).map{$0.uuid == productUuid}) ?? false {
                // Remove all quantifiable products directly after product
                let i = index + 1
                while true {
                    guard i < rows.count else {return}
                    if rows[i] is Product {
                        return
                    } else {
                        rows.remove(at: i)
                    }
                }
            }
        }
    }
    
    func delete(productUuid: String) {
        close(productUuid: productUuid)
        for (index, row) in rows.enumerated() {
            if ((row as? Product).map{$0.uuid == productUuid}) ?? false {
                rows.remove(at: index)
            }
        }
    }
    
    // Store products
    
    func insert(quantifiableProductUuid: String, storeProducts: [StoreProduct]) {
        for (index, row) in rows.enumerated() {
            if ((row as? QuantifiableProduct).map{$0.uuid == quantifiableProductUuid}) ?? false {
                rows.insertAll(index: index + 1, arr: storeProducts)
            }
        }
    }
    
    func isExpanded(quantifiableProductUuid: String) -> Bool {
        for (index, row) in rows.enumerated() {
            if ((row as? QuantifiableProduct).map{$0.uuid == quantifiableProductUuid}) ?? false {
                if let next = rows[safe: index + 1] {
                    if next is StoreProduct {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func close(quantifiableProductUuid: String) {
        for (index, row) in rows.enumerated() {
            if ((row as? QuantifiableProduct).map{$0.uuid == quantifiableProductUuid}) ?? false {
                // Remove all quantifiable products directly after product
                let i = index + 1
                while true {
                    guard i < rows.count else {return}
                    if rows[i] is Product || rows[i] is QuantifiableProduct {
                        return
                    } else {
                        rows.remove(at: i)
                    }
                }
            }
        }
    }
    
    func delete(quantifiableProductUuid: String) {
        close(quantifiableProductUuid: quantifiableProductUuid)
        for (index, row) in rows.enumerated() {
            if ((row as? QuantifiableProduct).map{$0.uuid == quantifiableProductUuid}) ?? false {
                rows.remove(at: index)
            }
        }
    }
    
    
    
    func delete(storeProductUuid: String) {
        for (index, row) in rows.enumerated() {
            if ((row as? StoreProduct).map{$0.uuid == storeProductUuid}) ?? false {
                rows.remove(at: index)
            }
        }
    }
}

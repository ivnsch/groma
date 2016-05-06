//
//  StashListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 23/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class StashListItemsController: ListItemsController {
    
    @IBOutlet weak var emptyListView: UIView!

    override var status: ListItemStatus {
        return .Stash
    }
    
    override var isPullToAddEnabled: Bool {
        return false
    }
    
    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onUIReady?()
        
        topBar.setBackVisible(true)
        topBar.positionTitleLabelLeft(true, animated: false, withDot: true)
    }
    
    
    override var emptyView: UIView {
        return emptyListView
    }
    
    
    override func onListItemsOrderChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.updateListItemsOrder(tableViewListItems.map{$0.listItem}, status: status, remote: true, successHandler{result in
        })
    }
    
    override func topBarTitle(list: List) -> String {
        return "Back store"
    }
    
    private func resetAllItems() {
        if let list = currentList {
            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
                if let weakSelf = self {
                    Providers.listItemsProvider.switchAllToStatus(weakSelf.listItemsTableViewController.items, list: list, status1: .Stash, status: .Todo, remote: true) {result in
                        if result.success {
                            weakSelf.listItemsTableViewController.setListItems([])
                            weakSelf.close()
                        }
                    }
                }
            }
        }
    }
    
    override func setDefaultLeftButtons() {
        topBar.setBackVisible(true)
    }
    
    private func close() {
        listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
            self?.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func setEmptyUI(visible: Bool, animated: Bool) {
        super.setEmptyUI(visible, animated: animated)
        let hidden = !visible
        if animated {
            emptyListView.setHiddenAnimated(hidden)
        } else {
            emptyListView.hidden = hidden
        }
    }

    override func onTopBarBackButtonTap() {
        super.onTopBarBackButtonTap()
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Submit:
            resetAllItems()
        default: super.onTopBarButtonTap(buttonId)
        }
    }
    
    // MARK: - Right buttons
    
    override func rightButtonsDefault() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .Submit)]
    }
    
    override func rightButtonsOpeningQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .Submit)]
    }
    
    override func rightButtonsClosingQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .Submit)]
    }
    
    override func rightButtonsClosing() -> [TopBarButtonModel] {
        return []
    }
}

//
//  ReorderSectionTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers
import RealmSwift

protocol ReorderSectionTableViewControllerDelegateNew: class {
    func onSectionsUpdated()
    func onSectionSelected(_ section: Section)
    func canRemoveSection(_ section: Section, can: @escaping (Bool) -> Void)
    func onSectionRemoved(_ section: Section)
}

class ReorderSectionTableViewControllerNew: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections: RealmSwift.List<Section>? {
        didSet {
            initNotifications()
        }
    }
    fileprivate var notificationToken: NotificationToken?
    
    // For delete - Theoretically it should work without this, but when list items controller receives the delete (and update, for the other sections) notifications and reloads sections/cells after it, there's a crash because "Realm object has been deleted or invalidated". Couldn't figure out why this happens - the delete is done in the main thread, the notification should be send by Realm after everything is up to date, and list items controllers references a Realm list, which of course is also in the main thread, which should be up to date when receiving the notification. It's a timing issue, since it doesn't happen when debugging, i.e. advancing step by step to the reload of the sections/cells.
    // So, instead of updating list items controller with the notification token, we supress the list items controller notification with this token and instead trigger a reload of it via delegate.
    // For more details about this error see https://github.com/realm/realm-cocoa/issues/3195, Though there doesn't seem to be anything that clarifies this problem there - a conclusion from this thread is that long as we use the notification block everything is ok, but that's exactly what's causing the crash here.
    var listItemsNotificationToken: NotificationToken?
    
    var onViewDidLoad: VoidFunction?
    
    var cellHeight: CGFloat = DimensionsManager.listItemsHeaderHeight
    
    weak var delegate: ReorderSectionTableViewControllerDelegateNew?
    
    var status: ListItemStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        onViewDidLoad?()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Intentionally named setEdit not setEditing because onComplete optional parameter makes setEditing call ambiguous
    func setEdit(_ editing: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }
        tableView.setEditing(editing, animated: animated)
        super.setEditing(editing, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setEdit(true, animated: false)
        // cell starts small to blend with the collapsed original tableview and grows to normal size
        setCellHeight(DimensionsManager.defaultCellHeight, animated: true)
        
        tableView.bottomInset = DimensionsManager.listItemsPricesViewHeight + 10 // 10 - show a little empty space between the last item and the prices view
    }
    
    // Animate cell height
    func setCellHeight(_ height: CGFloat, animated: Bool) {
        cellHeight = height
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    fileprivate func initNotifications() {
        
        guard let sections = sections else {QL4("No sections"); return}
        
        self.notificationToken?.stop()
        
        let notificationToken = sections.addNotificationBlock {[weak self] changes in guard let weakSelf = self else {return}
            
            switch changes {
            case .initial:
                QL1("initial")
                
            case .update(_, let deletions, let insertions, let modifications):
                QL2("notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                
                
                weakSelf.tableView.beginUpdates()
                weakSelf.tableView.insertSections(IndexSet(insertions), with: .top)
                weakSelf.tableView.deleteSections(IndexSet(deletions), with: .top)
//                weakSelf.tableView.reloadSections(IndexSet(modifications), with: .none)
                weakSelf.tableView.endUpdates()
                
                
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        self.notificationToken = notificationToken
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionCell", for: indexPath) as! ReorderSectionCell
        if let sections = sections {
            cell.section = sections[indexPath.row]
        } else {
            QL4("No sections")
        }
        return cell
    }
    
    deinit {
        QL1("deinit")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let sections = sections else {QL4("No sections"); return}
        guard let notificationToken = notificationToken else {QL4("No notificationToken"); return}
        guard let listItemsNotificationToken = listItemsNotificationToken else {QL4("No list items notificationToken"); return}
        
        if editingStyle == .delete {
            
            let section = sections[indexPath.row]
            
//            delegate?.canRemoveSection(section) {can in
//                if can {
                    tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        Prov.sectionProvider.remove(section, notificationTokens: [notificationToken, listItemsNotificationToken], weakSelf.successHandler {[weak self] in
                            self?.tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .bottom)
                            self?.delegate?.onSectionRemoved(section)
                        })
                    }
//                }
//            }
        }
    }
    
    // Note: status of itels in this list assumed to be .Todo! It's not possible to reorder sections in the other status
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let sections = sections else {QL4("No sections"); return}
        
        Prov.sectionProvider.move(from: fromIndexPath.row, to: toIndexPath.row, sections: sections, notificationToken: notificationToken, successHandler {
        })
        
//            sections.remove(at: (fromIndexPath as NSIndexPath).row)
//            
//            sections.insert(section, at: (toIndexPath as NSIndexPath).row)
//            
//            sections = sections.enumerated().map{index, section in
//                section.updateOrder(ListItemStatusOrder(status: status, order: index))
//            }
//            
//            Prov.sectionProvider.update(sections, remote: true, successHandler{[weak self] in
//                self?.delegate?.onSectionsUpdated()
//            })
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sections = sections else {QL4("No sections"); return}

        let section = sections[indexPath.row]
        delegate?.onSectionSelected(section)
    }
    
    // Updates a section based on identity (uuid). Note that this isn't usable for order update, as updating order requires to update the order field of sections below
    func updateSection(_ section: Section) {
        // realm updates section automatically now, besides this causes also an exception because we can't edit sections outside of transaction
//        for i in 0..<sections.count {
//            if sections[i].same(section) {
//                sections[i] = section
//            }
//        }
        tableView.reloadData()
    }
}

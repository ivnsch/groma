//
//  ExpandableItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

class ExpandableTableViewModel: NSObject, Identifiable {

    var name: String {
        fatalError("override")
    }
    var subtitle: String? {
        return nil
    }
    var bgColor: UIColor {
        fatalError("override")
    }
    var users: [DBSharedUser] {
        fatalError("override")
    }
    
    func same(_ rhs: ExpandableTableViewModel) -> Bool {
        fatalError("override")
    }
    
    override var debugDescription: String {
        return ""
    }
}

protocol Foo: class { // TODO rename, put in other file
    func setExpanded(_ expanded: Bool)
}

enum TopBarState {
    case normal, normalFromExpanded, editTable, editItem, add, addNoAnim
}


class ExpandableItemsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ExpandCellAnimatorDelegate, Foo, ListTopBarViewDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!
//    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emptyViewControllerContainer: UIView!
    
    fileprivate var emptyViewController: EmptyViewController!
    fileprivate let listItemsProvider = ProviderFactory().listItemProvider
    
//    var models: [ExpandableTableViewModel] = [] {
//        didSet {
//            emptyView.isHidden = !models.isEmpty
//            tableView.isHidden = !emptyView.isHidden
//            if models != oldValue {
////                tableView.reloadData()
//            }
////            printDebugModels()
//        }
//    }
    
    
    fileprivate var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destination as! UITableViewController
            tableViewController.tableView.dataSource = self
            tableViewController.tableView.delegate = self
        }
    }
    
    
    fileprivate let expandCellAnimator = ExpandCellAnimator()
    
    fileprivate var originalNavBarFrame: CGRect = CGRect.zero
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
    fileprivate var pullToAddView: MyRefreshControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        setEmptyUI(false, animated: false) // start with hidden empty view, this way there's no "fade in" animation when starting (non empty) screens the first time
        
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ExpandableItemsTableViewController.onPullRefresh(_:)), for: .valueChanged)
        self.pullToAddView = refreshControl

        
        originalNavBarFrame = topBar.frame
        
        topBar.delegate = self
        
        initTopBar()
        
        initEmptyView()
    }
    
    fileprivate func initEmptyView() {
        let emptyViewController = UIStoryboard.emptyViewStoryboard()
        emptyViewController.addTo(container: emptyViewControllerContainer)
        emptyViewController.labels = emptyViewLabels
        emptyViewController.onTapOrPull = {[weak self] in
            _ = self?.onAddTap()
        }
        self.emptyViewController = emptyViewController
    }
    
    var emptyViewLabels: (label1: String, label2: String) {
        fatalError("Override")
    }
    
    func updateEmptyUI() {
        setEmptyUI(itemsCount.map{$0 == 0} ?? true, animated: true)
    }
    
    func setEmptyUI(_ empty: Bool, animated: Bool) {
        emptyViewControllerContainer.setHiddenAnimated(!empty)
    }
    
    // MARK: -
    
    func onExpandableClose() {
    }
    
    // MARK: - Pull to add
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        onPullToAdd()
    }

    func onPullToAdd() {
        // override
    }
    
    fileprivate func initTopBar() {
        topBar.delegate = self
        setTopBarState(.normalFromExpanded)
    }
    
    fileprivate func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.white
        topBar.addSubview(label)
    }
    
    
    func setNavTitle(_ title: String) {
        topBar.title = title
        topBar.positionTitleLabelLeft(true, animated: false, withDot: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initModels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toggleButtonRotator.reset(tableView, topBar: topBar)
    }
    
    func initModels() {
        fatalError("override")
    }

    func setTopBarStateForAddTap(_ expand: Bool, rotateTopBarButtonOnExpand: Bool = true) {
        if expand {
            setTopBarState(rotateTopBarButtonOnExpand ? .add : .addNoAnim)
        } else {
            setTopBarState(.normalFromExpanded)
        }
    }
    
    func setTopBarState(_ topBarState: TopBarState) {
        
        func leftEdit() {
            topBar.setLeftButtonIds([.edit])
        }
        
        func rightSubmitAndClose() { // v x
            topBar.setRightButtonModels([
//                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
            ])
        }
        
        func rightClose() { // x
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
            ])
        }

        func rightOpen() { // +
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform.identity)
            ])
        }
        
        // animated
        func rightOpenFromClosed() { // x -> +
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)
            ])
        }
        
        // animated
        func rightSubmitAndCloseFromOpen(_ animateToggle: Bool) { // + -> v x
            var models: [TopBarButtonModel] = [
//                TopBarButtonModel(buttonId: .Submit)
            ]
            if animateToggle {
                models.append(TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform.identity, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4))))
            } else {
//                models.append(TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4))))
            }
            
            topBar.setRightButtonModels(models)
//            
//            topBar.setRightButtonModels([
//                TopBarButtonModel(buttonId: .Submit),
//                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformIdentity, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//            ])
        }

        switch topBarState {
        case .normal:
            leftEdit()
            rightOpen()
            
        case .normalFromExpanded:
            leftEdit()
            rightOpenFromClosed()
            
        case .editTable:
            leftEdit()
            rightOpen()
            
        case .editItem:
            leftEdit()
            rightSubmitAndCloseFromOpen(true)

        case .add:
            leftEdit()
            rightSubmitAndCloseFromOpen(true)
            
        case .addNoAnim:
            leftEdit()
            rightSubmitAndCloseFromOpen(false)
        }
    }
    
    func onSubmitTap() {
        fatalError("override")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ExpandableItemsTableViewCell
        
        if let model = itemForRow(row: indexPath.row) {
            cell.model = model
        } else {
            QL4("Illegal state: no model for row: \(indexPath.row)")
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let model = itemForRow(row: indexPath.row) else{QL4("Illegal state: no model for index path: \(indexPath)"); return}
            
            canRemoveModel(model) {[weak self] can in
                if can {
                    self?.deleteItem(index: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .top)
                }
            }
        }
    }
    
    func canRemoveModel(_ model: ExpandableTableViewModel, can: @escaping (Bool) -> Void) {
        can(true)
    }
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        moveItem(from: fromIndexPath.row, to: toIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        fatalError("override")
    }
    
    func onSelectCellInEditMode(_ model: ExpandableTableViewModel, index: Int) {
        setTopBarState(.editItem)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let model = itemForRow(row: indexPath.row) else {QL4("Illegal state: No item for index path: \(indexPath)"); return}
        
        if self.isEditing {
            onSelectCellInEditMode(model, index: indexPath.row)
            
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                
                let detailController = initDetailController(cell, model: model)
                
                let f = CGRect(x: cell.frame.origin.x, y: cell.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
                
                expandCellAnimator.reset()
                expandCellAnimator.collapsedFrame = f
                expandCellAnimator.delegate = self
                expandCellAnimator.fromView = tableView
                expandCellAnimator.toView = detailController.view
                expandCellAnimator.inView = view
                
                expandCellAnimator.animateTransition(true, topOffsetY: 64)
                
            } else {
                print("Warn: no cell for indexPath: \(indexPath)")
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y, startOffset: -60)
    }
    
    func onAddTap(_ rotateTopBarButton: Bool = true) {
    }
    
    @IBAction func onEditTap(_ sender: UIBarButtonItem) {
        self.setEditing(!self.isEditing, animated: true, tryCloseTopViewController: true)
    }
    
    func topControllerIsExpanded() -> Bool {
        fatalError("Override")
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if !editing {
            view.endEditing(true)
        }
        
//        if tryCloseTopViewController {
//            if !editing && topControllerIsExpanded() {
////                setTopBarState(.NormalFromExpanded)
////                closeTopViewController()
//            }
//        }
        
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - ExpandCellAnimatorDelegate
    
    func animationsForCellAnimator(_ isExpanding: Bool, frontView: UIView) {
        let navBarFrame = topBar.frame
        if isExpanding {
            topBar.transform = CGAffineTransform(translationX: 0, y: -navBarFrame.height)
        } else {
            topBar.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    func setExpanded(_ expanded: Bool) {
        expandCellAnimator.animateTransition(false, topOffsetY: 64)
    }
    
    func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
    }
    
    func prepareAnimations(_ willExpand: Bool, frontView: UIView) {
    }
    
//    func removeModel(_ model: ExpandableTableViewModel) {
//        
//        func remove() {
//            if let index = models.remove(model) {
//                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .top)
//            } else {
//                print("Warn: ViewController.onWebsocketList: Removed list item was not found in tableView")
//            }
//        }
//        
//        tableView.wrapUpdates {
//            remove()
//        }
//    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
    }
    
    func onTopBarTitleTap() {
    }
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .submit:
            onSubmitTap()
        case .toggleOpen:
            onAddTap()
        case .edit:
            let editing = !self.tableView.isEditing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        default:
            print("Warn: ExpandableItemsTableViewController.onTopBarButtonTap: Not handled buttonId: \(buttonId)")
            break;
        }
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
        if center {
            setTopBarState(.normal)
        }
    }
    
    func onExpand(_ expanding: Bool) {
    }
    
    
    
    // New
    
    
    func loadModels(onSuccess: @escaping () -> Void) {
        fatalError("Override")
    }
    
    func itemForRow(row: Int) -> ExpandableTableViewModel? {
        fatalError("Override")
    }
    
    var itemsCount: Int? {
        fatalError("Override")
    }
    
    func deleteItem(index: Int) {
        fatalError("Override")
    }
    
    func moveItem(from: Int, to: Int) {
        fatalError("Override")
    }
}

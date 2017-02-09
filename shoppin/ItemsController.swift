//
//  ItemsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 02/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers
import RealmSwift

class ItemsController: UIViewController, QuickAddDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewLabel1: UILabel!
    @IBOutlet weak var emptyViewLabel2: UILabel!

    weak var expandDelegate: Foo?

    // TODO rename these blocks, which are meant to be executed only once after loading accordingly e.g. onViewWillAppearOnce
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    var isPullToAddEnabled: Bool {
        return true
    }
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()
    
    var tableView: UITableView {
        fatalError("override")
    }
    
    var isEmpty: Bool {
        fatalError("override")
    }
    
    /// Get list if we are in subclass that uses List. This is a bit messy, we should not have anything specific of the controllers which extend this controller here. Only used to pass it to the quick-add.
    var list: Providers.List? {
        return nil
    }
    
    
    var quickAddItemType: QuickAddItemType {
        return .productForList
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initProgrammaticViews()
        
        initTitleLabel()
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()
        
        topBar.delegate = self
    }
    
    func initProgrammaticViews() {
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    deinit {
        QL1("Deinit list items controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, openInset: top, closeInset: top, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            if let weakSelf = self {
                controller.itemType = weakSelf.quickAddItemType
            }
            controller.list = self?.list
            return controller
        }
        manager.delegate = self
        return manager
    }

    fileprivate func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.white
        topBar.addSubview(label)
    }
    
    func initEmptyView(line1: String, line2: String) {
        emptyViewLabel1.text = line1
        emptyViewLabel2.text = line2
    }
    
    func onExpand(_ expanding: Bool) {
        if !expanding {
            clearPossibleNotePopup()
            topQuickAddControllerManager?.controller?.removeFromParentViewControllerWithView()
            setEmptyUI(false, animated: false)
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels(rightButtonsClosing())
            // Clear list item memory cache when we leave controller. This is not really necessary but just "in case". The list item memory cache is there to smooth things *inside* a list, that is transitions between todo/done/stash, and adding/incrementing items. Causing a db-reload when we load the controller is totally ok.
            Prov.listItemsProvider.invalidateMemCache()
        }
        
        topBar.positionTitleLabelLeft(expanding, animated: true, withDot: true, heightConstraint: topBarHeightConstraint)
    }
    
    func setThemeColor(_ color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.white
    }
    
    func setEmptyUI(_ empty: Bool, animated: Bool) {
        setDefaultLeftButtons()
        
        let hidden = !empty
        if animated {
            emptyView.setHiddenAnimated(hidden)
        } else {
            emptyView.isHidden = hidden
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // TODO! is this still necessary?
//        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        onViewWillAppear?()
        onViewWillAppear = nil
        
        //        updatePrices(.First)
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onEmptyViewTap(_:)))
        emptyView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        toggleButtonRotator.reset(tableView, topBar: topBar)
        
        onViewDidAppear?()
        onViewDidAppear = nil
    }
    
    func onEmptyViewTap(_ sender: UITapGestureRecognizer) {
        _ = toggleTopAddController() // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }

    func setDefaultLeftButtons() {
        if isEmpty || isAnyTopControllerExpanded {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    func clearPossibleNotePopup() {
        if let popup = view.viewWithTag(ViewTags.NotePopup) {
            popup.removeFromSuperview()
        }
    }
    
    var isAnyTopControllerExpanded: Bool {
        return topQuickAddControllerManager?.expanded ?? false
    }
    
    func closeTopControllers(rotateTopBarButton: Bool = true) {
        topQuickAddControllerManager?.expand(false)
        onCloseTopControllers(rotateTopBarButton: rotateTopBarButton)
    }
    
    /// Private to avoid incorrect flow when overriding both closeTopControllers and onCloseTopControllers (and calling super)
    fileprivate func onCloseTopControllers(rotateTopBarButton: Bool = true) {
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        
        if rotateTopBarButton {
            topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
        }
        
        // we don't use default left buttons method here as the top controller isn't expanded yet (TODO improve)
        if isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    /// itemToEdit != nil -> Edit mode
    func openQuickAdd(rotateTopBarButton: Bool = true, itemToEdit: AddEditItem? = nil) {
        topQuickAddControllerManager?.expand(true)
        toggleButtonRotator.enabled = false
        topQuickAddControllerManager?.controller?.initContent()
        
        topBar.setLeftButtonIds([])
        
        if rotateTopBarButton {
            topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
        }
        
        if let itemToEdit = itemToEdit {
            topQuickAddControllerManager?.controller?.initContent(itemToEdit)
        }
    }
    
    // MARK:
    
    // returns: is now open?
    func toggleTopAddController(_ rotateTopBarButton: Bool = true) -> Bool {
        
        clearPossibleUndo()
        
        clearPossibleNotePopup()
        
        // if any top controller is open, close it
        if isAnyTopControllerExpanded {
            closeTopControllers(rotateTopBarButton: rotateTopBarButton)
            return false
            
        } else { // if there's no top controller open, open the quick add controller
            openQuickAdd(rotateTopBarButton: rotateTopBarButton)
            return true
        }
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        clearPossibleNotePopup()
        
        if editing == false {
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            closeTopControllers()
        }
        
        if !editing {
            setDefaultLeftButtons()
            topBar.setRightButtonModels(rightButtonsDefault())
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        clearPossibleUndo()
    }
    
    func clearPossibleUndo() {
        // TODO remove?
        //        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    // MARK: - ListItemsTableViewDelegate
    
    func onTableViewScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(-64, topBar: topBar, scrollView: scrollView)
    }
    
    func onPullToAdd() {
        _ = toggleTopAddController(false) // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }
    
    func updateEmptyUI() {
        setEmptyUI(isEmpty, animated: true)
    }
    
    fileprivate func getTableViewInset() -> CGFloat {
        return topBar.frame.height
    }
        
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        closeTopControllers(rotateTopBarButton: true)
    }
    
    func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        fatalError("Override")
    }
    
    func onAddItem(_ item: Item) {
        fatalError("Override")
    }
    
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
       fatalError("Override")
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        fatalError("Override")
    }
    
    
    func onAddProduct(_ product: QuantifiableProduct, quantity: Int) {
        fatalError("Override")
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        fatalError("Override")
    }
    
    func onQuickListOpen() {
    }
    
    func onAddProductOpen() {
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        fatalError("Override")
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
        fatalError("Override")
    }
    
    func onRemovedBrand(_ name: String) {
        fatalError("Override")
    }
    
    fileprivate func sendActionToTopController(_ action: FLoatingButtonAction) {
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        if controller is QuickAddViewController || controller is AddEditListItemViewController {
            view.frame.origin.y = topBar.frame.height
        }
    }
    
    func onExpandableClose() {
        onCloseTopControllers(rotateTopBarButton: true)
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.back)
    }
    
    func onTopBarTitleTap() {
        // override
    }
    
    func back() {
        onExpand(false)
        topQuickAddControllerManager?.controller?.onClose()
        expandDelegate?.setExpanded(false)
    }
    
    fileprivate func topBarOnCloseExpandable() {
        setDefaultLeftButtons()
        topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
    }
    
    func closeTopController() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        topBarOnCloseExpandable()
    }
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .add:
            //            SizeLimitChecker.checkListItemsSizeLimit(listItemsTableViewController.items.count, controller: self) {[weak self] in
            //                if let weakSelf = self {
            sendActionToTopController(.add)
            //                }
        //            }
        case .toggleOpen:
            if !(topQuickAddControllerManager?.controller?.onTapNavBarCloseTap() ?? false) { // if the event is not consumed by quick add
                _ = toggleTopAddController()
            }
        case .edit:
            clearPossibleUndo()
            let editing = !isEditing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        default: QL4("Not handled: \(buttonId)")
        }
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
        if center {
            setDefaultLeftButtons()
            topBar.setRightButtonModels(rightButtonsDefault())
        }
    }
    
    // MARK: - Right buttons
    
    func rightButtonsDefault() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen)]
    }
    
    func rightButtonsOpeningQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))]
    }
    
    func rightButtonsClosingQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)]
    }
    
    func rightButtonsClosing() -> [TopBarButtonModel] {
        return []
    }
    
    // MARK: - Popup
    
    func showPopup(text: String, cell: UITableViewCell, button: UIView) {
        let topOffset: CGFloat = 64
        let frame = view.bounds.copy(y: topOffset, height: view.bounds.height)
        
        let noteButtonPointParentController = view.convert(CGPoint(x: button.center.x, y: button.center.y), from: cell)
        // adjust the anchor point also for topOffset
        let buttonPointWithOffset = noteButtonPointParentController.copy(y: noteButtonPointParentController.y - topOffset)
        
        AlertPopup.showCustom(message: text, controller: self, frame: frame, rootControllerStartPoint: buttonPointWithOffset)
    }
}

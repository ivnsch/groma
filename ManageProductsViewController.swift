//
//  ManageProductsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BottonPanelViewDelegate, AddEditProductControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var floatingViews: FloatingViews!
    private var editButton: UIBarButtonItem!
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var products: [Product] = [] {
        didSet {
            filteredProducts = products
        }
    }

    private var filteredProducts: [Product] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private lazy var addEditProductController: AddEditProductController = {
        let controller = UIStoryboard.addEditProductController()
        controller.delegate = self
        let height: CGFloat = 140
        self.initTopController(controller, height: height)
        return controller
    }()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        products = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initNavBar()
        
        tableView.allowsSelectionDuringEditing = true
        
        Providers.productProvider.products(successHandler {[weak self] products in
            self?.products = products
        })
    }

    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar() {
//        navigationController?.title = "Manage products"
        navigationItem.title = "Manage products"
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditTap:")
        self.editButton = editButton
        navigationItem.setRightBarButtonItem(editButton, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        initFloatingViews()
    }
    
    private func initFloatingViews() {
        floatingViews.setActions([toggleButtonInactiveAction])
        floatingViews.delegate = self
    }

    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("productCell", forIndexPath: indexPath) as! ManageProductsCell

        let product = filteredProducts[indexPath.row]

        cell.product = product
        return cell
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let product = filteredProducts[indexPath.row]
            Providers.productProvider.delete(product, successHandler{[weak self] in
                self?.tableView.wrapUpdates {
                    self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                    self?.products.remove(product)
                    self?.filteredProducts.remove(product)
                }
            })
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }

    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredProducts = products
        } else {
            Providers.productProvider.productsContainingText(searchText, successHandler{[weak self] products in
                self?.filteredProducts = products
            })
        }
    }
    
    private func onUpdatedProducts() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        addEditProductController.editingData = AddEditProductControllerEditingData(product: filteredProducts[indexPath.row], indexPath: indexPath)
        setAddEditProductControllerOpen(true)
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            if !editing {
                if addEditProductController.open {
                    setAddEditProductControllerOpen(false)
                }
            }
        }
        
        floatingViews.setActions([editing ? toggleButtonAvailableAction : toggleButtonInactiveAction]) // remove possible top controller specific action buttons (e.g. on list item update we have a submit button), and set appropiate alpha
        
        tableView.setEditing(editing, animated: animated)

        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    
    func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredProducts = products
    }
    
    // MARK - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        switch action {
        case .Toggle:
            if addEditProductController.open {
                setAddEditProductControllerOpen(false)
                floatingViews.setActions([toggleButtonInactiveAction])
                
            } else {
                clearSearch() // clear filter to avoid confusion, if we add an item it may be not in current filter and user will not see it appearing.
                setAddEditProductControllerOpen(true)
                floatingViews.setActions([toggleButtonActiveAction, FLoatingButtonAttributedAction(action: .Submit)])
            }
            
            
        case .Submit:
            addEditProductController.submit()
            
        case .Add, .Back: break
        }
    }
    
    // MARK: - AddEditProductControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
         presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onSubmit(name: String, category: String, price: Float, editingData: AddEditProductControllerEditingData?) {
        if let editingData = editingData {
            updateProduct(editingData, name: name, category: category, price: price)
        } else {
            addProduct(name, category: category, price: price)
        }
    }
    
    func onCancelTap() {
        setAddEditProductControllerOpen(false)
        addEditProductController.clear()
    }

    private func updateProduct(editingData: AddEditProductControllerEditingData, name: String, category: String, price: Float) {
        let updatedProduct = editingData.product.copy(name: name, price: price, category: category)
        Providers.productProvider.update(updatedProduct, successHandler{[weak self] in
            if let weakSelf = self {
                weakSelf.products.update(updatedProduct)
                weakSelf.onUpdatedProducts()
                
                weakSelf.tableView.scrollToRowAtIndexPath(editingData.indexPath, atScrollPosition: .Middle, animated: true)
                weakSelf.setAddEditProductControllerOpen(false)
                weakSelf.addEditProductController.clear()
            }
        })
    }
    
    private func addProduct(name: String, category: String, price: Float) {
        let product = ProductInput(name: name, price: price, category: category)
        Providers.productProvider.add(product, successHandler {[weak self] product in
            if let weakSelf = self {
                weakSelf.products.append(product)
                weakSelf.onUpdatedProducts()
                
                weakSelf.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: weakSelf.filteredProducts.count - 1, inSection: 0), atScrollPosition: .Middle, animated: true)
                weakSelf.setAddEditProductControllerOpen(false)
                weakSelf.addEditProductController.clear()
            }
        })
    }
    
    // MARK: - Top view
    
    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view
        self.view.addSubview(view)
        let navbarHeight = navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        view.frame = CGRectMake(0, navbarHeight + statusBarHeight, self.view.frame.width, height)
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    
    private func animateTopView(view: UIView, open: Bool) {
        if open {
            tableViewOverlay.frame = self.view.frame
            self.view.insertSubview(tableViewOverlay, aboveSubview: tableView)
        } else {
            tableViewOverlay.removeFromSuperview()
        }
        
        UIView.animateWithDuration(0.3) {
            if open {
                self.tableViewOverlay.alpha = 0.2
            } else {
                self.tableViewOverlay.alpha = 0
            }
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, open ? 1 : 0.001)

            self.searchBar.hidden = open

            let topInset = open ? (CGRectGetHeight(view.frame) - CGRectGetHeight(self.searchBar.frame)) : CGRectGetHeight(view.frame)
            let bottomInset = self.navigationController?.tabBarController?.tabBar.frame.height
            self.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
            self.tableView.topOffset = -self.tableView.inset.top
        }
    }
    
    private lazy var tableViewOverlay: UIView = {
        let view = UIButton()
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0
        return view
    }()
    
    
    private func setAddEditProductControllerOpen(open: Bool) {
        addEditProductController.open = open
        animateTopView(addEditProductController.view, open: open)
        
        if open {
            floatingViews.setActions([toggleButtonActiveAction, FLoatingButtonAttributedAction(action: .Submit)])
            
        } else {
            floatingViews.setActions([toggleButtonInactiveAction]) // this is done with setEditing false
        }
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    Providers.productProvider.products(weakSelf.paginator.currentPage, weakSelf.successHandler{products in
                        weakSelf.products.appendAll(products)
                        
                        weakSelf.paginator.update(products.count)
                        
                        weakSelf.tableView.reloadData()
                        setLoading(false)
                    })
                }
            }
        }
    }

}

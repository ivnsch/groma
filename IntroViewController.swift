//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit
import SwipeView
import QorumLogs
import Providers

enum IntroMode {
    case launch, more
}

class IntroViewController: UIViewController, RegisterDelegate, LoginDelegate, SwipeViewDataSource, SwipeViewDelegate {

    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var skipButton: UIButton!
    // This works but for now disabled, no signup in intro
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var verticalCenterSlideConstraint: NSLayoutConstraint!
    
    var mode: IntroMode = .launch
    
    fileprivate var pageModels: [(key: String, imageName: String)] = []
    
    var onCreateExampleList: VoidFunction?
    
    fileprivate let suggestionsPrefiller = SuggestionsPrefiller()
    
    fileprivate var finishedSlider = false {
        didSet {
            if mode == .launch {
                skipButton.setTitle(trans("intro_button_start"), for: UIControlState())
                skipButton.setTitleColor(Theme.black, for: UIControlState())
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        
        pageModels = [(trans("intro_slide_lists"), "intro_lists"),
                      (trans("intro_slide_inventories"), "intro_inventory"),
                      (trans("intro_slide_stats"), "intro_stats")]
        if CountryHelper.isInServerSupportedCountry() {
            pageModels.append((trans("intro_slide_real_time"), "intro_sharing"))
        }
        
        
        pageControl.numberOfPages = pageModels.count
        
        if mode == .launch {
            
            let initActions =  PreferencesManager.loadPreference(PreferencesManagerKey.isFirstLaunch) ?? false
            
            QL1("Will init database: \(initActions)")

            func toggleButtons(_ canSkip: Bool) {
                progressIndicator.isHidden = canSkip
                skipButton.isHidden = !canSkip
                if !progressIndicator.isHidden {
                    progressIndicator.startAnimating()
                }
            }
            
            if initActions {
                toggleButtons(false)
                
                initDatabase {
                    toggleButtons(true)
                }
            } else {
                toggleButtons(true)
            }
            
        } else {
            navigationItem.title = trans("title_intro")
            skipButton.isHidden = true
            progressIndicator.isHidden = true
        }
    }
    
    @IBAction func loginTapped(sender: UIButton) {
        startLogin(.normal)
    }
    
    fileprivate func startLogin(_ mode: LoginControllerMode) {
        let loginController = UIStoryboard.loginViewController()
        loginController.delegate = self
        loginController.onUIReady = {
            loginController.mode = mode
        }

        self.navigationController?.pushViewController(loginController, animated: true)
    }

    fileprivate func initDatabase(_ onComplete: @escaping VoidFunction) {

        func initRealmContainers(_ onFinish: @escaping (Bool) -> Void) {
            Prov.globalProvider.initContainers(handler: resultHandler(onSuccess: {
                onFinish(true)
            }, onErrorAdditional: {_ in
                onFinish(false)
            }))
        }
        
        func prefillDatabase(_ onFinish: @escaping (_ success: Bool, _ units: [Providers.Unit]) -> Void) {
            let lang = LangManager().appLang // note that the prefill items are left permanently in whatever lang the device was when the user installed the app
            
            suggestionsPrefiller.prefill(lang) {(success: Bool, defaultUnits: [Providers.Unit]) in
                QL1("Finish initialising database for lang: \(lang), success: \(success). Default units count: \(defaultUnits.count)")
                onFinish((success, defaultUnits))
            }
        }
        
        func initDefaultInventory(_ onFinish: ((DBInventory?) -> Void)? = nil) {
            Prov.inventoryProvider.inventories(false, resultHandler(onSuccess: {[weak self] inventories in
                
                if let weakSelf = self {
                    if inventories.isEmpty {
                        let inventory = DBInventory(uuid: UUID().uuidString, name: trans("first_inventory_name"), bgColor: UIColor.flatBlue, order: 0)
                        
                        Prov.inventoryProvider.addInventory(inventory, remote: true, weakSelf.resultHandler(onSuccess: {
                            onFinish?(inventory)
                            }, onError: {result in
                                // let the user start if there's an error (we don't expect any, but just in case!)
                                // it would be very bad if user can't get past intro for whatever reason. Both adding default inventory and default products (TODO) are not critical for the app to be usable.
                                QL4("Error adding inventory, result: \(result)")
                                onFinish?(nil)
                        }))
                    } else {
                        QL2("User already has inventories, skipping")
                        onFinish?(nil)
                    }
                }
                
                }, onError: {result in
                    QL4("Error fetching inventories, result: \(result)")
                    onFinish?(nil)
            }))
        }
        
        func initExampleGroup(unitDict: [UnitId: Providers.Unit], _ onFinish: VoidFunction? = nil) {
            Prov.listItemGroupsProvider.groups(sortBy: .order, resultHandler(onSuccess: {[weak self] groups in guard let weakSelf = self else {onFinish?(); return}
                
                if groups.isEmpty {
                    
                    let exampleGroup = ProductGroup(uuid: UUID().uuidString, name: trans("example_group_fruits_salad"), color: UIColor.flatYellow, order: 0)
                    
                    let ingredients: [(name: String, quantity: Float)] = [
                        (trans("pr_pineapple"), 1),
                        (trans("pr_plums"), 3),
                        (trans("pr_bananas"), 2),
                        (trans("pr_strawberries"), 1),
                        (trans("pr_water_1"), 3)
                    ]
                    
                    let ingredientsNameBrands: [(name: String, brand: String)] = ingredients.map{(name: $0.name, brand: "")}
                    
                    Prov.productProvider.products(ingredientsNameBrands, weakSelf.resultHandler(onSuccess: {products in
                        
                        if products.count != ingredientsNameBrands.count {
                            QL4("Unexpected: Some of the products of the example group are not in the database. Found products(\(products.count)): \(products)")
                            onFinish?()
                            
                        } else {
                            Prov.listItemGroupsProvider.add(exampleGroup, remote: true, weakSelf.resultHandler(onSuccess: {_ in
                                
                                guard let noneUnit = unitDict[.none] else {QL4("No none unit! can't add group items."); onFinish?(); return}
                                
                                let productsIngredients: [(product: QuantifiableProduct, quantity: Float)] = ingredients.flatMap {ingredient in
                                    if let product = products.findFirst({$0.item.name == ingredient.name}) {
                                        // for now use products without unit to prefill group
                                        let quanatifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantityFloat: 1, unit: noneUnit, product: product)
                                        return (quanatifiableProduct, ingredient.quantity)
                                    } else {
                                        return nil
                                    }
                                }
                                
                                let groupItems = productsIngredients.map {productIngredient in
                                    GroupItem(uuid: NSUUID().uuidString, quantity: productIngredient.quantity, product: productIngredient.product, group: exampleGroup)
                                }
                                
                                Prov.listItemGroupsProvider.add(groupItems, group: exampleGroup, remote: true, weakSelf.resultHandler(onSuccess: {_ in 
                                    QL2("Finish adding example group")
                                    onFinish?()
                                    
                                    }, onError: {result in
                                        QL4("Error adding example group items, result: \(result), items: \(groupItems)")
                                        onFinish?()
                                }))
                                
                                }, onError: {result in
                                    QL4("Error adding example group, result: \(result), group: \(exampleGroup)")
                                    onFinish?()
                            }))
                        }
                        }, onError: {result in
                            QL4("Error querying products, result: \(result)")
                            onFinish?()
                    }))
                } else {
                    QL2("User already has groups, skipping")
                    onFinish?()
                }
                }, onError: {result in
                    QL4("Error fetching groups, result: \(result)")
                    onFinish?()
            }))
        }

        func initExampleList(_ inventory: DBInventory, unitDict: [UnitId: Providers.Unit], onFinish: VoidFunction? = nil) {
            Prov.listProvider.lists(false, resultHandler(onSuccess: {[weak self] lists in guard let weakSelf = self else {onFinish?(); return}
                
                if lists.isEmpty {
                    
                    let exampleList = List(uuid: UUID().uuidString, name: trans("example_list_first_list"), color: UIColor.flatOrange, order: 0, inventory: inventory, store: nil)
                    
                    let productsWithQuantity: [(name: String, quantity: Float)] = [
                        (trans("pr_peaches"), 6),
                        (trans("pr_oranges"), 12),
                        (trans("pr_kiwis"), 4),
                        (trans("pr_water_1"), 3)
                    ]
                    
                    let productsWithBrands: [(name: String, brand: String)] = productsWithQuantity.map{(name: $0.name, brand: "")}
                    
                    Prov.productProvider.products(productsWithBrands, weakSelf.resultHandler(onSuccess: {products in
                        
                        if products.count != productsWithBrands.count {
                            QL4("Unexpected: Some of the products of the example group are not in the database. Found products(\(products.count)): \(products)")
                            onFinish?()
                            
                        } else {
                            Prov.listProvider.add(exampleList, remote: true, weakSelf.resultHandler(onSuccess: {addedList in
                        
                                guard let noneUnit = unitDict[.none] else {QL4("No none unit! can't add list items."); onFinish?(); return}

                                let productsIngredients: [(product: QuantifiableProduct, quantity: Float)] = productsWithQuantity.flatMap {ingredient in
                                    if let product = products.findFirst({$0.item.name == ingredient.name}) {
                                        // for now use products without unit to prefill list
                                        let quanatifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantityFloat: 1, unit: noneUnit, product: product)
                                        return (quanatifiableProduct, ingredient.quantity)
                                    } else {
                                        return nil
                                    }
                                }
                                
                                let storeProductInput = StoreProductInput(price: 1, baseQuantity: 1, unit: "") // TODO!!!!!!!!!!!!!!!!! empty string unit is converted to "none" when saving TODO more reliable way to implement this
                                let prototypes = productsIngredients.map {
                                    ListItemPrototype(product: $0.product, quantity: $0.quantity, targetSectionName: $0.product.product.item.category.name, targetSectionColor: $0.product.product.item.category.color, storeProductInput: storeProductInput)
                                }

                                
                                
                                // TODO add list items correctly (ues correct provider method - appending to list's sections)
                                onFinish?()
//                                Prov.listItemsProvider.add(prototypes, status: .todo, list: exampleList, note: nil, order: nil, token: nil, weakSelf.resultHandler(onSuccess: {[weak self] foo in
//                                    QL2("Finish adding example list")
//                                    
//                                    self?.onCreateExampleList?()
//                                    
//                                    onFinish?()
//                                    
//                                    }, onError: {result in
//                                        QL4("Error adding example list items, result: \(result), items: \(prototypes)")
//                                        onFinish?()
//                                }))
                                
                                
                                
                                
                                
                                }, onError: {result in
                                    QL4("Error adding example list, result: \(result), group: \(exampleList)")
                                    onFinish?()
                            }))
                        }
                        }, onError: {result in
                            QL4("Error querying products, result: \(result)")
                            onFinish?()
                    }))
                } else {
                    QL2("User already has lists, skipping")
                    onFinish?()
                }
                }, onError: {result in
                    QL4("Error fetching list, result: \(result)")
                    onFinish?()
            }))
        }

            
        // TODO!!!!!!!!!!!!!!!!!!!! move init containers to app delegate - since intro is shown on top of lists controller, the first time user loads the app will trigger error messages because lists (for controller behind) can't be loaded (since containers don't exist yet).
        initRealmContainers {success in
            guard success else {
                onComplete()
                return
            }
            
            QL2("Finished init realm containers")
            prefillDatabase {success, defaultUnits in
                
                let unitDict = defaultUnits.toDictionary {defaultUnit in
                    (defaultUnit.id, defaultUnit)
                }
                
                QL2("Finished copying prefill database")
                initDefaultInventory {inventoryMaybe in
                    QL2("Finished adding default inventory")
                    
//                    initExampleGroup(unitDict: unitDict) { // Disabled, getting exception "Can not add objects from a different Realm" after adding "Item" Realm object (no idea why). We don't use groups anymore anyway.
//                        QL2("Finished adding example group")
                        if let inventory = inventoryMaybe {
                            initExampleList(inventory, unitDict: unitDict) {
                                QL2("Finished adding example list")
                                onComplete()
                            }
                        } else {
                            QL2("Didn't add default inventory so can't add example list")
                            onComplete()
                        }
//                    }
                }
            }
        }
    }

    
    @IBAction func registerTapped(sender: UIButton) {
        let registerController = UIStoryboard.registerViewController()
        registerController.delegate = self
        _ = navigationController?.pushViewController(registerController, animated: true)
    }

    
    @IBAction func skipTapped(_ sender: UIButton) {
        if mode == .launch {
            PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
            exit()
        }
    }
    
    // MARK: - RegisterDelegate
    
    func onRegisterSuccess(_ email: String) {
        _ = navigationController?.popViewController(animated: true)
        startLogin(.afterRegister)
    }
    
    func onLoginFromRegisterSuccess() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onSocialSignupInRegisterScreenSuccess() {
        // TODO review this - not tested. For now no signup buttons in intro so we let it like this, maybe we want to reenable it later.
        _ = navigationController?.popViewController(animated: true)
        startLogin(.afterRegister)
    }
    
    // MARK: -
    
    fileprivate func exit() {
        self.modalTransitionStyle = .crossDissolve
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func onLoginSuccess() {
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        exit()
    }
    
    func onRegisterFromLoginSuccess() {
    }
    
    // MARK: - SwipeViewDataSource
    
    func numberOfItems(in swipeView: SwipeView!) -> Int {
        return pageModels.count
    }
    
    func swipeView(_ swipeView: SwipeView!, viewForItemAt index: Int, reusing view: UIView!) -> UIView! {
    
        let v = (view ?? Bundle.loadView("IntroPageView", owner: self)!) as! IntroPageView
        
        let pageModel = pageModels[index]
        
        let image = UIImage(named: pageModel.imageName)!
        v.imageView.image = image
        v.label.text = pageModel.key

        return v
    }

    // MARK: - SwipeViewDelegate
    
    func swipeViewCurrentItemIndexDidChange(_ swipeView: SwipeView!) {
        pageControl.currentPage = swipeView.currentItemIndex
        if swipeView.currentItemIndex == pageModels.count - 1 {
            if !finishedSlider {
                finishedSlider = true
            }
        }
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
    
    
    deinit {
        QL1("Deinit intro controller")
    }
}

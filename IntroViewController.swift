//
//  IntroViewController.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved/≥.
//

import UIKit
import SwipeView
import Lottie
import Providers

enum IntroMode {
    case launch, more
}

class IntroViewController: UIViewController, RegisterDelegate, LoginDelegate
, SwipeViewDataSource, SwipeViewDelegate
{
    @IBOutlet weak var swipeView: SwipeView!
    @IBOutlet weak var animationView: LOTAnimationView!
    @IBOutlet weak var pageControl: UIPageControl!

    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var skipButton: UIButton!
    // This works but for now disabled, no signup in intro
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var verticalCenterSlideConstraint: NSLayoutConstraint!
    
    var mode: IntroMode = .launch

    // TODO remove imageName - we don't use static images anymore
    fileprivate var pageModels: [(key: String, imageName: String)] = []

    fileprivate var databaseFinishedLoading = false

    var onCreateExampleList: VoidFunction?
    
    fileprivate let suggestionsPrefiller = SuggestionsPrefiller()
    
    fileprivate var finishedSlider = false {
        didSet {
            if mode == .launch {
                skipButton.setHiddenAnimated(false)
                if databaseFinishedLoading == false {
                    progressIndicator.isHidden = false
                    progressIndicator.startAnimating()
                }
                skipButton.setTitle(trans("intro_button_start"), for: UIControlState())
                skipButton.setTitleColor(Theme.black, for: UIControlState())
            }
        }
    }

    fileprivate var beforeFirstSliderDrag = true

    // (start, length) in percentage of total animaton duration
    // for example the first idle scene ("image" shown in the first page) starts say at 12.5% and has a length of 20% -> (12.5, 20)
    fileprivate var animationIntervals: [(Double, Double)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mode == .launch {
            navigationController?.isNavigationBarHidden = true
        }
        
        pageModels = [(trans("intro_slide_lists"), "intro_lists"),
                      (trans("intro_slide_recipes"), "intro_inventory"),
                      (trans("intro_slide_inventories"), "intro_inventory"),
                      (trans("intro_slide_stats"), "intro_stats")]
//        if CountryHelper.isInServerSupportedCountry() {
//            pageModels.append((trans("intro_slide_real_time"), "intro_sharing"))
//        }

        pageControl.numberOfPages = pageModels.count

        if mode == .launch {
            
            let initActions =  PreferencesManager.loadPreference(PreferencesManagerKey.isFirstLaunch) ?? false
            
            logger.v("Will init database: \(initActions)")

            skipButton.isHidden = true // for now always hidden - we force user to see all the intro
            progressIndicator.isHidden = true

            if initActions {
                initDatabase { [weak self] in
                    self?.databaseFinishedLoading = true
                    self?.progressIndicator.isHidden = true
                }
            } else {
                databaseFinishedLoading = true
            }
            
        } else {
            navigationItem.title = trans("title_intro")
            skipButton.isHidden = true
            progressIndicator.isHidden = true
        }

        initIntroAnimation()
    }

    fileprivate func initIntroAnimation() {
        initAnimationIntervals()
        animationView.setAnimation(named: "groma-intro-02")
        if let firstSceneStart = animationIntervals[safe: 1] {
            animationView.play(toProgress: CGFloat(firstSceneStart.0 / 100), withCompletion: nil)
        } else {
            logger.e("Start of first intro scene not found", .ui)
        }
    }

    fileprivate func initAnimationIntervals() {
        // progress percentage of idle scenes in animation (about in the middle of the respective idle interval)
        // got these numbers with trial and error - if the animation changes these numbers (most probably) have to be updated.
        let starts = [ 0, 12.5, 30, 55, 88 ]
        for i in 0..<starts.count {
            let current = starts[i]
            let next = starts[safe: i + 1] ?? 100
            animationIntervals.append((current, next - current))
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
                logger.v("Finish initialising database for lang: \(lang), success: \(success). Default units count: \(defaultUnits.count)")
                onFinish(success, defaultUnits)
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
                                logger.e("Error adding inventory, result: \(result)")
                                onFinish?(nil)
                        }))
                    } else {
                        logger.d("User already has inventories, skipping")
                        onFinish?(nil)
                    }
                }
                
                }, onError: {result in
                    logger.e("Error fetching inventories, result: \(result)")
                    onFinish?(nil)
            }))
        }
        
        func initExampleRecipe(unitDict: [UnitId: Providers.Unit], _ onFinish: VoidFunction? = nil) {
            Prov.recipeProvider.recipes(sortBy: .order, resultHandler(onSuccess: {[weak self] recipes in guard let weakSelf = self else {onFinish?(); return}
                
                guard recipes.isEmpty else {logger.d("User already has groups, skipping"); onFinish?(); return}
                
                let ingredientModels: [(name: String, quantity: Float, fraction: Fraction, unitId: UnitId)] = [
                    (trans("pr_tomatoes_peeled"), 1, Fraction.one, .can),
                    (trans("pr_oil_olives"), 1, Fraction.one, .spoon),
                    (trans("pr_onions"), 1, Fraction.one, .none),
                    (trans("pr_salt"), 0, Fraction.zero, .none),
                    (trans("pr_garlic"), 2, Fraction.one, .clove),
                    (trans("pr_pepper_red"), 1, Fraction.one, .pinch),
                    (trans("pr_chicken_broth"), 1, Fraction(numerator: 1, denominator: 2), .cup),
                    (trans("pr_cream"), 0, Fraction(numerator: 1, denominator: 3), .cup),
                    (trans("pr_pepper"), 0, Fraction.zero, .none)
                ]
                
                let spans: [TextSpan] = {
                    switch LangHelper.currentAppLang() {
                    default: return [
                        TextSpan(start: 0, length: 5, attribute: .bold),
                        TextSpan(start: 15, length: 7, attribute: .bold),
                        TextSpan(start: 26, length: 2, attribute: .bold),
                        TextSpan(start: 331, length: 2, attribute: .bold)
                        ]
                    }
                } ()

                let recipe = Recipe(uuid: UUID().uuidString, name: trans("tomato_soup"), color: UIColor.flatRed, text: trans("tomato_soup_text"), spans: spans)
                
                let itemNames = ingredientModels.map {$0.name}
                Prov.itemsProvider.items(names: itemNames, weakSelf.resultHandler(onSuccess: {[weak self] itemsResults in guard let weakSelf = self else {onFinish?(); return}
                    
                    let itemsDict = itemsResults.toDictionary {($0.name, $0)}

                    let ingredients: [Ingredient] = ingredientModels.compactMap {ingredientModel in
                        // It would be better to delete the recipe on failure instead of skip but this is quicker to implement
                        guard let unit = unitDict[ingredientModel.unitId] else {logger.e("Didn't find unit for id: \(ingredientModel.unitId). Can't add ingredient"); return nil}
                        guard let item = itemsDict[ingredientModel.name] else {logger.e("Didn't find item with name: \(ingredientModel.name). Can't add ingredient"); return nil}
                        return Ingredient(uuid: UUID().uuidString, quantity: ingredientModel.quantity, fraction: ingredientModel.fraction, unit: unit, item: item, recipe: recipe)
                    }
                    
                    Prov.recipeProvider.add(recipe, notificationToken: nil, weakSelf.resultHandler(onSuccess: {
                        Prov.ingredientProvider.add(ingredients, weakSelf.resultHandler(onSuccess: {
                            onFinish?()
                            
                        }, onError: {result in
                            logger.e("Error adding ingredients, result: \(result)")
                            onFinish?()
                        }))
                        
                    }, onError: {result in
                        logger.e("Error adding recipe, result: \(result), recipe: \(recipe)")
                        onFinish?()
                    }))
                    
                }, onError: {result in
                    logger.e("Error querying items, result: \(result)")
                    onFinish?()
                }))
            
            }, onError: {result in
                logger.e("Error querying recipes, result: \(result)")
                onFinish?()
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
                        (trans("pr_water"), 3)
                    ]

                    let ingredientsNameBrands: [(name: String, brand: String)] = ingredients.map{(name: $0.name, brand: "")}

                    Prov.productProvider.products(ingredientsNameBrands, weakSelf.resultHandler(onSuccess: {products in

                        if products.count != ingredientsNameBrands.count {
                            logger.e("Unexpected: Some of the products of the example group are not in the database. Found products(\(products.count)): (\(products.map{$0.item.name})), searched(\(ingredients.count)): \(ingredients.map{$0.name})")
                            onFinish?()

                        } else {
                            Prov.listItemGroupsProvider.add(exampleGroup, remote: true, weakSelf.resultHandler(onSuccess: {_ in

                                guard let noneUnit = unitDict[.none] else {logger.e("No none unit! can't add group items."); onFinish?(); return}

                                let productsIngredients: [(product: QuantifiableProduct, quantity: Float)] = ingredients.compactMap {ingredient in
                                    if let product = products.findFirst({$0.item.name == ingredient.name}) {
                                        // for now use products without unit to prefill group
                                        let quanatifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantity: 1, unit: noneUnit, product: product)
                                        return (quanatifiableProduct, ingredient.quantity)
                                    } else {
                                        return nil
                                    }
                                }

                                let groupItems = productsIngredients.map {productIngredient in
                                    GroupItem(uuid: NSUUID().uuidString, quantity: productIngredient.quantity, product: productIngredient.product, group: exampleGroup)
                                }

                                Prov.listItemGroupsProvider.add(groupItems, group: exampleGroup, remote: true, weakSelf.resultHandler(onSuccess: {_ in
                                    logger.d("Finish adding example group")
                                    onFinish?()

                                    }, onError: {result in
                                        logger.e("Error adding example group items, result: \(result), items: \(groupItems)")
                                        onFinish?()
                                }))

                                }, onError: {result in
                                    logger.e("Error adding example group, result: \(result), group: \(exampleGroup)")
                                    onFinish?()
                            }))
                        }
                        }, onError: {result in
                            logger.e("Error querying products, result: \(result)")
                            onFinish?()
                    }))
                } else {
                    logger.d("User already has groups, skipping")
                    onFinish?()
                }
                }, onError: {result in
                    logger.e("Error fetching groups, result: \(result)")
                    onFinish?()
            }))
        }

        func initExampleList(_ inventory: DBInventory, unitDict: [UnitId: Providers.Unit], onFinish: VoidFunction? = nil) {
            Prov.listProvider.lists(false, resultHandler(onSuccess: {[weak self] lists in guard let weakSelf = self else {onFinish?(); return}
                
                if lists.isEmpty {
                    
                    let exampleList = List(uuid: UUID().uuidString, name: trans("example_list_first_list"), color: UIColor.flatOrange, order: 0, inventory: inventory, store: nil)
                    
                    let productsWithQuantity: [(name: String, quantity: Float, base: Float, unit: UnitId)] = [
                        (trans("pr_peaches"), 6, 1, .none),
                        (trans("pr_oranges"), 12, 1, .none),
                        (trans("pr_kiwis"), 4, 1, .none),
                        (trans("pr_water"), 4, 1, .liter),
                        (trans("pr_rice"), 6, 500, .g),
                        (trans("pr_bread"), 12, 1, .none),
                        (trans("pr_grapes"), 4, 500, .g),
                        (trans("pr_mangos"), 3, 1, .none),
                        (trans("pr_garlic"), 6, 1, .none),
                        (trans("pr_drum_sticks"), 1, 500, .g),
                        (trans("pr_chicken_wings"), 1, 500, .g),
                        (trans("pr_pepper_red"), 3, 1, .none)
                    ]
                    
                    let productsWithBrands: [(name: String, brand: String)] = productsWithQuantity.map{(name: $0.name, brand: "")}
                    
                    Prov.productProvider.products(productsWithBrands, weakSelf.resultHandler(onSuccess: {products in
                        
                        if products.count != productsWithBrands.count {
                            logger.e("Unexpected: Some of the products of the example group are not in the database. Found products(\(products.count)): \(products.map{$0.item.name}), searched(\(productsWithBrands.count)): \(productsWithBrands.map{$0.name})")
                            onFinish?()
                            
                        } else {
                            Prov.listProvider.add(exampleList, remote: true, weakSelf.resultHandler(onSuccess: {addedList in
                        
                                guard let noneUnit = unitDict[.none] else {logger.e("No none unit! can't add list items."); onFinish?(); return}

                                let productsInputs: [(product: QuantifiableProduct, quantity: Float)] = productsWithQuantity.compactMap {ingredient in
                                    if let product = products.findFirst({$0.item.name == ingredient.name}) {
                                        // for now use products without unit to prefill list

                                        let unitId = ingredient.unit
                                        let unit = unitDict[unitId] ?? {
                                            logger.e("Invalid state: no unit found for id: \(unitId). Defaulting to none.")
                                            return noneUnit
                                        } ()
                                        let quanatifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantity: ingredient.base, unit: unit, product: product)
                                        return (quanatifiableProduct, ingredient.quantity)
                                    } else {
                                        return nil
                                    }
                                }

                                let inputs = productsInputs.map {
                                    // NOTE: Assumes all example list items are edible (edible: true). To change this set this flag in the productsWithQuantity tuples.
                                    ListItemInput(name: $0.product.product.item.name, quantity: $0.quantity, price: 0, refPrice: nil, refQuantity: 1, section: $0.product.product.item.category.name, sectionColor: $0.product.product.item.category.color, note: nil, baseQuantity: $0.product.baseQuantity, secondBaseQuantity: $0.product.secondBaseQuantity.value, unit: $0.product.unit.name, brand: $0.product.product.brand, edible: true)
                                }
                                
                                Prov.listItemsProvider.addNew(listItemInputs: inputs, list: exampleList, status: .todo, realmData: nil, weakSelf.resultHandler(onSuccess: {[weak self] foo in
                                    logger.d("Finish adding example list")
                                    
                                    self?.onCreateExampleList?()
                                    
                                    onFinish?()
                                    
                                    }, onError: {result in
                                        logger.e("Error adding example list items, result: \(result), inputs: \(inputs)")
                                        onFinish?()
                                }))
                                                                
                                }, onError: {result in
                                    logger.e("Error adding example list, result: \(result), group: \(exampleList)")
                                    onFinish?()
                            }))
                        }
                        }, onError: {result in
                            logger.e("Error querying products, result: \(result)")
                            onFinish?()
                    }))
                } else {
                    logger.d("User already has lists, skipping")
                    onFinish?()
                }
                }, onError: {result in
                    logger.e("Error fetching list, result: \(result)")
                    onFinish?()
            }))
        }

            
        // TODO!!!!!!!!!!!!!!!!!!!! move init containers to app delegate - since intro is shown on top of lists controller, the first time user loads the app will trigger error messages because lists (for controller behind) can't be loaded (since containers don't exist yet).
        initRealmContainers {success in
            guard success else {
                onComplete()
                return
            }
            
            logger.d("Finished init realm containers")
            prefillDatabase {success, defaultUnits in
                
                let unitDict = defaultUnits.toDictionary {defaultUnit in
                    (defaultUnit.id, defaultUnit)
                }
                
                logger.d("Finished copying prefill database")
                initDefaultInventory {inventoryMaybe in
                    logger.d("Finished adding default inventory")
                    
                    initExampleRecipe(unitDict: unitDict) {

//                    initExampleGroup(unitDict: unitDict) { // Disabled, getting exception "Can not add objects from a different Realm" after adding "Item" Realm object (no idea why). We don't use groups anymore anyway.
//                        logger.d("Finished adding example group")
                        if let inventory = inventoryMaybe {
                            initExampleList(inventory, unitDict: unitDict) {
                                logger.d("Finished adding example list")
                                onComplete()
                            }
                        } else {
                            logger.d("Didn't add default inventory so can't add example list")
                            onComplete()
                        }
//                    }
                    }
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

    func swipeViewWillBeginDragging(_ swipeView: SwipeView!) {
        beforeFirstSliderDrag = false
    }

    func swipeViewDidScroll(_ swipeView: SwipeView!) {
        let progress = swipeView.scrollOffset

        // at the beginning the swiper triggers some scroll events with 0, which would reset the animation (the first page is > 0%)
        // so we don't react to events until the user has dragged the first time
        if !beforeFirstSliderDrag {
            let whole = Int(progress) // whole part of progress number
            let fraction: Double = Double(progress) - Double(Int(progress)) // fraction part of progress number

            // if let normally not necessary - just in case
            if let interval = animationIntervals[safe: whole + 1] { // get animation interval
                let animProgress = interval.1 * Double(fraction) + interval.0 // calculate animation progress
                animationView.animationProgress = CGFloat(animProgress) / 100
            }
        }
    }
    
    deinit {
        logger.v("Deinit intro controller")
    }
}

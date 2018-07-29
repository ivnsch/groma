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

    var onCreateExampleList: ((Bool) -> Void)? // bool: success creating example list
    
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

        background({ () -> LOTComposition? in
            return LOTComposition(name: "groma-intro-02")
        }) { [weak self] composition in
            self?.animationView.sceneModel = composition
        }

        if let firstSceneStart = animationIntervals[safe: 1] {
            animationView.play(toProgress: CGFloat(firstSceneStart.0 / 100), withCompletion: nil)
        } else {
            logger.e("Start of first intro scene not found", .ui)
        }
    }

    // TODO remove animation intervals - we don't use them anymore - except to display the first but this can be done via (animation)frame - tired!
    fileprivate func initAnimationIntervals() {
        // progress percentage of idle scenes in animation (about in the middle of the respective idle interval)
        // got these numbers with trial and error - if the animation changes these numbers (most probably) have to be updated.
        let starts = [ 0, 13.5, 38, 67, 98 ]
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
                    
                    Prov.productProvider.products(productsWithBrands, weakSelf.resultHandler(onSuccess: { [weak self] products in
                        
                        if products.count < productsWithBrands.count {
                            logger.e("Unexpected: Some of the products for the example list are not in the database. Found products(\(products.count)): \(products.map{$0.item.name}), searched(\(productsWithBrands.count)): \(productsWithBrands.map{$0.name})")
                            onFinish?()
                            self?.onCreateExampleList?(false)

                        } else {
                            Prov.listProvider.add(exampleList, remote: true, weakSelf.resultHandler(onSuccess: { addedList in
                                self?.onCreateExampleList?(true)
                                onFinish?()


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
                                    ListItemInput(name: $0.product.product.item.name, quantity: $0.quantity, refPrice: nil, refQuantity: 1, section: $0.product.product.item.category.name, sectionColor: $0.product.product.item.category.color, note: nil, baseQuantity: $0.product.baseQuantity, secondBaseQuantity: $0.product.secondBaseQuantity, unit: $0.product.unit.name, brand: $0.product.product.brand, edible: true)
                                }

                                Prov.listItemsProvider.addNew(listItemInputs: inputs, list: exampleList, status: .todo, overwriteColorIfAlreadyExists: true, realmData: nil, weakSelf.resultHandler(onSuccess: {[weak self] foo in
                                    logger.d("Finish adding example list")

                                    self?.onCreateExampleList?(true)

                                    onFinish?()

                                    }, onError: { result in
                                        logger.e("Error adding example list items, result: \(result), inputs: \(inputs)")
                                        onFinish?()
                                    }
                                ))

                            }, onError: { result in
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
                        if let inventory = inventoryMaybe {
                            initExampleList(inventory, unitDict: unitDict) {
                                logger.d("Finished adding example list")
                                onComplete()
                            }
                        } else {
                            logger.d("Didn't add default inventory so can't add example list")
                            onComplete()
                        }
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
    
    func exit() {
        PreferencesManager.savePreference(PreferencesManagerKey.showIntro, value: false)
        self.modalTransitionStyle = .crossDissolve
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func onLoginSuccess() {
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
        v.setup(source: mode, controller: self)
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

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    // animation
    // yes, this has to be refactored. it's late!

    private var lastSwipeViewOffset: CGFloat = 0
    
    private var animating1 = false
    private var animating2 = false
    private var animating3 = false
    private var animating4 = false
    private var animating5 = false
    private var animating6 = false

    func swipeViewDidScroll(_ swipeView: SwipeView!) {
        let progress = swipeView.scrollOffset

        let direction = lastSwipeViewOffset < progress ? 1 : -1

        if progress > 0.40 && progress < 0.60 {
            if direction == 1 {
                if animating2 || animating3 || animating4 || animating5 || animating6 {
                    animationView.stop()
                }
                animating1 = true
                animationView.play(fromFrame: 25, toFrame: 55, withCompletion: { [weak self] finished in
                    self?.animating1 = false
                })
            } else if direction == -1 {
                if animating1 || animating3 || animating4 || animating5 || animating6 {
                    animationView.stop()
                }
                animating2 = true
                animationView.play(fromFrame: 55, toFrame: 25, withCompletion: { [weak self] finished in
                    self?.animating2 = false
                })
            }
        } else if progress > 1.40 && progress < 1.60 {
            if direction == 1 {
                if animating2 || animating1 || animating4 || animating5 || animating6 {
                    animationView.stop()
                }
                animating3 = true
                animationView.play(fromFrame: 55, toFrame: 101, withCompletion: { [weak self] finished in
                    self?.animating3 = false
                })
            } else if direction == -1 {
                if animating2 || animating3 || animating1 || animating5 || animating6 {
                    animationView.stop()
                }
                animating4 = true
                animationView.play(fromFrame: 101, toFrame: 55, withCompletion: { [weak self] finished in
                    self?.animating4 = false
                })
            }
        } else if progress > 2.40 && progress < 2.60 {
            if direction == 1 {
                if animating2 || animating3 || animating4 || animating1 || animating6 {
                    animationView.stop()
                }
                animating5 = true
                animationView.play(fromFrame: 101, toFrame: 148, withCompletion: { [weak self] finished in
                    self?.animating5 = false
                })
            } else if direction == -1 {
                if animating2 || animating3 || animating4 || animating5 || animating1 {
                    animationView.stop()
                }
                animating6 = true
                animationView.play(fromFrame: 148, toFrame: 101, withCompletion: { [weak self] finished in
                    self?.animating6 = false
                })
            }
        }

        lastSwipeViewOffset = progress
    }

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////

    deinit {
        logger.v("Deinit intro controller")
    }
}

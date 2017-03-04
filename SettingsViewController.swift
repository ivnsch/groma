//
//  SettingsViewController.swift
//  shoppin
//
//  Created by ischuetz on 04/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import QorumLogs
import Providers
import RealmSwift

enum SettingId {
    case clearHistory, overwriteData, removeAccount, enableRealTime, addDummyHistoryItems, clearAllData, restorePrefillProducts, restoreHints
}

class Setting {
    let id: SettingId
    init(id: SettingId) {
        self.id = id
    }
}

class SimpleSetting: Setting {
    let label: String
    let labelColor: UIColor
    let hasHelp: Bool
    init(id: SettingId, label: String, labelColor: UIColor = UIColor.black, hasHelp: Bool = false) {
        self.label = label
        self.labelColor = labelColor
        self.hasHelp = hasHelp
        super.init(id: id)
    }
}

class SwitchSetting: Setting {
    let label: String
    var on: Bool
    init(id: SettingId, label: String, on: Bool) {
        self.label = label
        self.on = on
        super.init(id: id)
    }
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchSettingCellDelegate, SimpleSettingCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let clearHistorySetting = SimpleSetting(id: .clearHistory, label: "Clear history") // debug
    fileprivate let overwriteDataSetting = SimpleSetting(id: .overwriteData, label: trans("setting_overwrite_data"), labelColor: UIColor.flatRed, hasHelp: true)
    fileprivate let removeAccountSetting = SimpleSetting(id: .removeAccount, label: trans("setting_remove_account"), labelColor: UIColor.flatRed)
    fileprivate let restorePrefillProductsSetting = SimpleSetting(id: .restorePrefillProducts, label: trans("setting_restore_bundled_products"), hasHelp: true)
    fileprivate let restoreHintsSetting = SimpleSetting(id: .restoreHints, label: trans("setting_restore_hints"), hasHelp: true)
    
    // developer
    fileprivate let addDummyHistoryItemsSetting = SimpleSetting(id: .addDummyHistoryItems, label: "Add dummy history items") // debug
    fileprivate let clearAllDataSetting = SimpleSetting(id: .clearAllData, label: "Clear all data") // debug
    
    fileprivate var settings: [Setting] = []
    
    fileprivate let overwritePopupMessage: String = trans("popups_settings_overwrite")
    
    fileprivate let restoreProductsMessage: String = trans("popups_restore_bundled_products")
    
    fileprivate let restoreHintsMessage: String = trans("popups_restore_hints")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = Theme.defaultTableViewBGColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateServerRelatedItemsUI()
    }
    
    fileprivate func updateServerRelatedItemsUI() {
        let showServerThings = ConnectionProvider.connectedAndLoggedIn
        
        if showServerThings {
            let realTimeConnectionSetting = SwitchSetting(id: .enableRealTime, label: trans("setting_real_time_connection"), on: Prov.userProvider.isWebsocketConnected())
            
            settings = [
//                clearHistorySetting,
                realTimeConnectionSetting,
                overwriteDataSetting,
                removeAccountSetting,
//                addDummyHistoryItemsSetting,
//                clearAllDataSetting,
                restorePrefillProductsSetting,
                restoreHintsSetting
            ]
        } else {
            settings = [
//                clearHistorySetting,
//                addDummyHistoryItemsSetting,
//                clearAllDataSetting,
                restorePrefillProductsSetting,
                restoreHintsSetting
            ]
        }
        
        tableView.reloadData()
    }
    
    // MARK: -
    
    // Debug only
    fileprivate func removeHistory() {
        Prov.historyProvider.removeAllHistoryItems(successHandler{
            AlertPopup.show(message: "The history was cleared", controller: self)
        })
    }
    
    fileprivate func overwriteData() {
        ConfirmationPopup.show(title: trans("popup_title_warning"), message: overwritePopupMessage, okTitle: trans("popup_button_continue"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            weakSelf.progressVisible()
            Prov.globalProvider.fullDownload(weakSelf.successHandler({result in
                AlertPopup.show(message: trans("popup_your_data_was_overwritten"), controller: weakSelf)
            }))
        }, onCancel: nil)
    }
    
    fileprivate func removeAccount() {
        ConfirmationPopup.show(message: trans("popup_are_you_sure_remove_account"), okTitle: trans("popup_button_yes"), controller: self, onOk: {[weak self] in
            
            if let weakSelf = self {
                
                Prov.userProvider.removeAccount(weakSelf.successHandler({
                    // note possible credentials login token deleted in removeAccount
                    FBSDKLoginManager().logOut() // in case we logged in using fb
                    GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
                    
                    AlertPopup.show(title: trans("popup_title_success"), message: trans("popup_your_account_was_removed"), controller: weakSelf, onDismiss: {
                        // TODO check that the user here is logged out already
                        weakSelf.updateServerRelatedItemsUI()
                    })
                }))
            }
        })
    }
    
    fileprivate func setWebsocketSettingEnabled(_ enabled: Bool) {
        WebsocketHelper.saveWebsocketDisabled(!enabled)
        if enabled {
            Prov.userProvider.connectWebsocketIfLoggedIn()
        } else {
            Prov.userProvider.disconnectWebsocket()
        }
    }
    
    // Debug only
    fileprivate func addDummyHistoryItems() {
        
        let user = DBSharedUser(email: "")
        
        Prov.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            
            if let weakSelf = self {
                
                if let inventory = inventories.first {
                    
                    Prov.productProvider.products(NSRange(location: 0, length: 500), sortBy: .alphabetic, weakSelf.successHandler{(products: Results<QuantifiableProduct>) in
                        
                        guard products.count > 0 else {
                            AlertPopup.show(message: "You need some products to be able to add history items", controller: weakSelf)
                            return
                        }
                        
                        // In order to fill the stats - add a random number if history items between 2 and 50 for each month to each of the past 12 months (excluding current, it's maybe better for testers to have current month empty so they can see more clearly the effect of items they are adding)
                        let historyItems: [[HistoryItem]] = stride(from: (-1), to: -12, by: -1).map {monthOffset in
                            
                            let date: Date = Date.inMonths(monthOffset)
                            
                            // Sync tests on device, iPhone 6
                            // max 10.000: Doesn't work: memory crash building sync request
                            // max 5.000 Doesn't work: (month item count were between 1645 and 4895): does build request (takes very long), 14 mb, server rejects (413 response, max payload configured to 10mb)
                            // max 2.000: Takes long, but works: (month item count were between 790 and 1860): does request (takes about 1 min), 6 mb, response only 500kb (gzip), processed correctly.
                            
                            let monthItemsCount = Int.random(2, max: 300)
                            QL1("Generating history item count: \(monthItemsCount) for date: \(date)")
                            let monthHistoryItems: [HistoryItem] = (2..<monthItemsCount).map {_ in
                                let randomIndex = Int.random(products.count)
                                let product = products[randomIndex]
                                return HistoryItem(uuid: UUID().uuidString, inventory: inventory, product: product, addedDate: date.toMillis(), quantity: Float(Int.random(10)), user: user, paidPrice: Float(Double.random()) * 2)
                            }
                            return monthHistoryItems
                        }
                        
                        // put the history items for past months in a flat array and save
                        let flattened: [HistoryItem] = Array(historyItems.joined())
                        Prov.historyProvider.addHistoryItems(flattened, weakSelf.successHandler{
                            AlertPopup.show(message: "Dummy history items added to inventory: \(inventory.name)", controller: weakSelf)
                            })
                        })
                    
                } else {
                    AlertPopup.show(message: "You need to have at least 1 inventory to add history items", controller: weakSelf)
                }
                
            } else {
                print("Warn: SettingsViewController.onAddDummyHistoryTap: weakSelf is not set")
            }
        })
    }
    
    // Debug only
    fileprivate func clearAllData() {
        Prov.globalProvider.clearAllData(false, handler: successHandler{
            AlertPopup.show(message: "The data was cleared", controller: self)
        })
    }
    
    fileprivate func restorePrefillProducts() {
        
        func onRestored() {
            AlertPopup.show(message: trans("popup_title_bundled_products_restored"), controller: self)
        }
        
        ConfirmationPopup.show(title: trans("popup_title_restore_bundled_products"), message: restoreProductsMessage, okTitle: trans("popup_button_restore_bundled_product"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
        
            Prov.productProvider.restorePrefillProductsLocal(weakSelf.resultHandler(resetProgress: false, onSuccess: {restoredSomething in
                if restoredSomething {
                    if ConnectionProvider.connectedAndLoggedIn {
                        weakSelf.progressVisible()
                        Prov.globalProvider.sync(false, handler: weakSelf.successHandler{syncResult in
                            onRestored()
                        })
                    } else {
                        onRestored()
                    }
                } else {
                    AlertPopup.show(message: trans("popup_you_already_use_bundled_products"), controller: weakSelf)
                }
            }, onErrorAdditional: {_ in }))
            
        }, onCancel: nil)

    }
    
    fileprivate func restoreHints() {
        PreferencesManager.clearPreference(key: .shownCanSwipeToOpenStash)
        PreferencesManager.clearPreference(key: .showedAddDirectlyToInventoryHelp)
        PreferencesManager.clearPreference(key: .showedDeleteHistoryItemHelp)
        PreferencesManager.savePreference(.showedCanSwipeToIncrementCounter, value: NSNumber(value: SwipeToIncrementAlertHelperNew.countToShowPopup as Int)) // show first time user tries to increment after this
        PreferencesManager.savePreference(.showedLongTapToEditCounter, value: NSNumber(value: SwipeToIncrementAlertHelperNew.countToShowPopup as Int)) // show first time user tries to increment after this
        PreferencesManager.savePreference(.showedTapToEditCounter, value: NSNumber(value: 0))
        AlertPopup.show(message: trans("popup_hints_restored"), controller: self)
    }
    
    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settings[(indexPath as NSIndexPath).row]
        
        switch setting.id {
        case .clearHistory:
            removeHistory()
        case .enableRealTime:
            return // handled in switch delegate
        case .overwriteData:
            overwriteData()
        case .removeAccount:
            removeAccount()
        case .addDummyHistoryItems:
            addDummyHistoryItems()
        case .clearAllData:
            clearAllData()
        case .restorePrefillProducts:
            restorePrefillProducts()
        case .restoreHints:
            restoreHints()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[(indexPath as NSIndexPath).row]
        
        let cell: UITableViewCell = {
            if let simpleSetting = setting as? SimpleSetting {
                let cell = tableView.dequeueReusableCell(withIdentifier: "simpleSetting", for: indexPath) as! SimpleSettingCell
                cell.setting = simpleSetting
                cell.delegate = self
                return cell
                
            } else if let switchSetting = setting as? SwitchSetting {
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchSetting", for: indexPath) as! SwitchSettingCell
                cell.setting = switchSetting
                cell.delegate = self
                return cell
                
            } else {
                fatalError("Forgot to handle a setting type!")
            }
        }()
        
        cell.contentView.addBottomBorderWithColor(Theme.cellBottomBorderColor, width: 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    // MARK: - SwitchSettingCellDelegate
    
    func onSwitch(_ setting: SwitchSetting, on: Bool) {
        switch setting.id {
        case .enableRealTime:
            setWebsocketSettingEnabled(on)
        default:
            QL3("Not supported: \(setting)")
            break
        }
    }
    
    // MARK: - SimpleSettingCellDelegate
    
    func onSimpleSettingHelpTap(_ cell: SimpleSettingCell, setting: SimpleSetting) {
        switch setting.id {
        case .overwriteData:
            AlertPopup.show(message: overwritePopupMessage, controller: self)
            
        case .restorePrefillProducts:
            AlertPopup.show(message: restoreProductsMessage, controller: self)

        case .restoreHints:
            AlertPopup.show(message: restoreHintsMessage, controller: self)

        default: QL4("No supported setting: \(setting)")
        }
    }
    
    deinit {
        QL1("Deinit settings controller")
    }
}

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

enum SettingId {
    case ClearHistory, OverwriteData, RemoveAccount, EnableRealTime, AddDummyHistoryItems, ClearAllData, RestorePrefillProducts
}

class Setting {
    let id: SettingId
    init(id: SettingId) {
        self.id = id
    }
}

class SimpleSetting: Setting {
    let label: String
    init(id: SettingId, label: String) {
        self.label = label
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

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchSettingCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private let clearHistorySetting = SimpleSetting(id: .ClearHistory, label: "Clear history")
    private let overwriteDataSetting = SimpleSetting(id: .OverwriteData, label: "Overwrite data")
    private let removeAccountSetting = SimpleSetting(id: .RemoveAccount, label: "Remove account")
    private let restorePrefillProductsSetting = SimpleSetting(id: .RestorePrefillProducts, label: "Restore bundled products")

    // developer
    private let addDummyHistoryItemsSetting = SimpleSetting(id: .AddDummyHistoryItems, label: "Add dummy history items")
    private let clearAllDataSetting = SimpleSetting(id: .ClearAllData, label: "Clear all data")
    
    private var settings: [Setting] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        updateServerRelatedItemsUI()
    }
    
    private func updateServerRelatedItemsUI() {
        let showServerThings = ConnectionProvider.connectedAndLoggedIn
        
        if showServerThings {
            let realTimeConnectionSetting = SwitchSetting(id: .EnableRealTime, label: "Real time connection", on: Providers.userProvider.isWebsocketConnected())
            
            settings = [
                clearHistorySetting,
                realTimeConnectionSetting,
                overwriteDataSetting,
                removeAccountSetting,
                addDummyHistoryItemsSetting,
                clearAllDataSetting,
                restorePrefillProductsSetting
            ]
        } else {
            settings = [
                clearHistorySetting,
                addDummyHistoryItemsSetting,
                clearAllDataSetting,
                restorePrefillProductsSetting
            ]
        }
        
        tableView.reloadData()
    }
    
    // MARK: -
    
    private func removeHistory() {
        Providers.historyProvider.removeAllHistoryItems(successHandler{
            AlertPopup.show(message: "The history was cleared", controller: self)
        })
    }
    
    private func overwriteData() {
        ConfirmationPopup.show(title: "Warning", message: "This will overwrite all your (Groma) data on this device with the data stored in the server. You may lose data.\nThis is only a helper to solve technical problems and is not necessary under normal circumstances.", okTitle: "Continue", cancelTitle: "Cancel", controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            weakSelf.progressVisible()
            Providers.globalProvider.fullDownload(weakSelf.successHandler({result in
                AlertPopup.show(message: "Your local data was overwritten", controller: weakSelf)
            }))
        }, onCancel: nil)
    }
    
    private func removeAccount() {
        ConfirmationPopup.show(message: "Are you sure you want to remove your account?", controller: self, onOk: {[weak self] in
            
            if let weakSelf = self {
                
                Providers.userProvider.removeAccount(weakSelf.successHandler({
                    // note possible credentials login token deleted in removeAccount
                    FBSDKLoginManager().logOut() // in case we logged in using fb
                    GIDSignIn.sharedInstance().signOut()  // in case we logged in using google
                    
                    AlertPopup.show(title: "Success", message: "Your account was removed", controller: weakSelf, onDismiss: {
                        // TODO check that the user here is logged out already
                        weakSelf.updateServerRelatedItemsUI()
                    })
                }))
            }
        })
    }
    
    private func setWebsocketSettingEnabled(enabled: Bool) {
        WebsocketHelper.saveWebsocketDisabled(!enabled)
        if enabled {
            Providers.userProvider.connectWebsocketIfLoggedIn()
        } else {
            Providers.userProvider.disconnectWebsocket()
        }
    }
    
    private func addDummyHistoryItems() {
        
        let user = SharedUser(email: "dummy@user.test")
        
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            
            if let weakSelf = self {
                
                if let inventory = inventories.first {
                    Providers.productProvider.products(NSRange(location: 0, length: 500), sortBy: .Alphabetic, weakSelf.successHandler{products in
                        
                        guard products.count > 0 else {
                            AlertPopup.show(message: "You need some products to be able to add history items", controller: weakSelf)
                            return
                        }
                        
                        // In order to fill the stats - add a random number if history items between 2 and 50 for each month to each of the past 12 months (excluding current, it's maybe better for testers to have current month empty so they can see more clearly the effect of items they are adding)
                        let historyItems: [[HistoryItem]] = (-1).stride(to: -12, by: -1).map {monthOffset in
                            
                            let date: NSDate = NSDate.inMonths(monthOffset)
                            
                            // Sync tests on device, iPhone 6
                            // max 10.000: Doesn't work: memory crash building sync request
                            // max 5.000 Doesn't work: (month item count were between 1645 and 4895): does build request (takes very long), 14 mb, server rejects (413 response, max payload configured to 10mb)
                            // max 2.000: Takes long, but works: (month item count were between 790 and 1860): does request (takes about 1 min), 6 mb, response only 500kb (gzip), processed correctly.
                            
                            let monthItemsCount = Int.random(2, max: 2000)
                            QL1("Generating history item count: \(monthItemsCount) for date: \(date)")
                            let monthHistoryItems: [HistoryItem] = (2..<monthItemsCount).map {_ in
                                let randomIndex = Int.random(products.count)
                                let product = products[randomIndex]
                                return HistoryItem(uuid: NSUUID().UUIDString, inventory: inventory, product: product, addedDate: date.toMillis(), quantity: Int.random(10), user: user, paidPrice: Float(Double.random()) * 10)
                            }
                            return monthHistoryItems
                        }
                        
                        // put the history items for past months in a flat array and save
                        let flattened: [HistoryItem] = Array(historyItems.flatten())
                        Providers.historyProvider.addHistoryItems(flattened, weakSelf.successHandler{
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
    
    private func clearAllData() {
        Providers.globalProvider.clearAllData(false, handler: successHandler{
            AlertPopup.show(message: "The data was cleared", controller: self)
        })
    }
    
    private func restorePrefillProducts() {
        
        func onRestored() {
            AlertPopup.show(message: "Products restored", controller: self)
        }
        
        ConfirmationPopup.show(title: "Restore Products", message: "This will restore bundled products that you deleted since the intallation of the app, or in case you changed the language of the device, add all the bundled products in the new language. Your existing producs and items are not affected.\nNote: If you changed the language and still have products in the old language, you'll end with multiple versions of the same product for the different languages.", okTitle: "Restore", cancelTitle: "Cancel", controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
        
            Providers.productProvider.restorePrefillProductsLocal(weakSelf.resultHandler(resetProgress: false, onSuccess: {restoredSomething in
                if restoredSomething {
                    if ConnectionProvider.connectedAndLoggedIn {
                        weakSelf.progressVisible()
                        Providers.globalProvider.sync(false, handler: weakSelf.successHandler{syncResult in
                            onRestored()
                        })
                    } else {
                        onRestored()
                    }
                } else {
                    AlertPopup.show(message: "You're already using all the bundled products.", controller: weakSelf)
                }
            }, onErrorAdditional: {_ in }))
            
        }, onCancel: nil)

    }
    
    // MARK: - UITableView

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let setting = settings[indexPath.row]
        
        switch setting.id {
        case .ClearHistory:
            removeHistory()
        case .EnableRealTime:
            return // handled in switch delegate
        case .OverwriteData:
            overwriteData()
        case .RemoveAccount:
            removeAccount()
        case .AddDummyHistoryItems:
            addDummyHistoryItems()
        case .ClearAllData:
            clearAllData()
        case .RestorePrefillProducts:
            restorePrefillProducts()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let setting = settings[indexPath.row]
        
        let cell: UITableViewCell = {
            if let simpleSetting = setting as? SimpleSetting {
                let cell = tableView.dequeueReusableCellWithIdentifier("simpleSetting", forIndexPath: indexPath) as! SimpleSettingCell
                cell.setting = simpleSetting
                return cell
                
            } else if let switchSetting = setting as? SwitchSetting {
                let cell = tableView.dequeueReusableCellWithIdentifier("switchSetting", forIndexPath: indexPath) as! SwitchSettingCell
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
    
    // MARK: - SwitchSettingCellDelegate
    
    func onSwitch(setting: SwitchSetting, on: Bool) {
        switch setting.id {
        case .EnableRealTime:
            setWebsocketSettingEnabled(on)
        default:
            QL3("Not supported: \(setting)")
            break
        }
    }
    
    deinit {
        QL1("Deinit settings controller")
    }
}
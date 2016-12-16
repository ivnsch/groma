//
//  RatingAlert.swift
//  shoppin
//
//  Created by ischuetz on 14/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

protocol RatingAlertDelegate: class {
    func onDismissRatingAlert()
}

class RatingAlert: EmailHelperDelegate {

    fileprivate let showLaterDays = 7
    
    weak var delegate: RatingAlertDelegate?

    fileprivate var controller: UIViewController?
    
    func checkShow(_ parentController: UIViewController) {
        
        func appInstallDate() -> Date {
            return PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) ?? {
                QL4("Invalid state: There's no app first launch date stored.")
                return Date() // just to return something - note that with this we will never show the popup as the time offset will be ~0
            }()
        }
        
        // When the user hasn't selected "never show again"
        func onCanShow() {
            // use last time user tapped "later" as reference date or the app install date if this hasn't happened yet
            let referenceDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastAppRatingDialogDate).map {(date: Date) in
                return date
                } ?? appInstallDate()
            
            let passedDays = referenceDate.daysUntil(Date())
            QL1("\(passedDays) days passed since last reference date. Showing if >= \(showLaterDays)")
            if passedDays >= showLaterDays {
                show(parentController)
            }
        }
        
        if let selectedNeverShow: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.dontShowAppRatingDialogAgain) {
            if !selectedNeverShow {
                onCanShow()
            } else {
                QL1("User selected to never show rating popup.")
            }
        } else {
            QL1("The rating dialog was never shown yet. Checking time.")
            onCanShow()
        }
    }
    
    fileprivate var em: EmailHelper? = nil
    
    fileprivate func show(_ controller: UIViewController) {
        
        self.controller = controller
        
        let alert = UIAlertController(title: trans("popup_title_rate_app"), message: trans("popup_please_rate_app"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: trans("popup_button_rate_app"), style: .default) {[weak self ]alertAction in guard let weakSelf = self else {return}
            if let url = URL(string: Constants.appStoreLink) {
                
                if UIApplication.shared.openURL(url) {
                    QL1("Rating dialog: opened app store")
                    PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true) // rating has practically the same meaning as selecting don't show again
                    
                } else {
                    QL1("Rating dialog: Couldn't open app store url")
                    AlertPopup.show(message: trans("popup_couldnt_open_app_store_url"), controller: controller)
                }
            } else {
                QL4("Url is nil, can't go to rating")
            }
            
            alert.dismiss(animated: true, completion: nil)
            weakSelf.delegate?.onDismissRatingAlert()
        })
        
        alert.addAction(UIAlertAction(title: trans("popup_button_rate_feedback"), style: .default) {[weak self] alertAction in
            QL1("Rating dialog: selected Send feedback")
            PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true)
            self?.em = EmailHelper(controller: controller)
            self?.em?.delegate = self
            self?.em?.showEmail()
            
            alert.dismiss(animated: true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })

        alert.addAction(UIAlertAction(title: trans("popup_button_rate_ask_later"), style: .default) {[weak self] alertAction in
            QL1("Rating dialog: selected ask me later")
            PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: Date())
            
            alert.dismiss(animated: true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })
        
        alert.addAction(UIAlertAction(title: trans("popup_button_rate_dont_ask_again"), style: .default) {[weak self] alertAction in
            QL1("Rating dialog: selected don't ask again")
            PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: Date())
            
            alert.dismiss(animated: true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })
        
        controller.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - EmailHelperDelegate
    
    func onEmailSent() {
        controller?.presentingViewController?.dismiss(animated: true, completion: nil)
        delegate?.onDismissRatingAlert()
    }
}

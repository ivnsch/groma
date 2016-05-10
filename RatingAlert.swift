//
//  RatingAlert.swift
//  shoppin
//
//  Created by ischuetz on 14/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol RatingAlertDelegate: class {
    func onDismissRatingAlert()
}

class RatingAlert: EmailHelperDelegate {

    private let showLaterDays = 7
    
    weak var delegate: RatingAlertDelegate?

    private var controller: UIViewController?
    
    func checkShow(parentController: UIViewController) {
        
        func appInstallDate() -> NSDate {
            return PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) ?? {
                QL4("Invalid state: There's no app first launch date stored.")
                return NSDate() // just to return something - note that with this we will never show the popup as the time offset will be ~0
            }()
        }
        
        // When the user hasn't selected "never show again"
        func onCanShow() {
            // use last time user tapped "later" as reference date or the app install date if this hasn't happened yet
            let referenceDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastAppRatingDialogDate).map {(date: NSDate) in
                return date
                } ?? appInstallDate()
            
            let passedDays = referenceDate.daysUntil(NSDate())
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
    
    private var em: EmailHelper? = nil
    
    private func show(controller: UIViewController) {
        
        self.controller = controller
        
        let alert = UIAlertController(title: "Rate Groma", message: "If you love Groma, please take a moment to rate it", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Rate", style: .Default) {[weak self ]alertAction in guard let weakSelf = self else {return}
            if let url = NSURL(string: Constants.appStoreLink) {
                
                if UIApplication.sharedApplication().openURL(url) {
                    QL1("Rating dialog: opened app store")
                    PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true) // rating has practically the same meaning as selecting don't show again
                    
                } else {
                    QL1("Rating dialog: Couldn't open app store url")
                    AlertPopup.show(message: "Couldn't open app store url.", controller: controller)
                }
            } else {
                QL4("Url is nil, can't go to rating")
            }
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            weakSelf.delegate?.onDismissRatingAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Send feedback", style: .Default) {[weak self] alertAction in
            QL1("Rating dialog: selected Send feedback")
            PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true)
            self?.em = EmailHelper(controller: controller)
            self?.em?.delegate = self
            self?.em?.showEmail()
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })

        alert.addAction(UIAlertAction(title: "Ask me later", style: .Default) {[weak self] alertAction in
            QL1("Rating dialog: selected ask me later")
            PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: NSDate())
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })
        
        alert.addAction(UIAlertAction(title: "Don't ask again", style: .Default) {[weak self] alertAction in
            QL1("Rating dialog: selected don't ask again")
            PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: NSDate())
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            self?.delegate?.onDismissRatingAlert()
        })
        
        controller.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - EmailHelperDelegate
    
    func onEmailSent() {
        controller?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        delegate?.onDismissRatingAlert()
    }
}
//
//  WebsocketHelper.swift
//  shoppin
//
//  Created by ischuetz on 29/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct WebsocketHelper {

    // Returns if client tries to open a connection. NOTE only this, we don't know if there's a connection as the server hasn't answered when we return from this method. Also websocket client-init can fail (we don't return anything here, only logs). In most cases it shouldn't though since we check for connection and login status in advance and this is the only reason because of which this can fail.
    static func tryConnectWebsocket() -> Bool {
        if ConnectionProvider.connectedAndLoggedIn {
            if userDisabledWebsocket() {
                QL2("User diabled websocket, not connecting")
                return false
            } else {
                QL2("Connecting websocket...")
                Providers.userProvider.connectWebsocketIfLoggedIn()
                return true
            }
        } else {
            QL2("Not connected or logged in - can't open websocket connection")
            return false
        }
    }
    
    static func userDisabledWebsocket() -> Bool {
        return PreferencesManager.loadPreference(PreferencesManagerKey.userDisabledWebsocket) ?? false
    }
    
    static func saveWebsocketDisabled(_ disabled: Bool) {
        // this if else is a quick fix because passing directly disabled doesn't compile TODO proper fix
        if disabled {
            PreferencesManager.savePreference(PreferencesManagerKey.userDisabledWebsocket, value: true)
        } else {
            PreferencesManager.savePreference(PreferencesManagerKey.userDisabledWebsocket, value: false)
        }
    }
}

//
//  MyWebSocket.swift
//  shoppin
//
//  Created by ischuetz on 22/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Starscream
import Valet
import QorumLogs

class MyWebSocket: WebSocketDelegate {
    
    private var socket: WebSocket?

    private var subscribedLists: [String] = []
    private var subscribedInventories: [String] = []
    
    init() {
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)
        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        if let token = maybeToken {
            socket = WebSocket(url: NSURL(string: "ws://\(Urls.hostIPPort)/ws")!)
            socket?.delegate = self
            socket?.headers["X-Auth-Token"] = token
            socket?.headers["Content-Type"] = "application/json"
            socket?.connect()
        }
    }
    
    // Unsubscribes if the user is logged in. After the server acks the socket connection is disconnected.
    func disconnect() {
        do {
            let dict = ["topics": subscribedLists + subscribedInventories]
            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
            if let str = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                
                QL1("Websocket: Sending string: \(str)")
                socket?.writeString(str)
                
            } else {
                QL4("Invalid serialization result: dict: \(dict), data: \(data)")
            }
        } catch let e as NSError {
            QL4("Error serializing json: \(e)")
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        QL2("Websocket: Connected")
        
        let deviceId = NSUUID().UUIDString

        Providers.listProvider.lists {listsResult in
            
            if let lists = listsResult.sucessResult {
                
                Providers.inventoryProvider.inventories {[weak self] inventoriesResult in
                    
                    if let inventories = inventoriesResult.sucessResult {
                        
                        // TODO new services that fetch only uuids from db
                        let listsUuids = lists.map{$0.uuid}
                        let inventoriesUuids = inventories.map{$0.uuid}
                        
                        do {
                            let dict = ["lists": listsUuids, "inventories": inventoriesUuids, "deviceId": deviceId]
                            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
                            if let str = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                                
                                print("Websocket: Sending string: \(str)")
                                socket.writeString(str)
                                
                                PreferencesManager.savePreference(PreferencesManagerKey.deviceId, value: NSString(string: deviceId))
                                self?.subscribedLists = listsUuids
                                self?.subscribedInventories = inventoriesUuids
                                
                            } else {
                                QL4("Invalid serialization result: dict: \(dict), data: \(data)")
                            }
                        } catch let e as NSError {
                            QL4("Error serializing json: \(e)")
                        }
                        
                    } else {
                        QL4("Couldn't retrieve inventories: \(inventoriesResult)")
                    }
                }
            } else {
                QL4("Couldn't retrieve lists: \(listsResult)")
            }
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            switch error.code {
            case 401:
                QL2("Not authorized, removing login token \(error)")
                Providers.userProvider.removeLoginToken()
            case 1000:
                QL4("Connection closed by server, TODO handling \(error)") // happens for example when server is restarted
                // TODO!!!! logout user? Try to connect again after a delay? In any case user should not be logged in without socket connection.
            default:
                QL4("Unknown websocket connection error: \(error)")
            }
        } else {
            QL2("Websocket: Disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        QL1("Websocket: Received text: \(text)")

        MyWebsocketDispatcher.process(text)
        
        // TODO unsubscribe ack - do we need this, if yes implement (this snippet is from old code when parsing was done in this class)
//        if let msg = dict["msg"] as? String {
//            if msg == "unsubscribed" {
//                socket.disconnect()
//                PreferencesManager.clearPreference(key: PreferencesManagerKey.deviceId)
//            }
//        } else {
//            QL4("Not handled websocket format: \(dict)")
//        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        QL1("Websocket: Received data: \(data.length)")
    }
}
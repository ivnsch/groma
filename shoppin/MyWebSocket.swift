//
//  MyWebSocket.swift
//  shoppin
//
//  Created by ischuetz on 22/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Starscream
import Valet

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
                
                print("Websocket: Sending string: \(str)")
                socket?.writeString(str)
                
            } else {
                print("Error: MyWebSocket.disconnect: invalid serialization result: dict: \(dict), data: \(data)")
            }
        } catch let e as NSError {
            print("Error: MyWebSocket.disconnect: serializing json: \(e)")
        }
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("Websocket: Connected")
        
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
                                print("Error: MyWebSocket.websocketDidConnect: invalid serialization result: dict: \(dict), data: \(data)")
                            }
                        } catch let e as NSError {
                            print("Error: MyWebSocket.websocketDidConnect: serializing json: \(e)")
                        }
                        
                    } else {
                        print("Error: MyWebSocket.websocketDidConnect: couldn't retrieve inventories: \(inventoriesResult)")
                    }
                }
            } else {
                print("Error: MyWebSocket.websocketDidConnect: couldn't retrieve lists: \(listsResult)")
            }
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            if error.code == 401 {
                print("Not authorized")
            } else {
                print("Unknown websocket connection error: \(error)")
            }
        } else {
            print("Websocket: Disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Websocket: Received text: \(text)")

        if let data = (text as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                if let dict =  json as? Dictionary<String, AnyObject>  {
                    
                    if let verb = dict["verb"] as? String, category = dict["category"] as? String, topic = dict["topic"] as? String, data = dict["message"] {
                        print("Websocket: Verb: \(verb), category: \(category), topic: \(topic), data: \(data)")
                        
                        switch category {
                        case "listitem":
                            switch verb {
                            case "update":
                                let listItem = ListItemParser.parse(data)
                                NSNotificationCenter.defaultCenter().postNotificationName("listItems", object: nil, userInfo: ["value": [listItem]])

                            default: print("Not handled verb: \(verb)")
                            }
                            

                        case "listitems":
                            switch verb {
                            case "update":
                                let dataarr = data as! [AnyObject]
                                let listItems = ListItemParser.parseArray(dataarr)
                                NSNotificationCenter.defaultCenter().postNotificationName("listItems", object: nil, userInfo: ["value": listItems])
                                
                            default: print("Not handled verb: \(verb)")
                            }
                        
                        
                        default: print("Not handled category: \(category)")
                        }
                        
                        
                    } else {
//                        print("not handled websocket format: \(dict)")
                        
                        if let msg = dict["msg"] as? String {
                            if msg == "unsubscribed" {
                                socket.disconnect()
                                PreferencesManager.clearPreference(key: PreferencesManagerKey.deviceId)
                            }
                        } else {
                            print("not handled websocket format: \(dict)")
                        }
                    }

                } else {
                    print("Warn: Websocket: Returned json could not be converted to dictionary: \(json)")
                }
                
                
                
            } catch let e as NSError {
                print("Error: MyWebSocket.websocketDidReceiveMessage: deserializing json: \(e)")
            }
        } else {
            print("Error: MyWebSocket.websocketDidReceiveMessage: couldn't get data from text: \(text)")
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("Websocket: Received data: \(data.length)")
    }
}
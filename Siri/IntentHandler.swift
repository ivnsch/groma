//
//  IntentHandler.swift
//  Siri
//
//  Created by Ivan Schuetz on 29.07.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import Intents
import Providers

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any? {
        RealmConfig.setDefaultConfiguration() // Make Realm use shared folder

        if intent is INAddTasksIntent {
            return AddTaskRequestHandler()
        }
        return nil
    }
}

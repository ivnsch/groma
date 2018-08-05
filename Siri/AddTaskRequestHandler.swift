//
//  AddTaskRequestHandler.swift
//  Siri
//
//  Created by Ivan Schuetz on 29.07.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Intents
import Providers
import RealmSwift

class AddTaskRequestHandler: NSObject, INAddTasksIntentHandling {

    func resolveTargetTaskList(for intent: INAddTasksIntent, with completion: @escaping (INTaskListResolutionResult) -> Void) {
        guard let title = intent.targetTaskList?.title else {
            completion(.needsValue())
            return
        }

        getPossibleLists(for: title) { [weak self] possibleLists in
            self?.completeResolveTaskList(with: possibleLists, for: title, with: completion)
        }
    }

    func handle(intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        Prov.listProvider.lists(false) { [weak self] result in
            if let lists = result.sucessResult {
                self?.handle(lists: lists, intent: intent, completion: completion)

            } else {
                logger.e("Error loading lists: \(String(describing: result.error))", .db)
                let response = INAddTasksIntentResponse(
                    code: .failure,
                    userActivity: .none)
                completion(response)
            }
        }
    }

    private func handle(lists: RealmSwift.List<Providers.List>, intent: INAddTasksIntent, completion: @escaping (INAddTasksIntentResponse) -> Void) {
        guard
            let taskList = intent.targetTaskList,
            let listIndex = lists.index(where: { $0.name.lowercased() == taskList.title.spokenPhrase.lowercased() }),
            let itemNames = intent.taskTitles, itemNames.count > 0
            else {
                completion(INAddTasksIntentResponse(code: .failure, userActivity: nil))
                return
        }

        // Get the list
        let list = lists[listIndex]

        completion(addListItems(itemNames: itemNames, list: list))
    }

    private func addListItems(itemNames: [INSpeakableString], list: Providers.List) -> INAddTasksIntentResponse {
        var addedTasks = [INTask]()
        let itemNamesDictionary: [String : INSpeakableString] = itemNames.toDictionary { ($0.spokenPhrase, $0) }
        for itemName in itemNames {
            let result = Prov.listItemsProvider.addNewSync(itemName: itemName.spokenPhrase, list: list)
            if let successResult = result.sucessResult {
                let listItemName = successResult.listItem.product.product.product.item.name
                if let speakableString = itemNamesDictionary[listItemName] {
                    addedTasks.append(
                        INTask(
                            title: speakableString,
                            status: .notCompleted,
                            taskType: .notCompletable,
                            spatialEventTrigger: nil,
                            temporalEventTrigger: nil,
                            createdDateComponents: nil,
                            modifiedDateComponents: nil,
                            identifier: nil)
                    )
                } else {
                    logger.e("Invalid state: Didn't find spoken phrase for list item: \(listItemName), spoken phrases: \(itemNames)", .db)
                }
            }
        }

        // Respond with the added items
        let response = INAddTasksIntentResponse(code: .success, userActivity: nil)
        response.addedTasks = addedTasks
        return response
    }

    private func getPossibleLists(for listName: INSpeakableString, callback: @escaping ([INSpeakableString]) -> Void) {

        Prov.listProvider.lists(false) { result in
            if let lists = result.sucessResult {

                var possibleLists = [INSpeakableString]()

                for list in lists {

                    if list.name.lowercased() == listName.spokenPhrase.lowercased() {
                        callback([INSpeakableString(spokenPhrase: list.name)])
                        return

                    } else if list.name.lowercased().contains(listName.spokenPhrase.lowercased()) || listName.spokenPhrase.lowercased() == "all" {
                        possibleLists.append(INSpeakableString(spokenPhrase: list.name))
                    }
                }

                callback(possibleLists)
            }
        }
    }

    private func completeResolveTaskList(with possibleLists: [INSpeakableString], for listName: INSpeakableString, with completion: @escaping (INTaskListResolutionResult) -> Void) {

        let taskLists = possibleLists.map {
            return INTaskList(title: $0, tasks: [], groupName: nil, createdDateComponents: nil, modifiedDateComponents: nil, identifier: nil)
        }

        switch possibleLists.count {
        case 0:
            completion(.unsupported())
        case 1:
            if possibleLists[0].spokenPhrase.lowercased() == listName.spokenPhrase.lowercased() {
                completion(.success(with: taskLists[0]))
            } else {
                completion(.confirmationRequired(with: taskLists[0]))
            }
        default:
            completion(.disambiguation(with: taskLists))
        }
    }
}

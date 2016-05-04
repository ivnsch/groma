//
//  HelpProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HelpProviderImpl: HelpProvider {

    func helpItems(handler: ProviderResult<[HelpItem]> -> Void) {
        handler(ProviderResult(status: .Success, sucessResult: HelpProviderImpl.helpItems))
    }

    // For now everything here and in memory, later maybe it makes sense to store these items in the prefill database?
    // (but this adds loading time at start, so maybe it's not bad in memory, also static var is lazy iirc)
    // TODO translations keys!
    private static var helpItems = [
        
        HelpItem(title: "What is the back store?", text: "This is where your list items go after you 'buy' them. You can move the back store items back to the todo list by tapping on 'reset' or tapping on each of them individually. The back store can only be accessed when there are items in it, by swiping the prices view (in the todo list) to the left."),
        
        HelpItem(title: "What are groups? Is this the same as recipes?", text: "Groups are items that belong together, identified with a name and which can be added to a list or other places at once, using the top menu. You can use them for anything you want - they are most commonly used for recipes!"),

        HelpItem(title: "What is the relationship between categories and sections?", text: "Category is how you generally want to classify a product. E.g. for apples you probably would use 'fruits'. A section is the section in the store where you find the product. The section can be different than the category! For example thuna, could have 'fish' as category but be in the 'canned food' section.\nProducts have always a category, which is used everywhere in the app. Sections only exist in shopping lists."),

        HelpItem(title: "Do I need an account?", text: "Unless you want to share your lists or inventories with other users or synchronise with other devices, you don't need an account. The functionality of the app with or without an account, besides of this, is identical."),

        HelpItem(title: "Can I use the app offline?", text: "Yes, you don't need to be logged in or have an account. If you have are logged in and go offline, the app will sync automatically when you're back online."),
        
        HelpItem(title: "How can I share lists or inventories with other people?", text: "To share lists or inventories, go to the view where the lists or inventories are listed, tap on the edit button, tap on the list or inventory you want to share and then on 'participants'. Here you can add or remove participants. Participants with pending invitations have a question mark next to them. When you are not logged in or connected the participants button is not visible."),

//        HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
        
        HelpItem(title: "Can I edit items globally? What are products?", text: "Products are the 'common unit' of all the items you manage in the app. If you want to edit the name of an item and want this to be done also in list, group, inventory and history items, you just have to edit it once in the 'manage products' screen. Also, if you want to remove a product, because e.g. you don't want to see it in the top-menu items anymore, do it in this screen."),
        
        HelpItem(title: "How do I remove products from the top menu? I never use them!", text: "You can remove them in 'Manage products' (in the ... tab)."),
        
        HelpItem(title: "When I edit the price of an item, does this affect the history or stats?", text: "No, the prices in history and stats are 'frozen' at the point of time you buy the items. If you added items with a wrong price not everything is lost: you can correct it in the list, remove the items from history and add them again."),
//      
        HelpItem(title: "What happens when I remove products?", text: "The product and all list/group/inventory, history and top-menu items associated with it will be removed. For example, if you remove 'Apples' with brand 'x', all the list, inventory, group and history and top-menu items that are named 'Apples' and have the brand 'x' Will be removed. Don't worry about products with no brand - an empty brand is handled like a brand and will only remove items with the same name that have also an empty brand."),
        
        HelpItem(title: "What happens when I remove history items?", text: "Removal of history items affects also the stats! If you, for example, remove 5x lemon cakes, bought on March the 3d, that costed $10, your stats for March will show $10 less spendings."),
        
//        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),

        HelpItem(title: "What is the 'real time connection' setting?", text: "The real time connection allows you to receive updates from another devices or users right after they are done. With the setting you can disable this. If you disable it, this will be remembered and not enabled until you enable it again. This setting is only visible when you have are logged in and connected."),
        
        HelpItem(title: "How do I read the report?", text: "The bars chart shows your monthly spedings since you started using the app back to 1 year. 'Monthly average' is the average of your spendings for the months where you have used the app. 'Daily average this month' is the daily avarage of what you've spent so far in the current month. 'Projected spendings this month' is an estimation of what you will spend in total in the current month based on what you have spent so far in this month. For example if today it's the 10th and you've spent $300 so far in this month, the projected spendings would be around $900. Tapping on a bar shows you a detail view of its month. The pie chart shows the top categories for which you have spent the most and below you see an aggregate of all the bought products in this month."),
        
        HelpItem(title: "I'm sharing an inventory with another user but we see different stats, why?", text: "In order to avoid confusion, after you share your items with other users, price updates are not shared automatically. This means that users can have different prices for the same items, which means that the stats also can show different spendings. Whenever you want your items to become identical to the items of another user, in order to see the same stats, go to the inventory participant list and tap on 'pull', next to the user."),

        HelpItem(title: "What does 'pull' mean in the participants list?", text: "In order to avoid confusion, after you share your items with other users, updates of the underlaying products are not shared automatically. This means that users can have e.g. different prices or categories for the same items. Whenever you want your products to become identical to the products of another user, go to the list/inventory participant list and tap on 'pull', next to the user. Note that in the case of list, the pull affects only the products currently in the list. In the case of inventory, since this is associated with the history and stats and thus has a much wider reach, all the products are upated."),
        
        HelpItem(title: "Can I use this app for online shopping?", text: "Yes, but as you have probably noticed it's not optimised for this - yet! This is already on the works and will be available in upcoming updates. Hold on!"),
        
        HelpItem(title: "What happens when my account is removed?", text: "Your data in the server is removed permanently. If you share list or inventories with other users these are not affected, except that you are removed as a participant. The data in your device is also not affected and you can continue using the app normally."),

        HelpItem(title: "Troubleshooting: I'm not receiving real time updates", text: "First of all, check if you're logged in! Real time updates don't work when you aren't logged in. If you are logged in, ensure that the real time connection is enabled in the settings. When the connections drops while you are logged in, the app tries to reestablish it automatically (you will see a label above the tab bar 'connecting to server...') in this case you only have to wait until the label disappears.", type: .Troubleshooting),
        
        HelpItem(title: "Troubleshooting: Sync doesn't work", text: "If you are getting repeatedly sync errors, as a last resort you can go to settings and select 'Overwrite local data'. This will reset the data on your device to the last data your successfully synced and likely fix the error. This is of course only a makeshift, such that you can use your account again, until the cause is fixed. This setting is only visible when are logged in and connected.", type: .Troubleshooting),
        
        HelpItem(title: "I cannot find the information I'm looking for", text: "Send a feedback email! Your questions will be answered and if necessary this help also updated.")

    ]
    
}

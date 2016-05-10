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
        
        let items: [HelpItem] = {
            switch LangHelper.currentAppLang() {
            case .EN: return HelpProviderImpl.helpItemsEN
            case .DE: return HelpProviderImpl.helpItemsDE
            case .ES: return HelpProviderImpl.helpItemsES
            }
        }()
        
        handler(ProviderResult(status: .Success, sucessResult: items))
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // EN
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // For now everything here and in memory, later maybe it makes sense to store these items in the prefill database?
    // (but this adds loading time at start, so maybe it's not bad in memory, also static var is lazy iirc)
    // TODO translations keys!
    private static var helpItemsEN = [
        
        HelpItem(title: "What is the back store?", text: "This is where your list items go after you 'buy' them. You can move the back store items back to the todo list by tapping on 'reset' or tapping on each of them individually. The back store can only be accessed when there are items in it, by swiping the prices view (in the todo list) to the left."),
        
        HelpItem(title: "What are groups? Is this the same as recipes?", text: "Groups are items that belong together, identified with a name and which can be added to a list or other places at once, using the top menu. You can use them for anything you want - they are most commonly used for recipes!"),

        // #new
        HelpItem(title: "I set the price of a list item but it's not updated in other lists.", text: "The prices of products, just like in real life, are store specific. Lists are bound to stores. Thus, when you set the price of an item this will affect only items from the same store of the list where you are in. When a list has no store, the update affects only items without a store."),

//        // #new (only for app without no server support)
//        HelpItem(title: "Can I upload my data to the cloud or share lists and inventories with other users?", text: "This functionality is currently available only in selected countries. If you are reading this, you're not in them ;). This is just a temporary limitation and will be hopefully removed soon for all countries."),
        
        HelpItem(title: "What is the relationship between categories and sections?", text: "Category is how you generally want to classify a product. E.g. for apples you probably would use 'fruits'. A section is the section in the store where you find the product. The section can be different than the category! For example thuna, could have 'fish' as category but be in the 'canned food' section.\nProducts have always a category, which is used everywhere in the app. Sections only exist in shopping lists."),

        // #new
        HelpItem(title: "What does color mean in the top menu for list/group/inventory items or products?.", text: "In the case of list items, this is the color of the section. In the other cases (group items, inventory items or products) this is the color of the category. This is the reason why the color button positioned on the same line as the section/category."),
        
        HelpItem(title: "Do I need an account?", text: "Unless you want to share your lists or inventories with other users or synchronise with other devices, you don't need an account. The functionality of the app with or without an account, besides of this, is identical."),

        HelpItem(title: "Can I use the app offline?", text: "Yes, you don't need to be logged in or have an account. If you have are logged in and go offline, the app will sync automatically when you're back online."),
        
        HelpItem(title: "How can I share lists or inventories with other people?", text: "To share lists or inventories, go to the view where the lists or inventories are listed, tap on the edit button, tap on the list or inventory you want to share and then on 'participants'. Here you can add or remove participants. Participants with pending invitations have a question mark next to them. When you are not logged in or connected the participants button is not visible."),

//        HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
        
        HelpItem(title: "Can I edit items globally? What are products?", text: "Products are the 'common unit' of all the items you manage in the app. If you want to edit the name of an item and want this to be done also in list, group, inventory and history items, you just have to edit it once in the 'manage products' screen. Also, if you want to remove a product, because e.g. you don't want to see it in the top-menu items anymore, do it in this screen."),
        
        HelpItem(title: "How do I remove products from the top menu? I never use them!", text: "You can remove them in 'Manage products' (in the ... tab)."),
        
        HelpItem(title: "I bought items with incorrect prices, how do I correct this?", text: "In order to keep your reports reliable, the history is a 'snapshot' of what you bought and not meant to be edited. Not everything is lost though: You can delete history items and buy the list items again with the corrected price."),
//      
        HelpItem(title: "What happens when I remove products in the manage products screen?", text: "The product and all list/group/inventory, history and top-menu items associated with it will be removed. For example, if you remove 'Apples' with brand 'x', all the list, inventory, group and history and top-menu items that are named 'Apples' and have the brand 'x' Will be removed. Don't worry about products with no brand - an empty brand is handled like a brand and will only remove items with the same name that have also an empty brand."),
        
        HelpItem(title: "What happens when I remove history items?", text: "Removal of history items affects also the stats! If you, for example, remove 5x lemon cakes, bought on March the 3d, that costed 10, your stats for March will show 10 less spendings."),
        
//        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),

        HelpItem(title: "What is the 'real time connection' setting?", text: "The real time connection allows you to receive updates from another devices or users right after they are done. With the setting you can disable this. If you disable it, this will be remembered and not enabled until you enable it again. This setting is only visible when you have are logged in and connected."),
        
        HelpItem(title: "How do I read the report?", text: "The bars chart shows your monthly spedings since you started using the app back to 1 year. 'Monthly average' is the average of your spendings for the months where you have used the app. 'Daily average this month' is the daily avarage of what you've spent so far in the current month. 'Projected spendings this month' is an estimation of what you will spend in total in the current month based on what you have spent so far in this month. For example if today it's the 10th and you've spent 300 so far in this month, the projected spendings would be around 900. Tapping on a bar shows you a detail view of its month. The pie chart shows the top categories for which you have spent the most and below you see an aggregate of all the bought products in this month."),
        
        HelpItem(title: "I'm sharing an inventory with another user but we see different stats, why?", text: "In order to avoid confusion, after you share your items with other users, price updates are not shared automatically. This means that users can have different prices for the same items, which means that the stats also can show different spendings. Whenever you want your items to become identical to the items of another user, in order to see the same stats, go to the inventory participant list and tap on 'pull', next to the user."),

        HelpItem(title: "What does 'pull' mean in the participants list?", text: "In order to avoid confusion, after you share your items with other users, updates of the underlaying products are not shared automatically. This means that users can have e.g. different prices or categories for the same items. Whenever you want your products to become identical to the products of another user, go to the list/inventory participant list and tap on 'pull', next to the user. Note that in the case of list, the pull affects only the products currently in the list. In the case of inventory, since this is associated with the history and stats and thus has a much wider reach, all the products are upated."),
        
        HelpItem(title: "Can I use this app for online shopping?", text: "Yes, but as you have probably noticed it's not optimised for this - yet! This is already on the works and will be available in upcoming updates. Hold on!"),
        
        HelpItem(title: "What happens when my account is removed?", text: "Your data in the server is removed permanently. If you share list or inventories with other users these are not affected, except that you are removed as a participant. The data in your device is also not affected and you can continue using the app normally."),

        HelpItem(title: "Troubleshooting: I'm not receiving real time updates", text: "First of all, check if you're logged in! Real time updates don't work when you aren't logged in. If you are logged in, ensure that the real time connection is enabled in the settings. When the connections drops while you are logged in, the app tries to reestablish it automatically (you will see a label above the tab bar 'connecting to server...') in this case you only have to wait until the label disappears.", type: .Troubleshooting),
        
        HelpItem(title: "Troubleshooting: Sync doesn't work", text: "If you are getting repeatedly sync errors, as a last resort you can go to settings and select 'Overwrite local data'. This will reset the data on your device to the last data your successfully synced and likely fix the error. This is of course only a makeshift, such that you can use your account again, until the cause is fixed. This setting is only visible when are logged in and connected.", type: .Troubleshooting),
        
        HelpItem(title: "I cannot find the information I'm looking for", text: "Send a feedback email! Your questions will be answered and if necessary this help also updated.")

    ]
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // DE
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static var helpItemsDE = [
        
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
        HelpItem(title: "What happens when I remove products in the manage products screen?", text: "The product and all list/group/inventory, history and top-menu items associated with it will be removed. For example, if you remove 'Apples' with brand 'x', all the list, inventory, group and history and top-menu items that are named 'Apples' and have the brand 'x' Will be removed. Don't worry about products with no brand - an empty brand is handled like a brand and will only remove items with the same name that have also an empty brand."),
        
        HelpItem(title: "What happens when I remove history items?", text: "Removal of history items affects also the stats! If you, for example, remove 5x lemon cakes, bought on March the 3d, that costed 10, your stats for March will show 10 less spendings."),
        
        //        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),
        
        HelpItem(title: "What is the 'real time connection' setting?", text: "The real time connection allows you to receive updates from another devices or users right after they are done. With the setting you can disable this. If you disable it, this will be remembered and not enabled until you enable it again. This setting is only visible when you have are logged in and connected."),
        
        HelpItem(title: "How do I read the report?", text: "The bars chart shows your monthly spedings since you started using the app back to 1 year. 'Monthly average' is the average of your spendings for the months where you have used the app. 'Daily average this month' is the daily avarage of what you've spent so far in the current month. 'Projected spendings this month' is an estimation of what you will spend in total in the current month based on what you have spent so far in this month. For example if today it's the 10th and you've spent 300 so far in this month, the projected spendings would be around 900. Tapping on a bar shows you a detail view of its month. The pie chart shows the top categories for which you have spent the most and below you see an aggregate of all the bought products in this month."),
        
        HelpItem(title: "I'm sharing an inventory with another user but we see different stats, why?", text: "In order to avoid confusion, after you share your items with other users, price updates are not shared automatically. This means that users can have different prices for the same items, which means that the stats also can show different spendings. Whenever you want your items to become identical to the items of another user, in order to see the same stats, go to the inventory participant list and tap on 'pull', next to the user."),
        
        HelpItem(title: "What does 'pull' mean in the participants list?", text: "In order to avoid confusion, after you share your items with other users, updates of the underlaying products are not shared automatically. This means that users can have e.g. different prices or categories for the same items. Whenever you want your products to become identical to the products of another user, go to the list/inventory participant list and tap on 'pull', next to the user. Note that in the case of list, the pull affects only the products currently in the list. In the case of inventory, since this is associated with the history and stats and thus has a much wider reach, all the products are upated."),
        
        HelpItem(title: "Can I use this app for online shopping?", text: "Yes, but as you have probably noticed it's not optimised for this - yet! This is already on the works and will be available in upcoming updates. Hold on!"),
        
        HelpItem(title: "What happens when my account is removed?", text: "Your data in the server is removed permanently. If you share list or inventories with other users these are not affected, except that you are removed as a participant. The data in your device is also not affected and you can continue using the app normally."),
        
        HelpItem(title: "Troubleshooting: I'm not receiving real time updates", text: "First of all, check if you're logged in! Real time updates don't work when you aren't logged in. If you are logged in, ensure that the real time connection is enabled in the settings. When the connections drops while you are logged in, the app tries to reestablish it automatically (you will see a label above the tab bar 'connecting to server...') in this case you only have to wait until the label disappears.", type: .Troubleshooting),
        
        HelpItem(title: "Troubleshooting: Sync doesn't work", text: "If you are getting repeatedly sync errors, as a last resort you can go to settings and select 'Overwrite local data'. This will reset the data on your device to the last data your successfully synced and likely fix the error. This is of course only a makeshift, such that you can use your account again, until the cause is fixed. This setting is only visible when are logged in and connected.", type: .Troubleshooting),
        
        HelpItem(title: "I cannot find the information I'm looking for", text: "Send a feedback email! Your questions will be answered and if necessary this help also updated.")
        
    ]
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ES
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static var helpItemsES = [
        HelpItem(title: "Qué es el depósito?", text: "Es el sitio a donde van tus items despues de que los 'compras'. Los items en el depósito se pueden mover de regreso a la lista todo usando 'retornar' o selectionando cada item individualmente. Para acceder el depósito arrastra la vista en donde aparece la cantidad de items en el depósito, en la parte baja de la lista todo, hacia la izquierda y selecciona la vista que aparece atrás."),
        
        HelpItem(title: "Qué son grupos? Son lo mismo que recetas?", text: "Grupos son items que guardas juntos y puedes agregar después a listas u otros sitios de una sola vez - su uso más común son recetas!"),
        
        HelpItem(title: "Cuál es la diferencia enre categorías y secciones?", text: "Categoría es como clasificas un producto. Por ejemplo para manzanas probablemente usarías 'frutas'. Una sección es la parte del almacén donde encuentras el producto. La sección no siempre es lo mismo que la categoría! Por ejemplo atúm, podría tener 'pez' como categoría pero estar en la sección 'enlatados'.\nProductos siempre tienen una categoría (en listas, grupos, inventarios, etc.) mientras que la sección sólo es utilizada en las listas."),
        
        HelpItem(title: "Necesito una cuenta de usuario?", text: "A menos que quieras compartir tus listas o inventarios con otros usuarios o syncronizar con otros aparatos, no necesitas una cuenta. Para todo lo demas, la app es identica con o sin cuenta."),
        
        HelpItem(title: "Puedo utilizar la app cuando no estoy online?", text: "Sí, una conexión internet o cuenta de usuario no es necesaria. Si estás online y te desconectas, la app se syncronizará automáticamente cuando te conectes de nuevo."),
        
        HelpItem(title: "Cómo comparto listas o inventarious con otras personas?", text: "Para compartir listas o inventarios, ve a la vista donde las listas o inventarios están enlistados, ###toca el botón para editar, ###toca la list o inventario que quieres compartir y después en 'participantes'. Aquí puedes agregar o remover participantes. Participants con invitaciones pendientes tienen un signo de interrogación. Cuando no tienes una conexión a internet o cuenta de usuario activa, el botón de participantes no es visible."),
        
        //        HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
        
        HelpItem(title: "Puedo editar items globalmente? Qué son productos?", text: "Productos are la 'Unidad común' de todos los items. Si quieres editar el nombre de un item de modo que también se editen todos los items con este nomber en las listas, grupos, inventarions, el menú de adición rápida, historia y estadísticas, sólo tienes que editarlo en la vista 'administrar productos'. De igual manera, si quieres remover un producto, de modo que desaparezca en todas partes sólo tienes que removerlo en 'administrar productos'."),
        
        HelpItem(title: "Cómo puedo remover productos del menú de adición rápida? Nunca los uso¡", text: "Puedes removerlos en la vista 'Administrar products' la cual encuentras en el ... tab."),
        
        HelpItem(title: "Cuando cambio el precio de un item, afecta esto la historia o las estadísticas?", text: "No, los precious en la historia y estadísticas son 'congelados' en el moment en que los compras y no son afectados. Si compraste un item con un precio incorrect no todo está perdido: Puedes correjir el precio en la lista, remover el item de la historia y agregarlo otra vez."),
        //
        HelpItem(title: "Qué pasa cuando removo productos en la vista 'Administrar productos'?", text: "El producto y todos los items en listas/grupos/inventarios/menú de adición rápida/historia y estadísticas que tienen el mismo nombre y marca que el producto son removidos. No te preopupes por product sin marca - la ausencia the marca es considerada igual que una marca y solo se removerán productos con el mismo nomber que no también carecen de marca."),
        
        HelpItem(title: "Qué pasa cuando removo entradas en la historia?", text: "Cuando remueves entradas de la historia las estadísticas también son afectadas, si por ejemplo remueves 5 tartas de limón que compraste el 3 de Marzo y costaron 10, tu estadística te mostrará una reducción en los gastos de Marzo por 10."),
        
        //        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),
        
        HelpItem(title: "Qué es la opción 'conección en tiempo real'?", text: "La conexión en tiempo real te permite recibir actualizaciones de otros aparatos/usuarios inmediatamente.  Con esta opción puedes deactivarla. Si la desactivas, no se volverá a activar automaticamente hasta que la actives de nuevo. Esta opción es sólo visible cuando tienes una conexión y cuenta de usuario activa."),
        
        HelpItem(title: "Cómo interpreto el reporte?", text: "La estadística de barras the muestra los gastos mensuales desde que empezaste a utilizar la app, hasta 1 año en el pasado. 'Promedio mensual' es el promedio de los gastos durante los meses que has usado la app. 'Promedio diario en este mes' es el promedio diario de lo que has gastado durante el mes actual. 'Gastos estimados para este mes'  es una estimación de lo que habrás gastado al final del mes actual (sólo para este mes). Por ejemplo si hoy es el día 10 del mes y has gastado hasta ahora 300 durante este mes, los gastos estimados para este mes serán aproximadamente 900. Pulsar en las barras te lleva a la vista de gastos para el mes correspondiente. El gráfico de torta muestra las categorías por las que más has gastado y abajo hay una lista de agreagados de los productos que compraste durante el mes."),
        
        HelpItem(title: "Estoy compartiendo my inventario con otros usuarios y vemos diferentes estadísticas, por qué??", text: "Para evitar confusión, cuando compartes items con otros usuarios, actualizaciones a sus precios are not compartidos automáticamente. Por esta razón es posible que usuarios tengan diferentes precios para los mismos items, lo que significa que la estadística puede mostrar diferentes gastos. Cuando quieras que tus items sean idénticos a los de otro(a) usuario(a), ve a la lista de participantes de de lista o inventario y selecciona 'descargar', próximo al(a) usuario(a)."),
        
        HelpItem(title: "Qué significa 'descargar' en la lista de participantes?", text: "Para evitar confusión, cuando compartes items con otros usuarios, actualizaciones a sus productos no son not compartidos automáticamente. Esto significa que diferentes usuarios pueden tener por ejemplo diferentes precios o categorías para los mismos productos.  Cuando quieras que productos sean idénticos a los de otro(a) usuario(a), ve a la lista de participantes de de lista o inventario y selecciona 'descargar', próximo al(a) usuario(a). Nota que en caso de la lista, la descarga afecta solo los productos que estan en la lista, mientras que en el inventario, debido a que este está asociado con la historia y las estadísticas, afecta a todos los productos."),
        
        HelpItem(title: "Puedo utilizar esta app para comprar en línea?", text: "Sí. El uso para este fin por el momento no es óptimo pero se encuentra en desarrollo y mejorará gradualmente en próximos updates."),
        
        HelpItem(title: "Qué pasa cuando mi cuenta es borrada?", text: "Tus datos son borrados permanentemente. Si compartes una listas o inventarios con otras personas, estos no serán afectados, excepto que tú eres removido(a) como participante. Los datos en tu device no son afectados y puedes continuar usando la app normalmente."),
        
        HelpItem(title: "Problemas: No estoy recibiendo updates en tiempo real", text: "Primero que todo, revisa que tanto conexión internet esté activa y como conectado(a) con tu cuenta de usuario en Groma. Updates en tiempo real no funcionan si no estás conectado(a). Si lo estás, asegura que la conexión de tiempo real está activa en las preferencias. Cuando la conexión a internet se pierde mientras estás conectado(a) la app intenta reestablecerla automáticamente. Es este caso ves un un label arriba de los tabs en la parte baja, que dice 'conectando al servidor...' En este caso sólo tienes que esperar hasta que este label desaparezca, lo que significa que la conexión fué reestablecida.", type: .Troubleshooting),
        
        HelpItem(title: "Problemas: La sincronización no funciona", text: "Si estás recibiendo constantemente errores de sincronización, un último recurso es sobreescribir los datos en tu device con los datos del servidor, lo cual puede solucionar estos problemas. Para hacer esto, ve a las preferencias, y selecciona 'Sobreescribir datos locales'", type: .Troubleshooting),
        
        HelpItem(title: "No encuentro la información que estoy buscando", text: "Envíame un feedback email¡ Respondeé a tus preguntas y si es necesario esta información también será actualizada para futuras versiones.")
    ]

}

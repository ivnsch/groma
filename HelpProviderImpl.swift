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
        
        //        // #new
        //        HelpItem(title: "How are the Lists, Cart, Inventory and History related?", text: "Shopping Lists are where you keep Lists of items you want to buy, when you marked them as bought in the Cart they go to the Inventory. The Inventory defaults to ‘Home’, but you can add other locations if you need. The best way to use Lists is to name each for the store where you will use it (this means that when you add prices it will be the right price for that store). When you mark an item as purchased the app also automatically adds it to your History.
        
        HelpItem(title: "What is the relationship between categories and sections?", text: "Category is how you generally want to classify a product. E.g. for apples you probably would use 'fruit'. A Section is the area of the store where you find the product. The section can be different than the category! For example tuna, could have 'fish' as category but be in the 'canned food' section.\nProducts have always a category, which is used everywhere in the app. Sections only exist in Shopping Lists."),
        
        
        HelpItem(title: "What are groups? Are they the same as recipes?", text: "Groups are a handy way of adding multiple items to a List at once. For example make a hamburger group with beef, buns, cheese and pickles, and add all the items to the List with only one click of a button – perfect for recipes you use often"),
        
        HelpItem(title: "What is the back store?", text: "This is where your List items go after you 'buy' them. You can move the back store items back to the to do List by tapping on 'reset' or tapping on each of them individually. The back store can only be accessed when there are items in it, by swiping the prices view (in the to do List) to the left."),
        
        //        // #new
        //        HelpItem(title: "I set the price of a List item but it's not updated in other Lists.", text: "The prices of products, just like in real life, are store specific. That’s why Lists are linked to specific stores. When you set the price of an item this will affect only items from the same store of the List where you are in. When a List has no store, the update affects only items without a store."),
        
        //        // #new (only for app without no server support)
        //        HelpItem(title: "Can I upload my data to the cloud or share Lists and inventories with other users?", text: "This functionality is currently available only in selected countries. If you are reading this, we haven’t got to you yet ;). "),
        
        //        // #new
        //        HelpItem(title: "What does color mean in the top menu for List/Group/Inventory items or products?.", text: "In the case of List items, this is the color of the section. In the other cases (Group items, Inventory items or Products) this is the color of the category. "),
        
        
        HelpItem(title: "Can I edit items globally? What are products?", text: "Products are the 'common unit' of all the items you manage in the app. If you want to edit the name of an item and want this to be done also in list, group, inventory and history items, you just have to edit it once in the products screen. Also, if you want to remove a product, because e.g. you don't want to see it in the top-menu items anymore, do it in this screen."),
        
        HelpItem(title: "How do I remove Products from the top menu? I never use them!", text: "You can remove them in the Products screen (in the ... tab)."),
        
        HelpItem(title: "I bought items with incorrect prices, how do I fix it?", text: "The History is a snapshot of what you bought and isn’t editable, you can delete History items and buy the List items again with the corrected price though."),
        
        HelpItem(title: "What happens when I remove products in the products screen?", text: "The product and all List/Group/Inventory/History and top-menu items associated with it will be removed."),
        
        HelpItem(title: "What happens when I remove items in my History?", text: "This will also affects your stats."),
        
        HelpItem(title: "How do I make sense of the report?", text: "The bar chart shows your monthly spend for the last 12 months. 'Projected spend this month' is an estimation of what you will spend in total in the current month based on what you have spent so far in this month. For example if today is July 10th and you've spent $300 so far in this month, the projected spend for July would be around $900. Tapping on a bar shows you a detailed view of its month. The pie chart shows the top categories and below you see an aggregate of all the purchased products."),
        
        HelpItem(title: "Can I use this app for online shopping?", text: "Yes, but as you have probably noticed it's not optimized for this - yet! This is already on the works and will be available in upcoming updates. Hold on!"),
        
        
        HelpItem(title: "Can I change the store that a List is linked to?", text: "No, once the List is submitted, the store can't be changed. If you need to do this you have to delete the List and create a new one with the new store. (We’re working on this for future versions)"),
        
        HelpItem(title: "I cannot find the information I'm looking for", text: "Send a feedback email! I’m super happy to answer your questions."),
        
        
//        HelpItem(title: "Do I need an account?", text: "Nope, unless that is you’d like to share your Lists or Inventories with other users or other devices."),
//        
//        HelpItem(title: "Can I use the app offline?", text: "Yes! If you have are logged in and go offline, the app will sync automatically when you're back online."),
//        
//        HelpItem(title: "How can I share Lists or Inventories with other people?", text: "Go to the view where the Lists or Inventories are shown, tap on the edit button, then tap on the List or Inventory you want to share and then on 'participants'. Here you can add or remove participants. NB: When you are not logged in or connected the participants button is not visible."),
//        
//        HelpItem(title: "What is the 'real time connection' setting?", text: "The real time connection allows you to receive updates from another device or user right after they are done. With the setting you can disable this. If you disable it, this will be remembered and not enabled until you enable it again. This setting is only visible when you have are logged in and connected."),
//        
//        HelpItem(title: "I'm sharing an Inventory with another user but we see different stats, why?", text: "After you share your items with other users, price updates are not shared automatically. Whenever you want your items to become identical to the items of another user, go to the Inventory participant List and tap on 'pull', next to the user."),
//        
//        HelpItem(title: "What does 'pull' mean in the participants List?", text: "See above! NB: For a List, the pull affects only the products currently in the List. In the case of Inventory, since this is associated with the history and stats and thus has a much wider reach, all the products are updated."),
//        
//        HelpItem(title: "What happens when my account is removed?", text: "Your data in the server is removed permanently. If you share Lists or Inventories with other users these are not affected, except that you are removed as a participant. The data in your device is also not affected and you can continue using the app normally."),
//        
//        // #new
//        HelpItem(title: "What are the participant permissions?", text: "To keep things simple, all participants are equal. The moment you share something with someone, this user gets full rights to the shared item. This person can also share the item with other users. The reach of a participant is limited only to the items in the List or Inventory being shared. They can't, for example, modify your underlaying products, e.g. change the prices.\nWhen you share a List with someone and want this person to also be able to buy items - that is, to move them to the Inventory associated with the List, don't forget to share also this Inventory with them, otherwise 'Buy' will not work. The reason of this separation is that you don't necessarily want to share always the Lists with the same persons as the inventories, for example you may want to task someone to buy a List but don't give them access to your household. After the participant puts the items in the cart, you can 'Buy' them."),
//        
//        HelpItem(title: "Troubleshooting: I'm not receiving real time updates", text: "Are you logged in? If you are, check that the real time connection is enabled in Settings.", type: .Troubleshooting),
//        
//        HelpItem(title: "Troubleshooting: Sync doesn't work or I get invalid request errors", text: "Shut the app and open it again… If nothing else works you go to settings and select 'Overwrite local data'. This will reset the data on your device to the last data your successfully synced. NB: This setting is only visible when you are logged in and connected.", type: .Troubleshooting),
//        
//        HelpItem(title: "Can I edit items globally? What are products?", text: "Products are the 'common unit' of all the items you manage in the app. If you want to edit the name of an item and want this to be done also in list, group, inventory and history items, you just have to edit it once in the products screen. Also, if you want to remove a product, because e.g. you don't want to see it in the top-menu items anymore, do it in this screen."),
    ]
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // DE
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static var helpItemsDE = [
        
        HelpItem(title: "Was ist der Unterschied zwischen Abteilungen und Kategorien?", text: "Kategorien ist wie du generell etwas einordnen willst. Die Abteilung ist der Ort im Laden, wo sich das Produkt befindet. Z.B. für Thunfisch könnte die Kategorie 'Fisch' lauten, und die Abteilung 'Dosenprodukte'."),

        HelpItem(title: "Was ist die Abstellkammer?", text: "Hier ist wo die Listen-Einträge kommen nachdem du sie 'kaufst'. Du kannst die Einträge zwischen der Abstellkammer und die Todo-Liste bewegen, indem 'Zurücksetzen', oder jeden einzelnen Eintrag antippst. Die Abstellkammer ist nur zugänglich wenn sich Einträge drin befinden. Um sie zu öffnen  musst du, auf der Ansicht wo sich der Preis befindet, auf der Todo-Liste, mit dem Finger nach Links streichen, und dann die dahinterliegende Fläche antippen."),
        
        HelpItem(title: "Was sind Gruppen? Etwa Rezepte?", text: "Gruppen erleichtern das Hinzufügen zusammenhängender Einträge. Du kannst damit z.B. Rezepte speichern, die sich danach auf einmal in Listen, Inventare oder sogar andere Gruppen einfügen lassen."),
        
        HelpItem(title: "Kann ich Einträge global editieren? Was sind Produkte?", text: "Produkte sind die zugrundeliegende Einheit aller Einträge in dieser App. Um global Eigenschaften zu editieren, also so dass es auch in den Listen, Gruppen, Inventare, Verlauf und Statistiken gemacht wird, musst du es nur einmal in der 'Produktverwaltung' Ansicht machen. Ebenso, wenn du Produkte global löschen willst, musst du es nur einmal in dieser Ansicht machen."),
        
        HelpItem(title: "Wie kann ich Produktvorschläge vom Top-Menü löschen? Ich benutze sie nie!", text: "Du kannst sie in der Ansicht 'Produktverwaltung' (im ... Tab) löschen."),
        
//        HelpItem(title: "Wird der Bericht geändert wenn ich Preise editiere?", text: "Nein, die Preise werden natürlich 'eingefroren' im Moment wo du sie kaufst. Sollte es allerdings dazu kommen, dass du Preise für bereits gekaufte Produkte korrigieren möchtest, kannst du die jeweiligen Einträge aus dem Verlauf löschen, und sie nochmal mit den korrigierten Preisen kaufen."),
        // x
//        HelpItem(title: "Was passiert wenn ich Produkte lösche?", text: "Das Produkt und alle damit verbundene Listen/Gruppen/Inventar Einträge werden gelöscht. Z.B. Wenn du 'Äpfel' mit der Marke 'X' löscht, alle Listen/Gruppen/Inventar Einträge mit dem Namen \"Äpfel\" und die Marke \"X\" werden auch gelöscht."),
        
        // x
        HelpItem(title: "Was passiert wenn ich Verlaufseinträge lösche?", text: "Die entsprechenden Einträge verschwinden auch aus dem Bericht. Wenn du deinen Bericht nicht ändern willst, solltest du den Verlauf auch nicht ändern!"),
        
        //        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),
        
        HelpItem(title: "Wie ist der Bericht zu verstehen?", text: "Das Säulendiagramm zeigt dir deine monatlichen Ausgaben seitdem du angefangen hast, die App zu benutzen. 'Monatlicher Durchschnitt' ist der Durchschnitt von deinen Ausgaben in den Monaten wo du die App benutzt hast. 'Monatstagesdurchschnitt' ist der täglicher Durchschnitt von dem was du in diesem Monat ausgegeben hast. 'Gesch. Gesamtausgaben akt. Monat' ist die Schätzung von dem, was du in diesem Monat ausgeben wirst, anhand dessen was du bislang in diesem Monat ausgegeben hast. Wenn du eine Säule antippst kommst du zur Detail-Ansicht für das jeweilige Monat. Da findest du ein Tortendiagramm mit den Kategorien wofür du am meisten ausgegeben hast und darunter ein Aggregat von den gekauften Produkten."),
        
        
        HelpItem(title: "Kann ich diese App auch für Onlineshopping benutzen?", text: "Ja. Sie ist noch nicht ganz darauf optimiert aber einige Verbesserung werden bereits entwickelt und werden in kommente Updates verfügbar sein."),
        
        HelpItem(title: "Kann ich den Laden von einer Liste ändern?", text: "Nein, nachdem die Liste gespeichert wurde, kann der Laden nicht mehr geändert werden. Falls du dies brauchst, musst du die alte Liste löschen und eine neue mit dem neuen Laden erstellen. Dies hat technische Gründe und kann in zukünftige Versionen geändert werden."),
        
        HelpItem(title: "Ich kann nicht die Information finden, wonach ich suche", text: "Sende uns eine Feedback Email! Wir beantworten gerne deine Fragen."),

        
//        HelpItem(title: "Brauche ich einen Benutzerkonto?", text: "Wenn du listen oder Inventare mit anderen nicht teilen willst, oder mit anderen Geräten synchronisieren willst, ist ein Benutzerkonto unnötig. Die Funktionalität von dieser App mit und ohne Benutzerkonto, außer diesen Eigenschaften ist gleich."),
//        
//        HelpItem(title: "Kann ich die App offline benutzen?", text: "Ja, du musst nicht einen Benutzerkonto haben. Wenn du eingeloggt bist und offline gehst, wird sich die App automatisch synchronisieren sobald du zurück online bist."),
//        
//        HelpItem(title: "Wie kann ich Listen oder Inventare mit anderen Personen teilen?", text: "Um Listen oder Inventare zu teilen, geh zu der Ansicht wo die Listen oder Inventare aufgelistet sind, dann Editieren, dann selektiere die Liste oder Inventar die du teilen willst und dann auf 'Teilnehmer'. Hier kannst du die Teilnehmer der Liste sehen und neue einladen. Teilnehmer die ihre Einladung noch nicht akzeptiert haben erscheinen mit einem Fragezeichnen. Wenn du nicht eingeloggt bist, ist der Teilnehmer Button nicht sichtbar."),
//        
//                HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
//
//        
//        HelpItem(title: "Warum gibt es eine Echtzeiverbindung Einstellung?", text: "Die Echtzeitverbindung erlaubt dir in Echtzeit die Aktivität anderer Benutzer, oder auch deiner anderen Geräte mitzubekommen. Mit dieser Einstellung, solltest du aus irgendeinem Grund es wollen, kannst du die Echtzeitverbing dauerhaft deaktivieren."),
//
//        HelpItem(title: "Ich teile ein Inventar mit einem anderen Benutzer aber unsere Berichte sind anders, warum?", text: "Um Verwirrung zu vermeiden, wenn ein Benutzer Preise von geteilten Produkten ändert, werden diese Änderungen nicht automatisch auf andere Benutzer übertragen. Folglich können benutzer unterschiedliche Preise für dieselbe Inventar Einträge haben, was auch bedeutet dass die Berichte anders ausfallen. Wenn du willst dass deine Produkte gänzlich mit den Produkten von einem anderen Teilnehmer übereinstimmen, gehe zu der Teilnehmerliste vom Inventar, und tippe 'ziehen' an neben dem Benutzer."),
//        
//        HelpItem(title: "Was bedeutet 'ziehen' in der Teilnehmer liste?", text: "Um Verwirrung zu vermeiden, wenn ein Benutzer Preise von geteilten Produkten ändert, werden diese Änderungen nicht automatisch auf andere Benutzer übertragen.  Wenn du willst dass deine Produkte gänzlich mit den Produkten von einem anderen Teilnehmer übereinstimmen, gehe zu der Teilnehmerliste vom Inventar, und tippe 'ziehen' an neben dem Benutzer. Im Fall von Listen, betrifft das Ziehen nur die Produkte die sich derzeit in der Liste befinden. Im Fall vom Inventar, betrifft es alle Produkte, da das Inventar auch mit dem Verlauf verknüpft ist und somit ein umfassenderes Umfang hat."),
//
//        HelpItem(title: "Was passiert wenn mein Benutzerkonto gelöscht wird?", text: "Deine Daten werden permanent gelöscht. Wenn du Listen oder Inventare geteilt hast, wird für die andere Betnutzer alles gleich bleiben, außer dass du als Teilnehmer verschwindest. Die daten auf deinem Gerät bleiben auch erhalten und du kannst die App normal weiter benutzen."),
//        
//        HelpItem(title: "Fehlerbehandlung: Ich bekomme keine Echtzeit Updates", text: "Zuerst überprüfe on du eingeloggt bist. Als nächstes stelle sicher dass die Echtzeitverbindung, in den Einstellungen, aktiviert ist. Wenn die Verbindung mit dem Server verloren geht während du eingeloggt bist, wird die App versuchen die automatisch wieder herzustellen (du wirst ein TODO***Schildchen**** unten sehen mit 'Verbinde mit Server...' In diesem Fall musst du nur warten bis dass das TODO***Schildchen*** verschwindet.", type: .Troubleshooting),
//        
//        HelpItem(title: "Fehlerbehandlung: Die synchronisierung funktioniert nicht", text: "Wenn du wiederholend synchronisierungsfehler bekommst, als Notlösung, kannst du in den Einstellungen 'Lokale Daten überschreiben' wählen. Hiermit werden deine lokale Daten mit den Daten überschrieben, die du das letzte Mal erfolgreich synchronisiert hast, und somit mögliche Ursachen vom Synchronisierungsfehler beseitigt. Diese Einstellung ist natürlich nur sichtbar wenn du eingeloggt bist und eine aktive Internetverbindung hast.", type: .Troubleshooting),
    ]
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ES
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static var helpItemsES = [
        
        HelpItem(title: "Cuál es la diferencia enre categorías y secciones?", text: "Categoría es como clasificas un producto. Por ejemplo para manzanas probablemente usarías 'frutas'. Una sección es la parte del almacén donde encuentras el producto. La sección no siempre es lo mismo que la categoría! Por ejemplo atúm, podría tener 'pez' como categoría pero estar en la sección 'enlatados'.\nProductos siempre tienen una categoría (en listas, grupos, inventarios, etc.) mientras que la sección sólo es utilizada en las listas."),
        
        HelpItem(title: "Qué es el depósito?", text: "Es el sitio a donde van tus items despues de que los 'compras'. Los items en el depósito se pueden mover de regreso a la lista todo usando 'retornar' o selectionando cada item individualmente. Para acceder el depósito arrastra la vista en donde aparece la cantidad de items en el depósito, en la parte baja de la lista todo, hacia la izquierda y selecciona la vista que aparece atrás."),
        
        HelpItem(title: "Qué son grupos? Son lo mismo que recetas?", text: "Grupos son items que guardas juntos y puedes agregar después a listas u otros sitios de una sola vez - su uso más común son recetas!"),
        
        HelpItem(title: "Puedo editar items globalmente? Qué son productos?", text: "Productos are la 'Unidad común' de todos los items. Si quieres editar el nombre de un item de modo que también se editen todos los items con este nomber en las listas, grupos, inventarions, el menú de adición rápida, historia y estadísticas, sólo tienes que editarlo en la vista 'administrar productos'. De igual manera, si quieres remover un producto, de modo que desaparezca en todas partes sólo tienes que removerlo en 'administrar productos'."),
        
        HelpItem(title: "Cómo puedo remover productos del menú de adición rápida? Nunca los uso!", text: "Puedes removerlos en la vista 'Administrar products' la cual encuentras en el ... tab."),
        
        HelpItem(title: "Cuando cambio el precio de un item, afecta esto la historia o las estadísticas?", text: "No, los precious en la historia y estadísticas son 'congelados' en el moment en que los compras y no son afectados. Si compraste un item con un precio incorrect no todo está perdido: Puedes correjir el precio en la lista, remover el item de la historia y agregarlo otra vez."),
        //
        HelpItem(title: "Qué pasa cuando remuevo productos en la vista 'Administrar productos'?", text: "El producto y todos los items en listas/grupos/inventarios/menú de adición rápida/historia y estadísticas que tienen el mismo nombre y marca que el producto son removidos. No te preopupes por product sin marca - la ausencia the marca es considerada igual que una marca y solo se removerán productos con el mismo nomber que no también carecen de marca."),
        
        HelpItem(title: "Qué pasa cuando remouevo entradas en la historia?", text: "Cuando remueves entradas de la historia las estadísticas también son afectadas, si por ejemplo remueves 5 tartas de limón que compraste el 3 de Marzo y costaron 10, tu estadística te mostrará una reducción en los gastos de Marzo por 10."),
        
        //        HelpItem(title: "How can I use custom quantity units, e.g. pounds?", text: ""),
        
        HelpItem(title: "Cómo interpreto el reporte?", text: "La estadística de barras the muestra los gastos mensuales desde que empezaste a utilizar la app, hasta 1 año en el pasado. 'Promedio mensual' es el promedio de los gastos durante los meses que has usado la app. 'Promedio diario en este mes' es el promedio diario de lo que has gastado durante el mes actual. 'Gastos estimados para este mes'  es una estimación de lo que habrás gastado al final del mes actual (sólo para este mes). Por ejemplo si hoy es el día 10 del mes y has gastado hasta ahora 300 durante este mes, los gastos estimados para este mes serán aproximadamente 900. Pulsar en las barras te lleva a la vista de gastos para el mes correspondiente. El gráfico de torta muestra las categorías por las que más has gastado y abajo hay una lista de agreagados de los productos que compraste durante el mes."),
        
        HelpItem(title: "Puedo utilizar esta app para comprar en línea?", text: "Sí. El uso para este fin por el momento no es óptimo pero se encuentra en desarrollo y mejorará gradualmente en próximos updates."),
        
        HelpItem(title: "Puedo cambiar el almancén de una lista?", text: "No, después que guardas la lista, el almacén no se puede cambiar. Si necesitas cambiarlo tienes que borrar la lista y crear una nueva con el nuevo almancén. Esto tiene razones técnicas y puede cambiar en futuras versiones."),

        HelpItem(title: "No encuentro la información que estoy buscando", text: "Envíanos un feedback email¡ Responderemos cordialmente tus preguntas."),
        
//        HelpItem(title: "Necesito una cuenta de usuario?", text: "A menos que quieras compartir tus listas o inventarios con otros usuarios o syncronizar con otros aparatos, no necesitas una cuenta. Para todo lo demas, la app es identica con o sin cuenta."),
//        
//        HelpItem(title: "Puedo utilizar la app cuando no estoy online?", text: "Sí, una conexión internet o cuenta de usuario no es necesaria. Si estás online y te desconectas, la app se syncronizará automáticamente cuando te conectes de nuevo."),
//        
//        HelpItem(title: "Cómo comparto listas o inventarious con otras personas?", text: "Para compartir listas o inventarios, ve a la vista donde las listas o inventarios están enlistados, ###toca el botón para editar, ###toca la list o inventario que quieres compartir y después en 'participantes'. Aquí puedes agregar o remover participantes. Participants con invitaciones pendientes tienen un signo de interrogación. Cuando no tienes una conexión a internet o cuenta de usuario activa, el botón de participantes no es visible."),
//        
//        //        HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
//        
//        HelpItem(title: "Necesito una cuenta de usuario?", text: "A menos que quieras compartir tus listas o inventarios con otros usuarios o syncronizar con otros aparatos, no necesitas una cuenta. Para todo lo demas, la app es identica con o sin cuenta."),
//        
//        HelpItem(title: "Puedo utilizar la app cuando no estoy online?", text: "Sí, una conexión internet o cuenta de usuario no es necesaria. Si estás online y te desconectas, la app se syncronizará automáticamente cuando te conectes de nuevo."),
//        
//        HelpItem(title: "Cómo comparto listas o inventarious con otras personas?", text: "Para compartir listas o inventarios, ve a la vista donde las listas o inventarios están enlistados, ###toca el botón para editar, ###toca la list o inventario que quieres compartir y después en 'participantes'. Aquí puedes agregar o remover participantes. Participants con invitaciones pendientes tienen un signo de interrogación. Cuando no tienes una conexión a internet o cuenta de usuario activa, el botón de participantes no es visible."),
//        
//        //        HelpItem(title: "Can I share lists or inventories with Android users?", text: "No, because there's no Android app yet. Stay in the loop though, a light version is planned."),
//        HelpItem(title: "Qué es la opción 'conección en tiempo real'?", text: "La conexión en tiempo real te permite recibir actualizaciones de otros aparatos/usuarios inmediatamente.  Con esta opción puedes deactivarla. Si la desactivas, no se volverá a activar automaticamente hasta que la actives de nuevo. Esta opción es sólo visible cuando tienes una conexión y cuenta de usuario activa."),
//        
//        HelpItem(title: "Estoy compartiendo my inventario con otros usuarios y vemos diferentes estadísticas, por qué?", text: "Para evitar confusión, cuando compartes items con otros usuarios, actualizaciones a sus precios are not compartidos automáticamente. Por esta razón es posible que usuarios tengan diferentes precios para los mismos items, lo que significa que la estadística puede mostrar diferentes gastos. Cuando quieras que tus items sean idénticos a los de otro(a) usuario(a), ve a la lista de participantes de de lista o inventario y selecciona 'descargar', próximo al(a) usuario(a)."),
//        
//        HelpItem(title: "Qué significa 'descargar' en la lista de participantes?", text: "Para evitar confusión, cuando compartes items con otros usuarios, actualizaciones a sus productos no son not compartidos automáticamente. Esto significa que diferentes usuarios pueden tener por ejemplo diferentes precios o categorías para los mismos productos.  Cuando quieras que productos sean idénticos a los de otro(a) usuario(a), ve a la lista de participantes de de lista o inventario y selecciona 'descargar', próximo al(a) usuario(a). Nota que en caso de la lista, la descarga afecta solo los productos que estan en la lista, mientras que en el inventario, debido a que este está asociado con la historia y las estadísticas, afecta a todos los productos."),
//
//        HelpItem(title: "Qué pasa cuando mi cuenta es borrada?", text: "Tus datos son borrados permanentemente. Si compartes una listas o inventarios con otras personas, estos no serán afectados, excepto que tú eres removido(a) como participante. Los datos en tu device no son afectados y puedes continuar usando la app normalmente."),
//        
//        HelpItem(title: "Problemas: No estoy recibiendo updates en tiempo real", text: "Primero que todo, revisa que tanto conexión internet esté activa y como conectado(a) con tu cuenta de usuario en Groma. Updates en tiempo real no funcionan si no estás conectado(a). Si lo estás, asegura que la conexión de tiempo real está activa en las preferencias. Cuando la conexión a internet se pierde mientras estás conectado(a) la app intenta reestablecerla automáticamente. Es este caso ves un un label arriba de los tabs en la parte baja, que dice 'conectando al servidor...' En este caso sólo tienes que esperar hasta que este label desaparezca, lo que significa que la conexión fué reestablecida.", type: .Troubleshooting),
//        
//        HelpItem(title: "Problemas: La sincronización no funciona", text: "Si estás recibiendo constantemente errores de sincronización, un último recurso es sobreescribir los datos en tu device con los datos del servidor, lo cual puede solucionar estos problemas. Para hacer esto, ve a las preferencias, y selecciona 'Sobreescribir datos locales'", type: .Troubleshooting),
    ]
    
}

//
//  AppDelegate.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import WebKit
import SafariServices
import AVFoundation

weak var timer: Timer!
var managedContext: NSManagedObjectContext!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, XMLParserDelegate {

    var window: UIWindow?
    var client: MSClient!
    let endpoint = "Endpoint=sb://podwise.servicebus.windows.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=99efNs84C80JoCaZdQyrCPiV5CShshoAU8G1Q5E9ojg="
    let hubName = "PodwiseHub"
    var eName: String = String()
    var episodeID: String = String()
    var episodeTitle: String = String()
    var episodeDescription = String()
    var episodeDuration = String()
    var episodeURL: URL!
    var skippedChannelTitle = false
    var skippedChannelDescription = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        
        client = MSClient(applicationURLString: "https://podwise.azurewebsites.net")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        //baseViewController.dismiss(animated: false, completion: nil)

        if nowPlayingEpisode != nil {
            nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
        }
        
        self.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if timer != nil {
            timer.invalidate()
        }
        
//        if let window = window {
//            if let viewControllers = window.rootViewController?.childViewControllers {
//                for viewController in viewControllers {
//                    viewController.dismiss(animated: false, completion: nil)
//                }
//            }
//        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if nowPlayingEpisode != nil {
            nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
        }
        
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Podwise")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Notification Methods
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
//        let hub: SBNotificationHub = SBNotificationHub(connectionString: endpoint, notificationHubPath: hubName)
//        
//        hub.registerNative(withDeviceToken: deviceToken, tags: nil, completion: { error in
//            if error != nil {
//                print("Error registering for notifications: \(String(describing: error))")
//            } else {
//                print("Registered with NotificationHub")
//            }
//        })
        
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        
        let managedContext = persistentContainer.viewContext
        let tokenEntity = NSEntityDescription.entity(forEntityName: "CDAPNSToken", in: managedContext)!
        let apnsToken = NSManagedObject(entity: tokenEntity, insertInto: managedContext) as! CDAPNSToken
        apnsToken.token = token
        CoreDataHelper.save(context: managedContext)
        
        registerDeviceTokenWithMicrosoft(deviceToken: token)
        
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func registerDeviceTokenWithMicrosoft(deviceToken: String) {
        AzureDBDataHelper.registerDeviceTokenWithMicrosoft(deviceToken: deviceToken, using: client)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        guard
            let aps = userInfo[AnyHashable("aps")] as? NSDictionary,
            let alert = aps["alert"] as? NSDictionary,
            let body = alert["body"] as? String,
            let title = alert["title"] as? String,
            let rssFeed = userInfo[AnyHashable("rssFeed")] as? String
            else {
                // handle any error here
                return
        }
        
        print("Title: \(title) \nBody:\(body)")
        print(rssFeed)
        
        if let parser = XMLParser(contentsOf: URL(string: rssFeed)!) {
            parser.delegate = self
            parser.parse()
        }
        print("Looking for: \(rssFeed)")
    }
    
    func downloadFile(at: URL) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        print(destinationUrl)
        
        var podcast: CDPodcast!
        let podcasts = CoreDataHelper.getPodcastWith(url: at, in: managedContext)
        if podcasts.count > 0 {
            podcast = podcasts[0]
        }
        // to check if it exists before downloading it
        if !FileManager.default.fileExists(atPath: destinationUrl.path) {
            let episodeEntity = NSEntityDescription.entity(forEntityName: "CDEpisode", in: managedContext!)!
            let episode = NSManagedObject(entity: episodeEntity, insertInto: managedContext) as! CDEpisode
            
            let parsedEpisode = Episode()
            parsedEpisode.id = episodeID
            parsedEpisode.title = episodeTitle
            parsedEpisode.itunesSubtitle = episodeDescription
            parsedEpisode.itunesDuration = episodeDuration
            parsedEpisode.audioUrl = at
            
            episode.id = episodeID
            episode.title = episodeTitle
            episode.subTitle = episodeDescription
            episode.audioURL = at
            episode.localURL = destinationUrl
            episode.duration = episodeDuration
            episode.podcast = podcast
            
            CoreDataHelper.save(context: managedContext!)
            
            // you can use NSURLSession.sharedSession to download the data asynchronously
            URLSession.shared.downloadTask(with: at, completionHandler: { (location, response, error) -> Void in
                guard let location = location, error == nil else { return }
                do {
                    // after downloading your file you need to move it to your destination url
                    print("Target Path: \(destinationUrl)")
                    try FileManager.default.moveItem(at: location, to: destinationUrl)
                    print("File moved to documents folder")
                    
                    downloads.removeFirst()
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }).resume()
        }
        
        // XMLParser Delegate Methods
        func parser(parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
            
            if elementName == "enclosure" {
                let audioURL = attributeDict["url"]
                let urlString: String = audioURL!
                let url: URL = URL(string: urlString)!
                print("URL for podcast download: \(url)")
                episodeURL = url
            }
            
            eName = elementName
            if elementName == "item" {
                episodeID = String()
                episodeTitle = String()
                episodeDescription = String()
                episodeDuration = String()
            }
        }

        func parser(parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "item" {
                downloadFile(at: episodeURL)
                parser.abortParsing()
            }
        }
        
        func parser(parser: XMLParser, foundCharacters string: String) {
            let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            
            if (!data.isEmpty) {
                switch eName {
                case "title":
                    if skippedChannelTitle == false {
                        skippedChannelTitle = true
                    } else {
                        episodeTitle += data
                    }
                case "description":
                    if skippedChannelDescription == false {
                        skippedChannelDescription = true
                    } else {
                        episodeDescription += data
                    }
                case "guid":
                    episodeID = data
                case "itunes:duration":
                    episodeDuration = data
                default:
                    break
                }
            }
        }
    }
    
    //  Tags that can be send from server in a push notification:
    
//    alert. This can be a string, like in the previous example, or a dictionary itself. As a dictionary, it can localize the text or change other aspects of the notification.
//    badge. This is a number that will display in the corner of the app icon. You can remove the badge by setting this to 0.
//    thread-id. You may use this key for grouping notifications.
//    sound. By setting this key, you can play custom notification sounds located in the app in place of the default notification sound. Custom notification sounds must be shorter than 30 seconds and have a few restrictions.
//    content-available. By setting this key to 1, the push notification becomes a silent one. This will be explored later in this push notifications tutorial.
//    category. This defines the category of the notification, which is is used to show custom actions on the notification. You will also be exploring this shortly.
}


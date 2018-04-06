//
//  AppDelegate.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import UserNotifications
import WebKit
import SafariServices
import AVFoundation

weak var timer: Timer!
var managedContext: NSManagedObjectContext!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, XMLParserDelegate, URLSessionDownloadDelegate {

    var window: UIWindow?
    var eName: String = String()
    var episodeID: String = String()
    var episodeTitle: String = String()
    var episodeDescription = String()
    var episodeDuration = String()
    var episodeURL: URL!
    var skippedChannelTitle = false
    var skippedChannelDescription = false
    var parser = XMLParser()
    var podcastURL: URL!
    
    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if nowPlayingEpisode != nil {
            nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
        }
        
        self.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if timer != nil {
            timer.invalidate()
        }
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
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }

        let token = tokenParts.joined()

        let managedContext = persistentContainer.viewContext
        let tokenEntity = NSEntityDescription.entity(forEntityName: "CDAPNSToken", in: managedContext)!
        let apnsToken = NSManagedObject(entity: tokenEntity, insertInto: managedContext) as! CDAPNSToken
        apnsToken.token = token
        CoreDataHelper.save(context: managedContext)

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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        parser.delegate = self
        
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        let alertBody = cloudKitNotification.alertBody
        
        if cloudKitNotification.notificationType == .query {
            let record = cloudKitNotification as! CKQueryNotification
            if let recordID = record.recordID {
                CloudKitDataHelper.fetchRecordWith(id: recordID, completionHandler: { (success, record) in
                    if success {
                        let record = record!
                        let rssFeed = record.object(forKey: "rssFeed") as! String
                        
                        if let rssURL = URL(string: rssFeed) {
                            self.podcastURL = rssURL
                            self.parser = XMLParser(contentsOf: rssURL)!
                            self.parser.delegate = self
                            let parsed = self.parser.parse()
                            print(parsed)

                            print("Looking for: \(rssFeed)")
                            completionHandler(UIBackgroundFetchResult.newData)
                        }
                    } else {
                        completionHandler(UIBackgroundFetchResult.noData)
                    }
                })
            }
        }
    }
    
    func downloadFile(at: URL) {
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        print(destinationUrl)
        managedContext = persistentContainer.viewContext
        var podcast: CDPodcast!
        let podcasts = CoreDataHelper.getPodcastWith(url: podcastURL, in: managedContext)
        if podcasts.count > 0 {
            podcast = podcasts[0]
            print(podcasts[0].feedURL!)
        }
        // to check if it exists before downloading it
        print("File exist at \(destinationUrl.path)? \(FileManager.default.fileExists(atPath: destinationUrl.path))")
        
        if !CoreDataHelper.episodeIsAlreadyDownloaded(title: episodeTitle, associatedPodcast: podcast, in: managedContext) {
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
            episode.progress = 0
            print(episode.podcast!.feedURL!)
            
            CoreDataHelper.save(context: managedContext!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "EpisodeReceived"), object:nil)
            
            if downloads == nil {
                downloads = []
            }
            
            let thisDownload = Download(url: destinationUrl, audioUrl: at, episode: episode, parsedEpisode: parsedEpisode, playNow: false, indexPath: IndexPath(row: 0, section: 0), addTo: podcast.playlist!)
            
            if downloads.isEmpty {
                thisDownload.setIsDownloading()
                downloads.append(thisDownload)
                downloadTask = backgroundSession.downloadTask(with: at)
                downloadTask.resume()
            } else {
                if downloads[0].isDownloading {
                    downloads.append(thisDownload)
                } else {
                    downloads[0].setIsDownloading()
                    downloadTask = backgroundSession.downloadTask(with: downloads[0].audioUrl)
                    downloadTask.resume()
                }
            }
            
            // you can use NSURLSession.sharedSession to download the data asynchronously
//            URLSession.shared.downloadTask(with: at, completionHandler: { (location, response, error) -> Void in
//                guard let location = location, error == nil else { return }
//                do {
//                    // after downloading your file you need to move it to your destination url
//                    print("Target Path: \(destinationUrl)")
//                    try FileManager.default.moveItem(at: location, to: destinationUrl)
//                    print("File moved to documents folder")
//                } catch let error as NSError {
//                    print(error.localizedDescription)
//                }
//            }).resume()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if downloads.count > 0 {
            let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            //print("downloaded \(progress)%")
            downloads[0].setPercentDown(to: progress)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DownloadProgress"), object: downloads[0])
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completed: error: \(String(describing: error))")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // after downloading your file you need to move it to your destination url
            try FileManager.default.moveItem(at: location, to: downloads[0].url)
            print("File moved to documents folder")

            print(downloads.count)
            downloads = Array(downloads.dropFirst())
            print(downloads.count)
            if downloads.count > 0 {
                self.downloadFile(at: downloads[0].audioUrl)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    // XMLParser Delegate Methods
    func parser(_ parser: XMLParser, didStartElement: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String]) {
        
        if didStartElement == "enclosure" {
            let audioURL = attributes["url"]
            let urlString: String = audioURL!
            let url: URL = URL(string: urlString)!
            print("URL for podcast download: \(url)")
            episodeURL = url
        }
        
        eName = didStartElement
        if didStartElement == "item" {
            episodeID = String()
            episodeTitle = String()
            episodeDescription = String()
            episodeDuration = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement: String, namespaceURI: String?, qualifiedName: String?) {
        if didEndElement == "item" {
            downloadFile(at: episodeURL)
            parser.abortParsing()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters: String) {
        let data = foundCharacters.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        
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
    
    //  Tags that can be send from server in a push notification:
    
//    alert. This can be a string, like in the previous example, or a dictionary itself. As a dictionary, it can localize the text or change other aspects of the notification.
//    badge. This is a number that will display in the corner of the app icon. You can remove the badge by setting this to 0.
//    thread-id. You may use this key for grouping notifications.
//    sound. By setting this key, you can play custom notification sounds located in the app in place of the default notification sound. Custom notification sounds must be shorter than 30 seconds and have a few restrictions.
//    content-available. By setting this key to 1, the push notification becomes a silent one. This will be explored later in this push notifications tutorial.
//    category. This defines the category of the notification, which is is used to show custom actions on the notification. You will also be exploring this shortly.
}


//
//  AzureDBDataHelper.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-01.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import WebKit
import SafariServices

class AzureDBDataHelper {
    
    static func registerDeviceTokenWithMicrosoft(deviceToken: String, using client: MSClient) {
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            print(identifierForVendor.uuidString)
            
            //let delegate = UIApplication.sharedApplication().delegate as AppDelegate
            //let client = delegate.client!
            let device = ["deviceToken":deviceToken, "deviceId": identifierForVendor.uuidString]
            let devicesTable = client.table(withName: "Devices")
            
            let query = devicesTable.query(with: NSPredicate(format: "deviceId == %@", identifierForVendor.uuidString))
            query.read(completion: { (result, error) in
                if let err = error {
                    print("ERROR ", err)
                } else if let items = result?.items {
                    if items.count > 0 { // do an update
                        for item in items {
                            print("Device: ", item)
                            var newItem = item
                            newItem["deviceToken"] = deviceToken
                            devicesTable.update(newItem as [NSObject: AnyObject], completion: { (result, error) -> Void in
                                if let err = error {
                                    print("ERROR ", err)
                                } else if let updatedItem = result {
                                    print("Updated Device Item: ", updatedItem)
                                }
                            })
                        }
                    } else { // do an insert
                        devicesTable.insert(device) {
                            (insertedItem, error) in
                            if (error != nil) {
                                print("Error \(error!.localizedDescription)");
                            } else {
                                print("Item inserted, id: \(String(describing: insertedItem!["id"])) deviceToken: \(String(describing: insertedItem!["deviceToken"]))")
                            }
                        }
                    }
                }
            })
        }
    }
    
    static func handle(subscribe: Bool, to podcast: CDPodcast) {
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let client = delegate.client!
            let podcastsTable = client.table(withName: "Podcasts")
            let podcastsForDeviceTable = client.table(withName: "PodcastsForDevice")
            let podcastToInsert = ["podcastId":"\(podcast.id)", "title":"\(podcast.title!)", "rssFeed":"\(podcast.feedURL!.absoluteString)"]
            let podcastForDevice = ["deviceId":identifierForVendor.uuidString, "podcastId":"\(podcast.id)", "subscribed":subscribe] as [String : Any]
            
            let query = podcastsTable.query(with: NSPredicate(format: "podcastId == %@", "\(podcast.id)"))
            query.read(completion: { (result, error) in
                if let err = error {
                    print("ERROR ", err)
                } else if let items = result?.items {
                    if items.count > 0 { // if there is a row in the Podcast table, check PodcastsForDevice
                        for item in items {
                            print("Podcast: \(item)")
                            
                            // check PodcastsForDevice for deviceId and podcastId combo
                            let p1 = NSPredicate(format: "podcastId == %@", "\(podcast.id)")
                            let p2 = NSPredicate(format: "deviceId == %@", identifierForVendor.uuidString)
                            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
                            let podcastsForDeviceQuery = podcastsForDeviceTable.query(with: predicate)
                            podcastsForDeviceQuery.read(completion: { (result, error) in
                                if let err = error {
                                    print("ERROR ", err)
                                } else if let rows = result?.items {
                                    if rows.count > 0 { // if there is a row in PodcastsForDevice, update subscribed value
                                        for row in rows { // update row with subscr
                                            print("Device: \(row)")
                                            var newItem = row
                                            newItem["subscribed"] = subscribe
                                            podcastsForDeviceTable.update(newItem as [NSObject: AnyObject], completion: { (result, error) -> Void in
                                                if let err = error {
                                                    print("ERROR ", err)
                                                } else if let updatedItem = result {
                                                    print("Updated Device Item: \(updatedItem)")
                                                }
                                            })
                                        }
                                    } else { // insert PocastsForDevice row
                                        podcastsForDeviceTable.insert(podcastForDevice) {
                                            (insertedItem, error) in
                                            if (error != nil) {
                                                print("Error \(error!.localizedDescription)");
                                            } else {
                                                print("Item inserted, podcastId: \(String(describing: insertedItem!["podcastId"])) deviceId: \(String(describing: insertedItem!["deviceId"]))")
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    } else { // do an insert into podcasts table and then into PodcastsForDevice
                        podcastsTable.insert(podcastToInsert) {
                            (insertedItem, error) in
                            if (error != nil) {
                                print("Error \(error!.localizedDescription)");
                            } else {
                                print("Item inserted, id: \(String(describing: insertedItem!["podcastId"])) title: \(String(describing: insertedItem!["title"]))")
                                
                                podcastsForDeviceTable.insert(podcastForDevice) {
                                    (insertedItem, error) in
                                    if (error != nil) {
                                        print("Error \(error!.localizedDescription)");
                                    } else {
                                        print("Item inserted, podcastId: \(String(describing: insertedItem!["id"])) deviceId: \(String(describing: insertedItem!["deviceToken"]))")
                                    }
                                }
                            }
                        }
                    }
                }
            })
        }
    }
}

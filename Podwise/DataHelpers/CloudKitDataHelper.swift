//
//  CloudKitDataHelper.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-02-18.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitDataHelper {
    
    static func podcastExistsInCloud(rssFeed: String, completionHandler:@escaping (_ success: Bool, _ record: CKRecord) -> Void) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        let predicate = NSPredicate(format: "rssFeed == %@", rssFeed)
        let query = CKQuery(recordType: "Podcasts", predicate: predicate)
        var result = false
        publicDB.perform(query, inZoneWith: nil, completionHandler: {results, er in
            
            if results != nil {
                print(results!.count)
                if results!.count >= 1 {
                    result = true
                    print(result)
                    completionHandler(result, results![0])
                } else {
                    result = false
                    print(result)
                    completionHandler(result, CKRecord(recordType: "Podcasts"))
                }
            }
        })
    }
    
    static func subscriptionExistsInCloud(deviceToken: String, record: CKRecord, completionHandler:@escaping (_ success: Bool, _ record: CKRecord) -> Void) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        let podcastReference = CKReference(recordID: record.recordID, action: CKReferenceAction.deleteSelf)
        let predicate1 = NSPredicate(format: "deviceToken == %@", deviceToken)
        let predicate2 = NSPredicate(format: "podcast == %@", podcastReference)
        let predicateList = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [predicate1, predicate2])
        let query = CKQuery(recordType: "Subscriptions", predicate: predicateList)
        var result = false
        publicDB.perform(query, inZoneWith: nil, completionHandler: {results, er in
            
            if results != nil {
                print(results!.count)
                if results!.count >= 1 {
                    result = true
                    print(result)
                    completionHandler(result, results![0])
                } else {
                    result = false
                    print(result)
                    completionHandler(result, CKRecord(recordType: "Subscriptions"))
                }
            }
        })
    }
    
    static func createPodcastRecordWith(title: String, rssFeed: String, completionHandler:@escaping (_ success: Bool, _ record: CKRecord) -> Void) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        let ckRecord = CKRecord(recordType: "Podcasts", recordID: CKRecordID(recordName: UUID().uuidString))
        
        ckRecord.setObject(title as CKRecordValue?, forKey: "title")
        ckRecord.setObject(rssFeed as CKRecordValue?, forKey: "rssFeed")
        ckRecord.setObject("" as CKRecordValue, forKey: "latestEpisode")
        
        publicDB.save(ckRecord, completionHandler: { (record, error) in
            if error != nil {
                print(error!)
                completionHandler(false, ckRecord)
                return
            }
            print("Successfully added record")
            completionHandler(true, ckRecord)
        })
    }
    
    static func subscribeToPodcastWith(title: String, rssFeed: String) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        podcastExistsInCloud(rssFeed: rssFeed, completionHandler:{(success: Bool, record: CKRecord) -> Void in
            if success {
                // subscribe to Podcast
                let deviceTokens = CoreDataHelper.getAPNSToken(context: managedContext!)
                if deviceTokens.count > 0 {
                    let deviceID = deviceTokens[0]
                    subscriptionExistsInCloud(deviceToken: deviceID.token!, record: record, completionHandler: { (foundSubRecord: Bool, subRecord: CKRecord) in
                        if !foundSubRecord {
                            let ckRecord = CKRecord(recordType: "Subscriptions", recordID: CKRecordID(recordName: UUID().uuidString))
                            let podcastReference = CKReference(recordID: record.recordID, action: CKReferenceAction.deleteSelf)
                            ckRecord.setObject(podcastReference, forKey: "podcast")
                            ckRecord.setObject(deviceID.token as CKRecordValue?, forKey: "deviceToken")
                            
                            publicDB.save(ckRecord, completionHandler: { (subsRecord, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                print("Successfully subscribed to podcast in cloud")
                                createCloudKitSubscriptionFor(record: record)
                            })
                        }
                    })
                }
            } else {
                // create new Podcast record and subscribe
                createPodcastRecordWith(title: title, rssFeed: rssFeed, completionHandler: { (success: Bool, record: CKRecord) in
                    if success {
                        let ckRecord = CKRecord(recordType: "Subscriptions", recordID: CKRecordID(recordName: UUID().uuidString))
                        let podcastReference = CKReference(recordID: record.recordID, action: CKReferenceAction.deleteSelf)
                        ckRecord.setObject(podcastReference, forKey: "podcast")
                        let deviceTokens = CoreDataHelper.getAPNSToken(context: managedContext!)
                        if deviceTokens.count > 0 {
                            let deviceID = deviceTokens[0]
                            ckRecord.setObject(deviceID.token! as CKRecordValue?, forKey: "deviceToken")
                            
                            publicDB.save(ckRecord, completionHandler: { (subRecord, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                print("Successfully subscribed to podcast in cloud")
                                createCloudKitSubscriptionFor(record: record)
                            })
                        }
                    }
                })
            }
        })
    }
    
    static func unsubscribeFromPodcastWith(title: String, rssFeed: String) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        podcastExistsInCloud(rssFeed: rssFeed, completionHandler:{(success: Bool, record: CKRecord) -> Void in
            if success {
                // unsubscribe to Podcast
                let deviceTokens = CoreDataHelper.getAPNSToken(context: managedContext!)
                if deviceTokens.count > 0 {
                    let deviceID = deviceTokens[0]
                    subscriptionExistsInCloud(deviceToken: deviceID.token!, record: record, completionHandler: { (foundSubRecord: Bool, subRecord: CKRecord) in
                        if foundSubRecord {
                            publicDB.delete(withRecordID: subRecord.recordID, completionHandler: { (recordID, error) in
                                if error != nil {
                                    print("Record \(String(describing: recordID)) was not successfully deleted")
                                }
                            })
                        }
                    })
                }
            }
        })
    }
    
    static func createCloudKitSubscriptionFor(record: CKRecord) {
        print(record.object(forKey: "deviceToken"))
        print(record.object(forKey: "title"))
        print(record.object(forKey: "rssFeed"))
        let predicate = NSPredicate(format: "rssFeed == %@", record.object(forKey: "rssFeed") as! String)
        let subscription = CKQuerySubscription(recordType: "Podcasts", predicate: predicate, options: .firesOnRecordUpdate)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.titleLocalizationKey = "%1$@"
        notificationInfo.titleLocalizationArgs = ["title"]
        notificationInfo.alertLocalizationKey = "%1$@"
        notificationInfo.alertLocalizationArgs = ["latestEpisode"]
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendMutableContent = true
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        publicDB.save(subscription) {(savedSubscription, error) in
            if error == nil {
                print("CloudKit Subscription saved!")
            } else {
                print("Couldn't save subscription")
            }
        }
    }
    
    static func fetchRecordWith(id: CKRecordID, completionHandler:@escaping (_ success: Bool, _ record: CKRecord?) -> Void) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        publicDB.fetch(withRecordID: id) { (record, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                completionHandler(false, nil)
            } else {
                completionHandler(true, record)
            }
        }
    }
}

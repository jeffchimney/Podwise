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
                    print(results!.count)
                    result = true
                    completionHandler(result, results![0])
                }
            }
        })
    }
    
    static func createPodcastRecordWith(title: String, rssFeed: String, completionHandler:@escaping (_ success: Bool) -> Void) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        let ckRecord = CKRecord(recordType: "Podcasts", recordID: CKRecordID(recordName: UUID().uuidString))
        
        ckRecord.setObject(title as CKRecordValue?, forKey: "title")
        ckRecord.setObject(rssFeed as CKRecordValue?, forKey: "rssFeed")
        ckRecord.setObject("" as CKRecordValue, forKey: "latestEpisode")
        
        publicDB.save(ckRecord, completionHandler: { (record, error) in
            if error != nil {
                print(error!)
                completionHandler(false)
                return
            }
            print("Successfully added record")
            completionHandler(true)
        })
    }
    
    static func subscribeToPodcastWith(title: String, rssFeed: String) {
        let container: CKContainer = CKContainer.default()
        let publicDB: CKDatabase = container.publicCloudDatabase
        
        podcastExistsInCloud(rssFeed: rssFeed, completionHandler:{(success: Bool, record: CKRecord) -> Void in
            if success {
                // subscribe to Podcast
                let ckRecord = CKRecord(recordType: "Subscriptions", recordID: CKRecordID(recordName: UUID().uuidString))
                
                ckRecord.setObject(title as CKRecordValue?, forKey: "title")
                ckRecord.setObject(rssFeed as CKRecordValue?, forKey: "rssFeed")
                ckRecord.setObject("" as CKRecordValue, forKey: "latestEpisode")
            } else {
                // create new Podcast record and subscribe
            }
        })
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Podcasts", predicate: predicate)
        //let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        publicDB.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error retrieving from cloudkit")
            } else {
//                let ckRecord = CKRecord(recordType: "Podcasts", recordID: CKRecordID(recordName: UUID().uuidString))
//
//                ckRecord.setObject(title as CKRecordValue?, forKey: "title")
//                ckRecord.setObject(rssFeed as CKRecordValue?, forKey: "rssFeed")
//                ckRecord.setObject(startDate as CKRecordValue, forKey: "warrantyStarts")
//
//                let syncedDate = Date()
//                ckRecord.setObject(syncedDate as CKRecordValue?, forKey: "lastSynced")
//
//                if cdRecord.recentlyDeleted {
//                    let dateDeleted = dateFormatter.string(from: cdRecord.dateDeleted! as Date)
//                    ckRecord.setObject(dateDeleted as CKRecordValue?, forKey: "dateDeleted")
//                }
//
//                privateDatabase.save(ckRecord, completionHandler: { (record, error) in
//                    if error != nil {
//                        print(error!)
//                        return
//                    }
//                    print("Successfully added record")
//
//                    self.importAssociatedImages(cdRecord: cdRecord, syncedDate: syncedDate, context: context)
//                    self.importAssociatedNotes(cdRecord: cdRecord, syncedDate: syncedDate, context: context)
//                })
            }
        })
    }
    
}

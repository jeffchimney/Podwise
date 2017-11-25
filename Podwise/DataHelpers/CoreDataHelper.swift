//
//  CoreDataHelper.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-22.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import EventKit

class CoreDataHelper {
    
    static func fetchAllEpisodes(in context: NSManagedObjectContext) -> [CDEpisode] {
        // Get associated images
        let recordFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
        
        var recordRecords: [NSManagedObject] = []
        do {
            recordRecords = try context.fetch(recordFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var recordList: [CDEpisode] = []
        for record in recordRecords {
            let thisRecord = record as! CDEpisode
            
            recordList.append(thisRecord)
        }
        return recordList
    }
    
    static func getEpisodeWith(id: String, in context: NSManagedObjectContext) -> [CDEpisode] {
        // Get associated images
        let episodeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
        let predicate = NSPredicate(format: "id = %@", id)
        episodeFetchRequest.predicate = predicate
        
        var episodeRecords: [NSManagedObject] = []
        do {
            episodeRecords = try context.fetch(episodeFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var episodeList: [CDEpisode] = []
        for episode in episodeRecords {
            let thisEpisode = episode as! CDEpisode
            
            episodeList.append(thisEpisode)
        }
        return episodeList
    }
    
    static func getPodcastWith(id: Int, in context: NSManagedObjectContext) -> [CDPodcast] {
        // Get associated images
        let podcastFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPodcast")
        let predicate = NSPredicate(format: "id = \(id)")
        podcastFetchRequest.predicate = predicate
        
        var podcastRecords: [NSManagedObject] = []
        do {
            podcastRecords = try context.fetch(podcastFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var podcastList: [CDPodcast] = []
        for podcast in podcastRecords {
            let thisPodcast = podcast as! CDPodcast
            
            podcastList.append(thisPodcast)
        }
        return podcastList
    }
    
    static func fetchAllPodcasts(in context: NSManagedObjectContext) -> [CDPodcast] {
        // Get associated images
        let podcastFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPodcast")
        
        var podcastRecords: [NSManagedObject] = []
        do {
            podcastRecords = try context.fetch(podcastFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var podcastList: [CDPodcast] = []
        for podcast in podcastRecords {
            let thisPodcast = podcast as! CDPodcast
            
            podcastList.append(thisPodcast)
        }
        return podcastList
    }
    
    static func fetchEpisodesFor(podcast: CDPodcast, in context: NSManagedObjectContext) -> [CDEpisode] {
        let episodeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
        let predicate = NSPredicate(format: "podcast = %@", podcast)
        episodeFetchRequest.predicate = predicate
        
        var episodes: [NSManagedObject] = []
        do {
            episodes = try context.fetch(episodeFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var episodeList: [CDEpisode] = []
        for episode in episodes {
            let thisEpisode = episode as! CDEpisode
            
            episodeList.append(thisEpisode)
        }
        return episodeList
    }
    
    static func save(context: NSManagedObjectContext) {
        // save locally
        do {
            try context.save()
        } catch {
            DispatchQueue.main.async {
                print("Connection error. Try again later.")
            }
            return
        }
    }
    
    static func delete(episode: CDEpisode, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if episode == thisRecord {
                context.delete(thisRecord)
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
}

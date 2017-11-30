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
    
    static func getAPNSToken(context: NSManagedObjectContext) -> [CDAPNSToken] {
        // Get associated images
        let tokenFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDAPNSToken")
        
        var tokenRecords: [NSManagedObject] = []
        do {
            tokenRecords = try context.fetch(tokenFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var tokenList: [CDAPNSToken] = []
        for token in tokenRecords {
            let thisToken = token as! CDAPNSToken
            
            tokenList.append(thisToken)
        }
        return tokenList
    }
    
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
    
    static func fetchAllPlaylists(in context: NSManagedObjectContext) -> [CDPlaylist] {
        // Get associated images
        let playlistFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPlaylist")
        
        var playlistRecords: [NSManagedObject] = []
        do {
            playlistRecords = try context.fetch(playlistFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var playlistList: [CDPlaylist] = []
        for playlist in playlistRecords {
            let thisPlaylist = playlist as! CDPlaylist
            
            playlistList.append(thisPlaylist)
        }
        return playlistList
    }
    
    static func fetchAllPlaylists(with name: String, in context: NSManagedObjectContext) -> [CDPlaylist] {
        // Get associated images
        let playlistFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPlaylist")
        let predicate = NSPredicate(format: "name == %@", name)
        playlistFetchRequest.predicate = predicate
        
        var playlistRecords: [NSManagedObject] = []
        do {
            playlistRecords = try context.fetch(playlistFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var playlistList: [CDPlaylist] = []
        for playlist in playlistRecords {
            let thisPlaylist = playlist as! CDPlaylist
            
            playlistList.append(thisPlaylist)
        }
        return playlistList
    }
    
    static func getHighestPlaylistSortIndex(in context: NSManagedObjectContext) -> Int {
        // Get associated images
        let playlistFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPlaylist")
        
        playlistFetchRequest.fetchLimit = 1
        let sortDescriptor = NSSortDescriptor(key: "sortIndex", ascending: false)
        playlistFetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let playlists = try context.fetch(playlistFetchRequest)
            let max = playlists.first as! CDPlaylist
            return Int(max.sortIndex)
        } catch _ {
            return 0
        }
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
    
    static func getEpisodesForPodcastWithNoPlaylist(podcast: CDPodcast, in context: NSManagedObjectContext) -> [CDEpisode] {
        var episodeList: [CDEpisode] = []
        if podcast.playlist == nil {
            let episodeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
            let predicate = NSPredicate(format: "podcast = %@ && playlist == nil", podcast)
            episodeFetchRequest.predicate = predicate
            
            var episodeRecords: [NSManagedObject] = []
            do {
                episodeRecords = try context.fetch(episodeFetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            for episode in episodeRecords {
                let thisEpisode = episode as! CDEpisode
                
                episodeList.append(thisEpisode)
            }
        }
        return episodeList
    }
    
    static func getAllEpisodesWithNoPlaylist(in context: NSManagedObjectContext) -> [CDEpisode] {
        var episodeList: [CDEpisode] = []
        let podcastList: [CDPodcast] = fetchAllPodcasts(in: context)
        for podcast in podcastList {
            if podcast.playlist == nil {
                let episodeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDEpisode")
                let predicate = NSPredicate(format: "podcast = %@ && playlist == nil", podcast)
                episodeFetchRequest.predicate = predicate
                
                var episodeRecords: [NSManagedObject] = []
                do {
                    episodeRecords = try context.fetch(episodeFetchRequest)
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
                for episode in episodeRecords {
                    let thisEpisode = episode as! CDEpisode
                    
                    episodeList.append(thisEpisode)
                }
            }
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
    
    static func getPodcastsWhere(subscribed: Bool, in context: NSManagedObjectContext) -> [CDPodcast] {
        // Get associated images
        let podcastFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPodcast")
        let predicate = NSPredicate(format: "subscribed = \(subscribed)")
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
    
    static func fetchPodcastsFor(playlist: CDPlaylist, in context: NSManagedObjectContext) -> [CDPodcast] {
        let podcastFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDPodcast")
        let predicate = NSPredicate(format: "playlist = %@", playlist)
        podcastFetchRequest.predicate = predicate
        
        var podcasts: [NSManagedObject] = []
        do {
            podcasts = try context.fetch(podcastFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var podcastList: [CDPodcast] = []
        for podcast in podcasts {
            let thisPodcast = podcast as! CDPodcast
            
            podcastList.append(thisPodcast)
        }
        return podcastList
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

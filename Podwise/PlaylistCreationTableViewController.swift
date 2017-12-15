//
//  PlaylistCreationTableViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-27.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class PlaylistCreationTableViewController: UITableViewController {
    
    var playlist: CDPlaylist!
    var podcasts: [CDPodcast] = []
    var selectedPodcasts: [CDPodcast] = []
    var podcastsInPlaylist: [CDPodcast] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var managedContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        podcasts.sort(by: { $0.title! < $1.title!})
        
        if playlist != nil {
            podcastsInPlaylist = CoreDataHelper.fetchPodcastsFor(playlist: playlist, in: managedContext!)
            saveButton.title = "Save"
        } else {
            saveButton.title = "Create"
        }
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return podcasts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 50
        } else {
            return 80
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 50
        } else {
            return 25
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath as IndexPath) as! PlaylistTitleCell
            
            if playlist != nil {
                cell.titleTextField.text = playlist.name!
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistCell", for: indexPath as IndexPath) as! PodcastChecklistCell
            
            if podcastsInPlaylist.contains(podcasts[indexPath.row]) {
                cell.accessoryType = .checkmark
            }
            
            cell.titleLabel.text = podcasts[indexPath.row].title
            cell.networkLabel.text = podcasts[indexPath.row].author
            
            if let imageData = podcasts[indexPath.row].image {
                cell.artImageView.image = UIImage(data: imageData)
            }
            
            cell.artImageView.layer.cornerRadius = 10
            cell.artImageView.layer.masksToBounds = true
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let cell = tableView.cellForRow(at: indexPath) as! PodcastChecklistCell
            if cell.accessoryType == .checkmark { // deselect row
                DispatchQueue.main.async {
                    cell.accessoryType = .none
                }
                if selectedPodcasts.contains(podcasts[indexPath.row]) {
                    let index = selectedPodcasts.index(of: podcasts[indexPath.row])
                    selectedPodcasts.remove(at: index!)
                }
            } else { // select row
                DispatchQueue.main.async {
                    cell.accessoryType = .checkmark
                }
                selectedPodcasts.append(podcasts[indexPath.row])
            }
        }
    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        let titleCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PlaylistTitleCell
        if playlist == nil {
            let existingPlaylists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            var playlistAlreadyExists = false
            var preexistingPlaylist: CDPlaylist!
            for existingPlaylist in existingPlaylists {
                if existingPlaylist.name == titleCell.titleTextField.text {
                    playlistAlreadyExists = true
                    preexistingPlaylist = existingPlaylist
                }
            }
            
            if !playlistAlreadyExists {
                let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
                let newPlaylist = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
                
                newPlaylist.name = titleCell.titleTextField.text
                let sortIndex = CoreDataHelper.getHighestPlaylistSortIndex(in: managedContext!)
                newPlaylist.sortIndex = (Int64(sortIndex + Int(1)))
                newPlaylist.id = UUID().uuidString
                print(newPlaylist.sortIndex)
                for podcast in selectedPodcasts {
                    podcast.playlist = newPlaylist
                }
            } else {
                for podcast in selectedPodcasts {
                    podcast.playlist = preexistingPlaylist
                }
            }
            
            CoreDataHelper.save(context: managedContext!)
        } else {
            playlist.name = titleCell.titleTextField.text
            let sortIndex = CoreDataHelper.getHighestPlaylistSortIndex(in: managedContext!)
            playlist.sortIndex = (Int64(sortIndex + Int(1)))
            playlist.id = UUID().uuidString
            print(playlist.sortIndex)
            for podcast in selectedPodcasts {
                podcast.playlist = playlist
            }
            
            CoreDataHelper.save(context: managedContext!)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
}

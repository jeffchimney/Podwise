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
    
    var podcasts: [CDPodcast] = []
    var selectedPodcasts: [CDPodcast] = []
    var managedContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        podcasts.sort(by: { $0.title! < $1.title!})
        
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
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistCell", for: indexPath as IndexPath) as! PodcastChecklistCell
            
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
        let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
        let playlist = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
        
        let titleCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PlaylistTitleCell
        playlist.name = titleCell.titleTextField.text
        
        for podcast in selectedPodcasts {
            podcast.playlist = playlist
        }
        
        CoreDataHelper.save(context: managedContext!)
        
        navigationController?.popViewController(animated: true)
    }
    
}

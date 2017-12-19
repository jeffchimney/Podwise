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

class PlaylistCreationTableViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var playlist: CDPlaylist!
    var podcasts: [CDPodcast] = []
    var selectedPodcasts: [CDPodcast] = []
    var podcastsInPlaylist: [CDPodcast] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var managedContext: NSManagedObjectContext?
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 25, left: 8.0, bottom: 25, right: 8.0)
    
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
        
        collectionView.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        collectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: collectionView.frame.width-16, height: 50)
        } else {
            let height = CGFloat(podcasts.count * 80 + 50)
            return CGSize(width: collectionView.frame.width-16, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistTitleCell", for: indexPath) as! PlaylistTitleCell
            
            if playlist != nil {
                cell.titleTextField.text = playlist.name!
            }
            
            cell.layer.cornerRadius = 15
            cell.layer.masksToBounds = true
            
            cell.isUserInteractionEnabled = false
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewPlaylistCell", for: indexPath) as! PodcastsForPlaylistCell
            
            cell.subscriptionsTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
            cell.subscriptionsTableView.frame = cell.bounds
            cell.subscriptionsTableView.podcasts = podcasts
            cell.subscriptionsTableView.podcastsInPlaylist = podcastsInPlaylist
            cell.subscriptionsTableView.subscribed = true
            cell.subscriptionsTableView.rowInTableView = indexPath.row
            cell.subscriptionsTableView.layer.cornerRadius = 15
            cell.subscriptionsTableView.layer.masksToBounds = true
            
            cell.subscriptionsTableView.reloadData()
            
            return cell
        }
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if indexPath.section == 0 {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath as IndexPath) as! PlaylistTitleCell
//
//            if playlist != nil {
//                cell.titleTextField.text = playlist.name!
//            }
//
//            cell.layer.cornerRadius = 15
//            cell.layer.masksToBounds = true
//
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistCell", for: indexPath as IndexPath) as! PodcastChecklistCell
//
//            if podcastsInPlaylist.contains(podcasts[indexPath.row]) {
//                cell.accessoryType = .checkmark
//            }
//
//            cell.titleLabel.text = podcasts[indexPath.row].title
//            cell.networkLabel.text = podcasts[indexPath.row].author
//
//            if let imageData = podcasts[indexPath.row].image {
//                cell.artImageView.image = UIImage(data: imageData)
//            }
//
//            cell.artImageView.layer.cornerRadius = 10
//            cell.artImageView.layer.masksToBounds = true
//
//            return cell
//        }
//    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.section == 1 {
//            let cell = tableView.cellForRow(at: indexPath) as! PodcastChecklistCell
//            if cell.accessoryType == .checkmark { // deselect row
//                DispatchQueue.main.async {
//                    cell.accessoryType = .none
//                }
//                if selectedPodcasts.contains(podcasts[indexPath.row]) {
//                    let index = selectedPodcasts.index(of: podcasts[indexPath.row])
//                    selectedPodcasts.remove(at: index!)
//                }
//            } else { // select row
//                DispatchQueue.main.async {
//                    cell.accessoryType = .checkmark
//                }
//                selectedPodcasts.append(podcasts[indexPath.row])
//            }
//        }
//    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        
        
        let titleCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! PlaylistTitleCell
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

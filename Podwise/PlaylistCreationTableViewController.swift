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
    var podcastsInPlaylist: [CDPodcast] = []
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var managedContext: NSManagedObjectContext?
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
    
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
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        self.transitioningDelegate = self
        
        collectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = CGFloat(podcasts.count * 80 + 50)
        return CGSize(width: collectionView.frame.width-16, height: height)
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

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewPlaylistCell", for: indexPath) as! PodcastsForPlaylistCell
        
        cell.subscriptionsTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
        cell.subscriptionsTableView.frame = cell.bounds
        cell.subscriptionsTableView.podcasts = podcasts
        cell.subscriptionsTableView.podcastsInPlaylist = podcastsInPlaylist
        cell.subscriptionsTableView.subscribed = true
        cell.subscriptionsTableView.rowInTableView = indexPath.row
        cell.subscriptionsTableView.layer.cornerRadius = 15
        cell.subscriptionsTableView.layer.masksToBounds = true
        cell.subscriptionsTableView.previousViewController = self
        
        if playlist != nil {
            cell.subscriptionsTableView.playlist = playlist
        }
        
        cell.subscriptionsTableView.reloadData()
        
        return cell
    }
    
    func createPlaylist(playlistName: String, selectedPodcasts: [CDPodcast]) {
        if playlist == nil {
            let existingPlaylists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            var playlistAlreadyExists = false
            var preexistingPlaylist: CDPlaylist!
            for existingPlaylist in existingPlaylists {
                if existingPlaylist.name == playlistName {
                    playlistAlreadyExists = true
                    preexistingPlaylist = existingPlaylist
                }
            }
            
            if !playlistAlreadyExists {
                let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
                let newPlaylist = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
                
                newPlaylist.name = playlistName
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
            playlist.name = playlistName
            playlist.id = UUID().uuidString
            print(playlist.sortIndex)
            print(selectedPodcasts.count)
            for podcast in selectedPodcasts {
                podcast.playlist = playlist
            }
            
            CoreDataHelper.save(context: managedContext!)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
}

extension PlaylistCreationTableViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if presented == self {
            return PresentationController(presentedViewController: presented, presenting: presenting)
        }
        return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented == self {
            return CardAnimationController(isPresenting: true)
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed == self {
            return CardAnimationController(isPresenting: false)
        } else {
            return nil
        }
    }
    
    
}

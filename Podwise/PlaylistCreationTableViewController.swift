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
    //weak var managedContext: NSManagedObjectContext?
    weak var relayoutSectionDelegate: relayoutSectionDelegate!
    var colour = UIColor()
    var colourSet = false
    
    //fileprivate let sectionInsets = UIEdgeInsets(top: 0, left: 8.0, bottom: 4.0, right: 8.0)
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
        
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.transitioningDelegate = self
        
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        colour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        
        collectionView.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section != 0 {
            let height = CGFloat(50)
            return CGSize(width: collectionView.frame.width-16, height: height)
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
        
        if indexPath.section != 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistColourCell", for: indexPath) as! PlaylistColourCell
            
            cell.purpleButton.layer.cornerRadius = 20
            cell.purpleButton.layer.masksToBounds = true
            cell.blueButton.layer.cornerRadius = 20
            cell.blueButton.layer.masksToBounds = true
            cell.greenButton.layer.cornerRadius = 20
            cell.greenButton.layer.masksToBounds = true
            cell.yellowButton.layer.cornerRadius = 20
            cell.yellowButton.layer.masksToBounds = true
            cell.orangeButton.layer.cornerRadius = 20
            cell.orangeButton.layer.masksToBounds = true
            cell.redButton.layer.cornerRadius = 20
            cell.redButton.layer.masksToBounds = true
            cell.greyButton.layer.cornerRadius = 20
            cell.greyButton.layer.masksToBounds = true
            
            cell.layer.cornerRadius = 15
            cell.layer.masksToBounds = true
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewPlaylistCell", for: indexPath) as! PodcastsForPlaylistCell
            
            cell.subscriptionsTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
            cell.subscriptionsTableView.frame = cell.bounds
            cell.subscriptionsTableView.podcasts = podcasts
            cell.subscriptionsTableView.podcastsInPlaylist = podcastsInPlaylist
            cell.subscriptionsTableView.subscribed = true
            cell.subscriptionsTableView.rowInTableView = indexPath.row
            cell.subscriptionsTableView.previousViewController = self
            
            cell.contentView.layer.cornerRadius = 15
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.75
            cell.layer.shadowOffset = CGSize.zero
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            cell.layer.masksToBounds = false
            
            if playlist != nil {
                cell.subscriptionsTableView.playlist = playlist
            }
            
            cell.subscriptionsTableView.reloadData()
            
            return cell
        }
    }
    
    func createPlaylist(playlistName: String, selectedPodcasts: [CDPodcast]) {
        let colourData = NSKeyedArchiver.archivedData(withRootObject: colour)
        
        if playlist == nil {
            let existingPlaylists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            var playlistAlreadyExists = false
            var preexistingPlaylist: CDPlaylist!
            for existingPlaylist in existingPlaylists {
                if existingPlaylist.name == playlistName {
                    playlistAlreadyExists = true
                    preexistingPlaylist = existingPlaylist
                    preexistingPlaylist.colour = colourData
                }
            }
            
            if !playlistAlreadyExists {
                let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
                let newPlaylist = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
                
                newPlaylist.name = playlistName
                let sortIndex = CoreDataHelper.getHighestPlaylistSortIndex(in: managedContext!)
                newPlaylist.sortIndex = (Int64(sortIndex + Int(1)))
                newPlaylist.id = UUID().uuidString
                newPlaylist.colour = colourData

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
            
            if colourSet {
                playlist.colour = colourData
            }

            for podcast in selectedPodcasts {
                podcast.playlist = playlist
            }
            
            CoreDataHelper.save(context: managedContext!)
        }
        
        relayoutSectionDelegate.reloadCollectionView()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func setPlaylistColour(_ sender: Any) {
        
        let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 1)) as! PlaylistColourCell
        let buttonPressed = sender as! UIButton
        switch buttonPressed {
        case cell.purpleButton:
            colour = UIColor(displayP3Red: 88/255, green: 86/255, blue: 214/255, alpha: 1.0)
        case cell.blueButton:
            colour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        case cell.greenButton:
            colour = UIColor(displayP3Red: 76/255, green: 217/255, blue: 100/255, alpha: 1.0)
        case cell.yellowButton:
            colour = UIColor(displayP3Red: 255/255, green: 204/255, blue: 0, alpha: 1.0)
        case cell.orangeButton:
            colour = UIColor(displayP3Red: 255/255, green: 149/255, blue: 0, alpha: 1.0)
        case cell.redButton:
            colour = UIColor(displayP3Red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0)
        case cell.greyButton:
            colour = UIColor(displayP3Red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
        default:
            print("default")
        }
        
        let tableCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! PodcastsForPlaylistCell
        let headerView = tableCell.subscriptionsTableView.headerView(forSection: 0) as! NewPlaylistHeaderView
        headerView.contentView.backgroundColor = colour
        colourSet = true
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

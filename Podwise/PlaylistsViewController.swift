//
//  FirstViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class PlaylistsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    struct PlaylistEpisodes {
        var name : CDPlaylist
        var episodes : [CDEpisode]
    }
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var episodesForPlaylists: [CDPlaylist: [CDEpisode]] = [CDPlaylist: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.fetchAllPodcasts(in: managedContext!)
        episodes = []
        for podcast in podcasts {
            let episodesForPodcast = CoreDataHelper.getEpisodesForPodcastWithNoPlaylist(podcast: podcast, in: managedContext!)
            for episode in episodesForPodcast {
                episodes.append(episode)
            }
        }
        
        episodesForPlaylists = [:]
        playlistStructArray = [PlaylistEpisodes]()
        playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
        
        misfitEpisodes = []
        for playlist in playlists {
            let podcastsForPlaylist = CoreDataHelper.fetchPodcastsFor(playlist: playlist, in: managedContext!)
            var episodesForPlaylist:[CDEpisode] = []
            for podcast in podcastsForPlaylist {
                var episodesForPodcastInPlaylist = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
                for podcastEpisode in episodesForPodcastInPlaylist {
                    if podcastEpisode.playlist != nil {
                        misfitEpisodes.append(podcastEpisode)
                    }
                }
                for episode in misfitEpisodes {
                    if episodesForPodcastInPlaylist.contains(episode) {
                        let index = episodesForPodcastInPlaylist.index(of: episode)
                        episodesForPodcastInPlaylist.remove(at: index!)
                    }
                }
                episodesForPlaylist.append(contentsOf: episodesForPodcastInPlaylist)
            }
            
            episodesForPlaylists[playlist] = episodesForPlaylist
        }
        
        // assign misfit episodes into their proper playlist
        for misfit in misfitEpisodes {
            episodesForPlaylists[misfit.playlist!]?.append(misfit)
        }
        
        for (key, value) in episodesForPlaylists {
            if value.count > 0 {
                playlistStructArray.append(PlaylistEpisodes(name: key, episodes: value))
            }
        }
        
        playlistStructArray.sort(by: { $0.name.sortIndex < $1.name.sortIndex})
        
        collectionView.backgroundColor = .black
        collectionView.backgroundView?.backgroundColor = .black
        
        collectionView.reloadData()
        
//        if !isTimerRunning {
//            runTimer()
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//    {
//        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Update action ...")
//            success(true)
//        })
//
//        let deleteEpisodeAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Delete action ...")
//            var cdEpisode: [CDEpisode]
//            if self.episodes.count > 0 {
//                if indexPath.section == 0 {
//                    cdEpisode = CoreDataHelper.getEpisodeWith(id: self.episodes[indexPath.row].id!, in: self.managedContext!)
//                } else {
//                    cdEpisode = CoreDataHelper.getEpisodeWith(id: self.playlistStructArray[indexPath.section-1].episodes[indexPath.row].id!, in: self.managedContext!)
//                }
//            } else {
//                cdEpisode = CoreDataHelper.getEpisodeWith(id: self.playlistStructArray[indexPath.section].episodes[indexPath.row].id!, in: self.managedContext!)
//            }
//            if cdEpisode.count > 0 {
//                do {
//                    let filemanager = FileManager.default
//                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
//                    let destinationPath = documentsPath.appendingPathComponent(cdEpisode[0].localURL!.lastPathComponent)
//                    if filemanager.fileExists(atPath: destinationPath) {
//                        try! filemanager.removeItem(atPath: destinationPath)
//                        tableView.beginUpdates()
//                        CoreDataHelper.delete(episode: cdEpisode[0], in: self.managedContext!)
//                        if self.episodes.count > 0 {
//                            self.playlistStructArray[indexPath.section-1].episodes.remove(at: indexPath.row)
//                        } else {
//                            self.playlistStructArray[indexPath.section].episodes.remove(at: indexPath.row)
//                        }
//                        tableView.deleteRows(at: [indexPath], with: .automatic)
//                        tableView.endUpdates()
//                    } else {
//                        print("not deleted, couldnt find file.")
//                    }
//                }
//            }
//            success(true)
//        })
//
//        deleteEpisodeAction.image = UIImage(named: "trash")
//        deleteEpisodeAction.backgroundColor = .red
//
//        addToPlaylistAction.image = UIImage(named: "playlist")
//        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
//
//        return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
//    }
    
//    func runTimer() {
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(checkDownloads)), userInfo: nil, repeats: true)
//    }
//
//    @objc func checkDownloads() {
//        tableView.reloadData()
//    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if destinationIndexPath.section == 0 {
            let movedObject = playlistStructArray[sourceIndexPath.row]
            playlistStructArray.remove(at: sourceIndexPath.row)
            playlistStructArray.insert(movedObject, at: destinationIndexPath.row)
            
            var sortIndex = 0
            for item in playlistStructArray {
                let thisPlaylist = CoreDataHelper.fetchAllPlaylists(with: item.name.id!, in: managedContext!)
                if thisPlaylist.count > 0 {
                    thisPlaylist[0].sortIndex = Int64(sortIndex)
                }
                
                item.name.sortIndex = Int64(sortIndex)
                CoreDataHelper.save(context: managedContext!)
                sortIndex += 1
            }
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if( originalIndexPath.section != proposedIndexPath.section )
        {
            return originalIndexPath;
        }
        else
        {
            return proposedIndexPath;
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return playlistStructArray.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            let height = CGFloat(playlistStructArray[indexPath.row].episodes.count * 80 + 55)
            return CGSize(width: collectionView.frame.width-16, height: height)
        } else {
            return CGSize(width: collectionView.frame.width-16, height: 75)
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
        print(playlistStructArray.count)
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath) as! GroupedViewCell
            
            cell.playlistGroupTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
            cell.playlistGroupTableView.frame = cell.bounds
            cell.playlistGroupTableView.episodesInPlaylist = playlistStructArray[indexPath.row].episodes
            cell.playlistGroupTableView.reloadPlaylist()
            
            cell.playlistGroupTableView.layer.cornerRadius = 15
            cell.playlistGroupTableView.layer.masksToBounds = true
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addPlaylistCell", for: indexPath) as! AddPlaylistCell
            
            cell.playlistButton.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
            cell.playlistButton.layer.cornerRadius = 25
            cell.playlistButton.layer.masksToBounds = true
            
            return cell
        }
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            let point: CGPoint = gesture.location(in: collectionView)
            var pointInCell: CGPoint?
            var cell: GroupedViewCell?
            if let indexPath: IndexPath = collectionView.indexPathForItem(at: point) {
                cell = (collectionView.cellForItem(at: indexPath) as! GroupedViewCell)
                pointInCell = cell?.convert(point, from: collectionView)
                
                if cell != nil && pointInCell != nil {
                    if (cell!.playlistGroupTableView.headerView(forSection: 0)?.frame.contains(pointInCell!))! {
                        if let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) {
                            self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
                        }
                    }
                }
            } else {
                print("long press on table view but not on a row");
            }
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            let point: CGPoint = gesture.location(in: collectionView)
            var pointInCell: CGPoint?
            var cell: GroupedViewCell?
            if let indexPath: IndexPath = collectionView.indexPathForItem(at: point) {
                if indexPath.section == 0 {
                    collectionView.endInteractiveMovement()
                } else {
                    collectionView.cancelInteractiveMovement()
                }
            }
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    @IBAction func addPlaylistButtonPressed(_ sender: Any) {
        
    }
}


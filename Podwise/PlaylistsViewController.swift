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
import MediaPlayer

public protocol relayoutSectionDelegate: class {
    func relayoutSection(row: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int)
    func reloadCollectionView()
}

//public protocol editPlaylistParentDelegate: class {
//    func edit(playlist: CDPlaylist)
//    func edit()
//}

public protocol editPlaylistDelegate: class {
    func edit(playlist: CDPlaylist)
    func edit()
}

class PlaylistsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, relayoutSectionDelegate, editPlaylistDelegate {
    
    struct PlaylistEpisodes {
        var name : CDPlaylist
        var episodes : [CDEpisode]
    }
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var headers: [PlaylistHeaderView] = []
    var episodesForPlaylists: [CDPlaylist: [CDEpisode]] = [CDPlaylist: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var sectionDragging = 0
    var episodesToAddBack = [CDEpisode]()
    var isDragging = false
    //var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        collectionView.dragInteractionEnabled = true
        
        self.transitioningDelegate = self
        
        //let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        //collectionView.addGestureRecognizer(longPressGesture)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
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
        
        headers = []
        
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
        
        //collectionView.backgroundColor = .black
        //collectionView.backgroundView?.backgroundColor = .black
        
        collectionView.reloadData()
//        if !isTimerRunning {
//            runTimer()
//        }
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        podcasts = []
//        episodes = []
//        misfitEpisodes = []
//        playlists = []
//        episodesForPlaylists = [:]
//        playlistStructArray = []
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    @objc func checkDownloads() {
//        tableView.reloadData()
//    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return playlistStructArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isDragging && section == sectionDragging {
            return 1
        } else {
            if section < playlistStructArray.count {
                if playlistStructArray[section].episodes.count == 0 {
                    return playlistStructArray[section].episodes.count
                } else {
                    return playlistStructArray[section].episodes.count + 1
                }
            } else {
                return 1
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            return CGSize(width: collectionView.frame.width-16, height: 50)
        } else {
            return CGSize(width: collectionView.frame.width-16, height: 80)
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
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isDragging && indexPath.section == sectionDragging {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderViewCell", for: indexPath as IndexPath) as! PlaylistHeaderView
            
            cell.editDelegate = self
            if let podcastPlaylist = episodesToAddBack[0].podcast?.playlist {
                cell.playlist = podcastPlaylist
                
                let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                
                cell.cellBackgroundView.backgroundColor = playlistColour as? UIColor
                
                cell.label.text = podcastPlaylist.name!
                if podcastPlaylist.name! == "Unsorted" {
                    cell.button.isHidden = true
                } else {
                    cell.button.isHidden = false
                }
            }
            
            cell.isUserInteractionEnabled = true
            
            headers.append(cell)
            
            // round top left and right corners
            let cornerRadius: CGFloat = 10
            let maskLayer = CAShapeLayer()
            
            maskLayer.path = UIBezierPath(
                roundedRect: cell.bounds,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                ).cgPath
            
            cell.layer.mask = maskLayer
            
            return cell
        } else {
            if indexPath.section < playlistStructArray.count {
                if indexPath.row == 0 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderViewCell", for: indexPath as IndexPath) as! PlaylistHeaderView
                    
                    cell.editDelegate = self
                    if playlistStructArray[indexPath.section].episodes.count > 0 {
                        if let podcastPlaylist = playlistStructArray[indexPath.section].episodes[0].podcast?.playlist {
                            cell.playlist = podcastPlaylist
                            
                            let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                            
                            cell.cellBackgroundView.backgroundColor = playlistColour as? UIColor
                            
                            cell.label.text = podcastPlaylist.name!
                            if podcastPlaylist.name! == "Unsorted" {
                                cell.button.isHidden = true
                            } else {
                                cell.button.isHidden = false
                            }
                        }
                        
                        cell.isUserInteractionEnabled = true
                        
                        headers.append(cell)
                        
                        // round top left and right corners
                        let cornerRadius: CGFloat = 10
                        let maskLayer = CAShapeLayer()
                        
                        maskLayer.path = UIBezierPath(
                            roundedRect: cell.bounds,
                            byRoundingCorners: [.topLeft, .topRight],
                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                            ).cgPath
                        
                        cell.layer.mask = maskLayer
                        
                        return cell
                    } else {
                        // Shouldnt ever hit this.
                        return UICollectionViewCell()
                    }
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCollectionViewCell
                    let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
                    cell.titleLabel.text = thisEpisode.title
                    
                    var hours = 0
                    var minutes = 0
                    if let optionalHours = Int(thisEpisode.duration!) {
                        hours = (optionalHours/60)/60
                    }  else {
                        print(thisEpisode.duration!)
                        let durationArray = thisEpisode.duration?.split(separator: ":")
                        if let optionalHours = Int(durationArray![0]) {
                            hours = optionalHours
                        }
                    }
                    if let optionalMinutes = Int(thisEpisode.duration!) {
                        minutes = (optionalMinutes/60)%60
                    }  else {
                        let durationArray = thisEpisode.duration!.split(separator: ":")
                        if let optionalMinutes = Int(durationArray[1]) {
                            minutes = optionalMinutes
                        }
                    }
                    
                    cell.titleLabel.text = thisEpisode.title
                    cell.durationLabel.text = thisEpisode.subTitle
                    if hours == 0 && minutes == 0 {
                        cell.durationLabel.text = ""
                    } else if hours == 0 {
                        cell.durationLabel.text = "\(minutes)m"
                    } else {
                        cell.durationLabel.text = "\(hours)h \(minutes)m"
                    }
                    
                    DispatchQueue.main.async {
                        if let imageData = thisEpisode.podcast?.image {
                            cell.artImageView.image = UIImage(data: imageData)
                        }
                        
                        cell.artImageView.layer.cornerRadius = 10
                        cell.artImageView.layer.masksToBounds = true
                        cell.activityIndicator.isHidden = true
                    }
                    
                    if downloads != nil {
                        for download in downloads {
                            if download.episode == thisEpisode {
                                cell.activityIndicator.startAnimating()
                                cell.activityIndicator.isHidden = false
                                cell.isUserInteractionEnabled = false
                                break
                            } else {
                                cell.activityIndicator.isHidden = true
                                cell.activityIndicator.stopAnimating()
                                cell.isUserInteractionEnabled = true
                            }
                        }
                    }
                    
                    if indexPath.row == playlistStructArray[indexPath.section].episodes.count {
                        // round top left and right corners
                        let cornerRadius: CGFloat = 10
                        let maskLayer = CAShapeLayer()
                        
                        maskLayer.path = UIBezierPath(
                            roundedRect: cell.bounds,
                            byRoundingCorners: [.bottomLeft, .bottomRight],
                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                            ).cgPath
                        
                        cell.layer.mask = maskLayer
                    }
                    
                    return cell
                }
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addPlaylistCell", for: indexPath) as! AddPlaylistCell
                
                cell.playlistButton.backgroundColor = UIColor.white
                cell.playlistButton.layer.cornerRadius = 15
                cell.playlistButton.layer.masksToBounds = true
                cell.editDelegate = self
                
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
            let podcast = thisEpisode.podcast!
            if nowPlayingEpisode != nil {
                nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
            }
            CoreDataHelper.save(context: managedContext)
            nowPlayingEpisode = thisEpisode
            let nowPlayingImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
            baseViewController.miniPlayerView.artImageView.image = nowPlayingImage
            baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
            playDownload(for: thisEpisode)
        }
    }
    
    func playDownload(for episode: CDEpisode) {
        startAudioSession()
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.localURL!.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            startAudioSession()
            player.play()
            
            let artworkImage = UIImage(data: episode.podcast!.image!)
            let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
                return artworkImage!
            })
            
            let mpic = MPNowPlayingInfoCenter.default()
            mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:episode.title!,
                                   MPMediaItemPropertyArtist:episode.podcast!.title!,
                                   MPMediaItemPropertyArtwork: artwork,
                                   MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                                   MPMediaItemPropertyPlaybackDuration: player.duration
            ]
            
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startAudioSession() {
        // set up background audio capabilities
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault, options: .interruptSpokenAudioAndMixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try audioSession.setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
//    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
//        switch(gesture.state) {
//        case .began:
//            let point: CGPoint = gesture.location(in: collectionView)
//
//            var index = 0
//            for header in headers {
//                if header.frame.contains(point) {
//                    print("YOU ARE PRESSING: \(header.playlist.name!)")
//                    collectionView.beginInteractiveMovementForItem(at: IndexPath(row: 0, section: index))
//
//                    let numberOfEpisodes = playlistStructArray[index].episodes.count
////                    for episodeNumber in 0...numberOfEpisodes-1 {
////                        let thisCell = collectionView.cellForItem(at: IndexPath(row: episodeNumber+1, section: index))
////                        thisCell?.isHidden = true
////                    }
//                }
//                index += 1
//                return
//            }
////            if let indexPath: IndexPath = collectionView.indexPathForItem(at: point) {
////                print("\(indexPath.row) \(indexPath.section)")
////                if indexPath.section == 0 {
//
//
////                    cell = (collectionView.cellForItem(at: indexPath) as! PlaylistHeaderView)
////                    pointInCell = cell?.convert(point, from: collectionView)
////
////                    if cell != nil && pointInCell != nil {
////                        if (pointInCell?.y)! < CGFloat(50) {
////                            if let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) {
////                                self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
////                            }
////                        }
////                    }
////                }
////            } else {
////                print("long press on table view but not on a row");
////            }
//        case .changed:
//            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
//        case .ended:
//            let point: CGPoint = gesture.location(in: collectionView)
//            if let indexPath: IndexPath = collectionView.indexPathForItem(at: point) {
//                if indexPath.section == 0 {
//                    collectionView.endInteractiveMovement()
//                } else {
//                    collectionView.cancelInteractiveMovement()
//                }
//            }
//            collectionView.endInteractiveMovement()
//        default:
//            collectionView.cancelInteractiveMovement()
//        }
//    }
    
    func relayoutSection(row: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int) {
        if playlistStructArray[row].episodes.contains(deleted) {
            let indexToDelete = playlistStructArray[row].episodes.index(of: deleted)
            playlistStructArray[row].episodes.remove(at: indexToDelete!)
            
            if episodesInPlaylist == 0 {
                playlistStructArray.remove(at: row)
                collectionView.deleteItems(at: [IndexPath(row: row, section: 0)])
                return
            }
            
            collectionView.reloadItems(at: [IndexPath(row: row, section: 0)])
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: collectionView.layoutSubviews, completion: nil)
        }
    }
    
    func reloadCollectionView() {
        viewDidLoad()
    }
    
    func edit(playlist: CDPlaylist) {
        // Safe Push VC
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playlistCreationViewController") as? PlaylistCreationTableViewController {
            
            viewController.playlist = playlist
            viewController.transitioningDelegate = self
            viewController.modalPresentationStyle = .custom
            viewController.relayoutSectionDelegate = self
            
            navigationController?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func edit() {
        // Safe Push VC
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playlistCreationViewController") as? PlaylistCreationTableViewController {
          
            viewController.transitioningDelegate = self
            viewController.modalPresentationStyle = .custom
            viewController.relayoutSectionDelegate = self
            
            navigationController?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentation = PresentationController.init(presentedViewController: presented, presenting: presenting)
        
        return presentation;
    }
    
    // MARK: collection view Drag and Drop Delegate methods
    
    // Drag
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var item: String
        if indexPath.row == 0 && indexPath.section != playlistStructArray.count {
            sectionDragging = indexPath.section
            item = playlistStructArray[indexPath.section].name.name!
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            isDragging = true
            
            // remove dragging items
            collectionView.performBatchUpdates({
                var indicesToRemove: [IndexPath] = []
                var index = 1
                for episode in playlistStructArray[sectionDragging].episodes {
                    episodesToAddBack.append(episode)
                    indicesToRemove.append(IndexPath(row: index, section: sectionDragging))
                    index += 1
                }
                playlistStructArray[sectionDragging].episodes = []
                
                collectionView.deleteItems(at: indicesToRemove)
            })
            
            return [dragItem]
        } else {
            return []
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
//        var item: String
//        if indexPath.row == 0 {
//            item = playlistStructArray[indexPath.section].name.name!
//        } else {
//            item = playlistStructArray[indexPath.section].episodes[indexPath.row-1].title!
//        }
//        let itemProvider = NSItemProvider(object: item as NSString)
//        let dragItem = UIDragItem(itemProvider: itemProvider)
//        dragItem.localObject = item
//        return [dragItem]
//    }
    
    // Drop
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil
        {
            if collectionView.hasActiveDrag
            {
                if destinationIndexPath != nil {
                    if destinationIndexPath!.section < playlistStructArray.count {
                        //if destinationIndexPath!.row < playlistStructArray[destinationIndexPath!.section].episodes.count {
                        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
                        //} else {
                        //    return UICollectionViewDropProposal(operation: .forbidden)
                        //}
                    } else {
                        return UICollectionViewDropProposal(operation: .forbidden)
                    }
                } else {
                    return UICollectionViewDropProposal(operation: .forbidden)
                }
            }
            else
            {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
        else
        {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        isDragging = false
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath
        {
            destinationIndexPath = indexPath
        }
        else
        {
            // Get index path of original playlist
            destinationIndexPath = IndexPath(row: 0, section: playlistStructArray.count)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            // remove dragging items
            let indexSetToDelete = NSMutableIndexSet()
            indexSetToDelete.add(sectionDragging)
            
            let indexSetToAdd = NSMutableIndexSet()
            indexSetToAdd.add(destinationIndexPath.section)
            
            collectionView.performBatchUpdates({
                // remove dragged section
                //let sectionToInsert = playlistStructArray[sectionDragging]
                
                playlistStructArray.remove(at: sectionDragging)
                collectionView.deleteSections(indexSetToDelete as IndexSet)

                let playlistEpisodesToInsert = PlaylistEpisodes(name: episodesToAddBack[0].podcast!.playlist!, episodes: episodesToAddBack)
                playlistStructArray.insert(playlistEpisodesToInsert, at: destinationIndexPath.section)
                
                // add in dropped section
                //playlistStructArray.insert(sectionToInsert, at: destinationIndexPath.section)
                collectionView.insertSections(indexSetToAdd as IndexSet)
                
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
            })
            episodesToAddBack = []
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0)
            {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            let item = coordinator.items[0]
            coordinator.drop(item.dragItem, toItemAt: dIndexPath)
//            let indexSetToReload = NSMutableIndexSet()
//            indexSetToReload.add(indexSetToAdd as IndexSet)
//            indexSetToReload.add(indexSetToDelete as IndexSet)
            
            //collectionView.reloadSections(indexSetToReload as IndexSet)
            break
        case .copy:
            //Add the code to copy items
            break
            
        default:
            sectionDragging = nil
            return
        }
    }
}


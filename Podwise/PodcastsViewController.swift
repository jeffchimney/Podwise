//
//  SecondViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

public protocol reloadCollectionViewDelegate: class {
    func reloadCollectionView()
}

class PodcastsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate, reloadCollectionViewDelegate {
    
    var subscribedPodcasts: [CDPodcast] = []
    var unSubscribedPodcasts: [CDPodcast] = []
    var managedContext: NSManagedObjectContext?
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if( traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        subscribedPodcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        subscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        let unSubscribedPodcastsUnfiltered = CoreDataHelper.getPodcastsWhere(subscribed: false, in: managedContext!)
        unSubscribedPodcasts = []
        for podcast in unSubscribedPodcastsUnfiltered {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            if episodesForPodcast.count > 0 {
                unSubscribedPodcasts.append(podcast)
            }
        }
        unSubscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        collectionView.reloadData()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionGroupCell", for: indexPath) as! SubscriptionCell
        
        cell.subscriptionsTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
        cell.subscriptionsTableView.frame = cell.bounds
        if indexPath.row == 0 {
            cell.subscriptionsTableView.podcasts = subscribedPodcasts
            cell.subscriptionsTableView.subscribed = true
        } else {
            cell.subscriptionsTableView.podcasts = unSubscribedPodcasts
            cell.subscriptionsTableView.subscribed = false
        }
        cell.subscriptionsTableView.rowInTableView = indexPath.row
        cell.subscriptionsTableView.previousViewController = self
        cell.subscriptionsTableView.reloadData()
        
        cell.contentView.layer.cornerRadius = 15
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 1.0
        cell.layer.shadowOpacity = 0.75
        cell.layer.shadowOffset = CGSize.zero
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            let height = CGFloat(subscribedPodcasts.count * 80 + 50)
            return CGSize(width: collectionView.frame.width-16, height: height)
        } else {
            let height = CGFloat(unSubscribedPodcasts.count * 80 + 50)
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
    
    
//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//    {
//
//        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Adding to playlist...")
//            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
//
//            let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
//
//            for eachPlaylist in playlists {
//                alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
//                    //execute some code when this option is selected
//                    if indexPath.section == 0 {
//                        self.add(podcast: self.subscribedPodcasts[indexPath.row], to: eachPlaylist)
//                    } else {
//                        self.add(podcast: self.unSubscribedPodcasts[indexPath.row], to: eachPlaylist)
//                    }
//                }))
//            }
//
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            self.present(alert, animated: true, completion: nil)
//            success(true)
//        })
//
//        addToPlaylistAction.image = UIImage(named: "playlist")
//        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
//
//        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
//    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    // MARK: - Preview Delegate Methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = collectionView.convert(location, from: self.view)
        
        guard let indexPath = collectionView.indexPathForItem(at: cellPosition),
            let cell = (collectionView.cellForItem(at: indexPath) as? SubscriptionCell) else {
                return nil
        }
        
        let subCellPosition = cell.subscriptionsTableView.convert(location, from: self.view)
        
        guard let subIndexPath = cell.subscriptionsTableView.indexPathForRow(at: subCellPosition),
            let subCell = (cell.subscriptionsTableView.cellForRow(at: subIndexPath) as? PlaylistCell) else {
                return nil
        }
        
        guard let targetViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "episodesViewController") as?
            EpisodesForPodcastViewController else {
                return nil
        }
        
        var selectedPodcast: CDPodcast!
        if indexPath.section == 0 {
            selectedPodcast = subscribedPodcasts[subIndexPath.row]
        } else {
            selectedPodcast = unSubscribedPodcasts[subIndexPath.row]
        }
        
        targetViewController.podcast = selectedPodcast
        targetViewController.reloadCollectionViewDelegate = self
        targetViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(subCell.frame, to: cell.subscriptionsTableView)
        
        return targetViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func reloadCollectionView() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        subscribedPodcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        subscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        let unSubscribedPodcastsUnfiltered = CoreDataHelper.getPodcastsWhere(subscribed: false, in: managedContext!)
        unSubscribedPodcasts = []
        for podcast in unSubscribedPodcastsUnfiltered {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            if episodesForPodcast.count > 0 {
                unSubscribedPodcasts.append(podcast)
            }
        }
        unSubscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        DispatchQueue.main.async() {
            self.collectionView.reloadData()
        }
    }
}


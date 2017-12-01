//
//  SecondViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

public protocol reloadTableViewDelegate: class {
    func reloadTableView()
}

class PodcastsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate, reloadTableViewDelegate {
    
    var subscribedPodcasts: [CDPodcast] = []
    var unSubscribedPodcasts: [CDPodcast] = []
    var managedContext: NSManagedObjectContext?

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.dataSource = self
        tableView.delegate = self
        
        if( traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        navigationController?.setNavigationBarHidden(true, animated: true)
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
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subscribedPodcasts.count
        } else {
            return unSubscribedPodcasts.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var podcastListForSection: [CDPodcast] = []
        if indexPath.section == 0 {
            podcastListForSection = subscribedPodcasts
        } else {
            podcastListForSection = unSubscribedPodcasts
        }
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "PodcastCell", for: indexPath as IndexPath) as! PodcastListCell
        
        cell.titleLabel.text = podcastListForSection[indexPath.row].title
        cell.authorLabel.text = podcastListForSection[indexPath.row].author
        if let imageData = podcastListForSection[indexPath.row].image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var podcastListForSection: [CDPodcast] = []
        if indexPath.section == 0 {
            podcastListForSection = subscribedPodcasts
        } else {
            podcastListForSection = unSubscribedPodcasts
        }
        
        let podcast: CDPodcast = podcastListForSection[indexPath.row]
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "episodesViewController") as! EpisodesForPodcastViewController
        resultViewController.podcast = podcast
        self.navigationController?.pushViewController(resultViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return  "Subscribed"
        } else {
            return  "Not Subscribed"
        }
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {

        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Adding to playlist...")
            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
            
            let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
            
            for eachPlaylist in playlists {
                alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                    //execute some code when this option is selected
                    if indexPath.section == 0 {
                        self.add(podcast: self.subscribedPodcasts[indexPath.row], to: eachPlaylist)
                    } else {
                        self.add(podcast: self.unSubscribedPodcasts[indexPath.row], to: eachPlaylist)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            success(true)
        })
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    // MARK: - Preview Delegate Methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = tableView.cellForRow(at: indexPath) else {
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
            selectedPodcast = subscribedPodcasts[indexPath.row]
        } else {
            selectedPodcast = unSubscribedPodcasts[indexPath.row]
        }
        
        targetViewController.podcast = selectedPodcast
        targetViewController.reloadTableViewDelegate = self
        targetViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
        
        return targetViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    func reloadTableView() {
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
            self.tableView.reloadData()
        }
    }
}


//
//  BrowseViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class BrowseViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarBottomConstraint: NSLayoutConstraint!
    var podcastResults: [[String: Any]] = []
    var searchBarBottomConstraintInitialValue: CGFloat = 0
    var feedURL: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        searchBarBottomConstraintInitialValue = searchBarBottomConstraint.constant
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        iTunesSearch(term: searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration) { () -> Void in
            self.searchBarBottomConstraint.constant = 85-keyboardFrame.height
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration) { () -> Void in
            self.searchBarBottomConstraint.constant = self.searchBarBottomConstraintInitialValue
            self.view.layoutIfNeeded()
        }
    }
    
    //
    func iTunesSearch (term: String) {
        // replace spaces with + symbol.
        let iTunesTerm = term.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.caseInsensitive, range: nil)
        // anything that is URL friendly should be escaped
        let escapedTerm = iTunesTerm.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        //stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let path = "https://itunes.apple.com/search?term=\(escapedTerm ?? "")&media=podcast"
        let url: URL = URL(string: path)!
        let request: URLRequest = URLRequest(url: url)//NSURLRequest(URL: url as URL)
        let session: URLSession = URLSession.shared // NSURLConnection(request: rqst, delegate: self, startImmediately: false)!
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.ctnFinishedLoading(data: data!)
        })
        print("URL for searching iTunes API \(url)")
        task.resume()
    }
    

    func ctnFinishedLoading(data: Data) {
        // self.d should hold the resulting info, request is complete
        // received data is converted into an object through JSON deserialization
        do {
            let jResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
            let results = jResult["results"] as! [[String: Any]]
            if jResult.count > 0 && results.count > 0 {
                print(results)
                self.podcastResults = results
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        } catch {
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcastResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! PodcastCell
        let rowData: [String: Any] = self.podcastResults[indexPath.row]
        print(rowData)
        cell.titleLabel.text = rowData["trackName"] as? String
        cell.descriptionLabel.text = rowData["artistName"] as? String
        cell.collectionID = rowData["collectionId"] as? String
        let urlString: String = rowData["artworkUrl60"] as! String
        let url: URL = URL(string: urlString)!
        let request: URLRequest = URLRequest(url: url)
        let session: URLSession = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            // Download representation of the image as NSData at the URL
            do {
                let imageData: Data = try Data.init(contentsOf: url, options: .mappedIfSafe)
                DispatchQueue.main.async {
                    cell.artImageView.image = UIImage(data: imageData)
                }
            } catch {
                print("Could not load art thumbnail")
            }
        })
        print("URL for searching iTunes API \(url)")
        task.resume()
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowData: [String: Any] = self.podcastResults[indexPath.row]
        feedURL = rowData["feedUrl"] as! String
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "resultViewController") as! PodcastHistoryViewController
        resultViewController.feedURL = feedURL
        resultViewController.collectionID = rowData["collectionId"] as! Int
        self.navigationController?.pushViewController(resultViewController, animated: true)
    }
}

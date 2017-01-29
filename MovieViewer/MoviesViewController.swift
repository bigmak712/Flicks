//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Timothy Mak on 1/12/17.
//  Copyright © 2017 Timothy Mak. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class InfiniteScrollActivityView: UIView {
    var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    static let defaultHeight:CGFloat = 60.0
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        setupActivityIndicator()
    }
    
    override init(frame aRect: CGRect){
        super.init(frame: aRect)
        setupActivityIndicator()
    }
    
    override func layoutSubviews(){
        super.layoutSubviews()
        activityIndicatorView.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
    }
    
    func setupActivityIndicator(){
        activityIndicatorView.activityIndicatorViewStyle = .gray
        activityIndicatorView.hidesWhenStopped = true
        self.addSubview(activityIndicatorView)
    }
    
    func stopAnimating(){
        self.activityIndicatorView.stopAnimating()
        self.isHidden = true
    }
    
    func startAnimating(){
        self.isHidden = false
        self.activityIndicatorView.startAnimating()
    }
}

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    
    // checks for loading data in scrollViewDidScroll
    var isMoreDataLoading = false

    var loadingMoreView:InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        // Add refresh control to table view
        tableView.insertSubview(refreshControl, at: 0)
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        networkRequest()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(refreshControl: UIRefreshControl){
        
        // ... Create the NSURLRequest (myRequest) ...
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let myRequest = NSURLRequest(url: url as URL)
        
        loadingMoreView?.center = self.view.center

        
        //Configure session so that completion handler is executed on main UI thread
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: myRequest as URLRequest, completionHandler: { (data, response, error) in
            
            if let responseData = data {
                // ... Use the new data to update the data source ...
                if let responseDictionary = try! JSONSerialization.jsonObject(                                                                                with: responseData, options:[]) as? NSDictionary {
                    
                    // Add the loaded movies to the movies array
                    if let responseDictionary = responseDictionary["results"] as? [NSDictionary] {
                        self.movies = responseDictionary
                    }
                }
            }
            
            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
            
            // Tell the refreshControl to stop spinning
            refreshControl.endRefreshing()
        });
        task.resume()
    }
    
    func loadMoreData(){
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let myRequest = NSURLRequest(url: url as URL)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue: OperationQueue.main)
        
        let task : URLSessionDataTask = session.dataTask(with: myRequest as URLRequest, completionHandler: { (data, response, error) in
            
            // Update flag
            self.isMoreDataLoading = false
            
            // Stop the loading indicator
            self.loadingMoreView!.stopAnimating()
            
            // ... Use the new data to update the data source ...
            if let responseData = data {
                // ... Use the new data to update the data source ...
                if let responseDictionary = try! JSONSerialization.jsonObject(                                                                                with: responseData, options:[]) as? NSDictionary {
                    
                    assert((self.movies != nil))
                    
                    // Get the 'response' field
                    let responseFieldDictionary = responseDictionary["response"] as? NSDictionary
                    
                    // Add the loaded movies to the movies array
                    if let responseDictionary = responseFieldDictionary?["posts"] as? [NSDictionary] {
                        self.movies!.append(contentsOf: responseDictionary)
                    }
                }
            }

            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
        });
        task.resume()
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(!isMoreDataLoading){
            
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging){
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView?.center = self.view.center
                loadingMoreView!.startAnimating()
                
                // Code to load more results
                loadMoreData()
                
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if let movies = movies {
            return movies.count
        }
        else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let baseUrl = "https://image.tmdb.org/t/p/w500"
        
        if let posterPath = movie["poster_path"] as? String{
            let posterUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWith(posterUrl as! URL)
        }
        
        return cell
    }

    func networkRequest(){
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            // Hide HUD once the network request comes back (must be done on main UI thread)
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    self.movies = (dataDictionary["results"] as! [NSDictionary])
                    self.tableView.reloadData()
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}

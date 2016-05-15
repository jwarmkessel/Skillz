//
//  ViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 9/11/15.
//  Copyright © 2015 Justin Warmkessel, Inc. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

extension Float {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
    
    var radiansToDegrees : CGFloat {
        return CGFloat(self) * 180.0 / CGFloat(M_PI)
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, VideoCellDelegate {
  
    let feedPlayer : AVPlayer = AVPlayer()
    
    let recordViewController : RecordViewController = RecordViewController()
    
    @IBOutlet weak var tableView: UITableView!
 
    let kEstimatedRowHeight : CGFloat = 600.0
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    var model : FeedModel?
    var tempVisibleCells : [UITableViewCell?]?
    
    //MARK: VideoCellDelegate
    func tryLessonButtonHandlerTapped(videoCell: VideoCell) {
        videoCell.player?.pause()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("recordViewController") as! RecordViewController
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    //MARK: ScrollViewDelegate
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        
//        print(self.tableView.visibleCells.count)
//        if let videoCell : VideoCell? = self.tableView.visibleCells.first as? VideoCell {
//            
//            let cellHeight = videoCell?.contentView.frame.size.height
//            print(cellHeight)
//            
//            let tableViewOffsetIncludingHeader = self.tableView.contentOffset.y + 64.0
//            print(tableViewOffsetIncludingHeader)
//            
//            if (tableViewOffsetIncludingHeader % 457 == 0) {
//                videoCell?.player?.pause()
//            }
//        }
//    }
    
//    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
//        
//    }
    
    //MARK: UIViewController
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureTableView()
        self.view.userInteractionEnabled = true
        self.tableView.userInteractionEnabled = true
        self.configureNavigationBar()
        
        guard let feedModel = self.model else {
            return
        }

        feedModel.videos?.removeAll()
        feedModel.updateVideos()
        self.tableView.reloadData()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.navigationController?.navigationBarHidden = true
        self.model = FeedModel.init()
    }
    
    func configureNavigationBar() {
        guard let navController = self.navigationController else {
            return
        }
        
        navController.navigationBar.barTintColor = UIColor(red: 255.0/255.0, green: 69.0/255.0, blue: 0, alpha: 1.0)
        navController.navigationBar.barStyle = UIBarStyle.Black
        navController.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    //MARK: Convenience methods
    func configureTableView() {
        self.tableView.delegate             = self
        self.tableView.dataSource           = self
        self.tableView.estimatedRowHeight   = kEstimatedRowHeight
        self.tableView.rowHeight            = UITableViewAutomaticDimension
    }
    
    //MARK: UITableViewDatasource
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 600.0
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if isLandscapeOrientation() {
//            return hasImageAtIndexPath(indexPath) ? 140.0 : 120.0
//        } else {
//            return hasImageAtIndexPath(indexPath) ? 235.0 : 155.0
//        }
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        self.stopNonVisibleVideoCellMediaSession(tableView, willDisplayCell: cell, indexPath: indexPath)
    }
    
    func stopNonVisibleVideoCellMediaSession(tableView: UITableView, willDisplayCell cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let visibleCells = self.tempVisibleCells else {
            self.tempVisibleCells = self.tableView.visibleCells
            return
        }
        
        for (_, element) in visibleCells.enumerate() {
            if let visible : [VideoCell]? = self.tableView.visibleCells as? [VideoCell], let visibleCellsNonOptional = visible {
                for videoCell: VideoCell in visibleCellsNonOptional {
                    
                    var found : Bool = false
                    
                    if (videoCell == element) {
                        found = true
                    }
                    
                    if (!found) {
                        //Take the videoCell and stop it.
                    }
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if let model = self.model, let videos = model.videos {
            count = videos.count
        }
        
        return count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (self.model?.sections.count)!
    }
  
    
    func urlForVideo(fileName: String) -> NSURL? {
        
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "mp4")
        
        if let path = path {
            return NSURL(fileURLWithPath:path)
        } else {
            return nil
        }
        
        /* this would also work, it's a matter of taste :
        if let path = NSBundle.mainBundle().pathForResource(filename, ofType: "m4a") {
        return NSURL(fileURLWithPath:path)
        }
        return nil
        */
        
    }
    
    func tableView(tableView: UITableView,
                   didEndDisplayingCell cell: UITableViewCell,
                                        forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let videoCell : VideoCell = cell as? VideoCell {
            if var player : AVPlayer? = videoCell.player {
                player = nil
                
                if (player == nil) {
                    //print("Player is niled")
                }
            }
            
            if let sublayers = videoCell.videoImageView.layer.sublayers {
                for layer in sublayers {
                    if layer.isKindOfClass(AVPlayerLayer) {
                        print("Removing layer")
                        layer.removeFromSuperlayer()
                    }
                }
            }
        }
    }
    
    func configureVideoCell(cell : VideoCell, indexPath : NSIndexPath) -> VideoCell {

        cell.topLineDecoration.backgroundColor = indexPath.row != 0 ? UIColor.lightGrayColor() : cell.topLineDecoration.backgroundColor
        cell.topLineDecoration.alpha = 0.8
        cell.temporaryText?.text = "Create video content"
        cell.selectionStyle = .None
        cell.delegate = self
        
        cell.detailLabel.text = indexPath.row == 0 ? "Tap the button on the right." : ""
        
        var isDir = ObjCBool(false)

        if let model = self.model,
            let vid = model.videos,
            let obj : AnyObject? = vid[indexPath.row],
            let vidName = obj as? String {
            
            let videoPath = documentsURL.path! + "/" + vidName
            
            if NSFileManager.defaultManager().fileExistsAtPath(videoPath, isDirectory: &isDir) {
                
                let pathURL = NSURL.fileURLWithPath(videoPath)
    
                //TODO hook up to retrieveCurrentPlayerItem(contentPath : String)
                //cell.player = self.feedPlayer.replaceCurrentItemWithPlayerItem(<#T##item: AVPlayerItem?##AVPlayerItem?#>)
                cell.player = AVPlayer(URL: pathURL)
                
                let playerLayer = AVPlayerLayer(player: cell.player)
        
                playerLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI)/2.0))
                let height : CGFloat = CGRectGetHeight(cell.videoImageView.layer.frame)
                let width : CGFloat = CGRectGetWidth(cell.videoImageView.layer.frame)
                let rect : CGRect = CGRectMake(0.0, 0.0, width, height)
                
                playerLayer.frame = rect
                
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                
                cell.videoImageView.layer.addSublayer(playerLayer)

                NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: cell.player?.currentItem, queue: nil, usingBlock: { (NSNotification) -> Void in
                    
                    cell.player?.currentItem?.seekToTime(kCMTimeZero)
                    cell.player?.play()
                })
                
                //cell.player?.seekToTime(kCMTimeZero)
                cell.player?.play()
                cell.player?.muted = true;
            }
        }
        
        return cell
    }
    
    func handsfreeTap(gesture: UITapGestureRecognizer) {
        let indexPath = NSIndexPath(forRow: gesture.view!.tag, inSection: 0)
        let cell : VideoCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? VideoCell)!

        if (cell.player?.rate == 0.0)
        {
            cell.player?.play()
            cell.player?.muted = false;
        }
        else
        {
            cell.player?.pause()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell : VideoCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? VideoCell)!
        
        if (cell.player?.rate == 0.0)
        {
            cell.player?.play()
        }
        else
        {
            cell.player?.pause()
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell?
        
        if let model = self.model, let vid = model.videos, let obj : AnyObject? = vid[indexPath.row] {
            
            // Valid video
            if let _ = obj as? String {
                
                //TODO:Check if valid .mp4
                let videoCell : VideoCell? = tableView.dequeueReusableCellWithIdentifier("videoCell", forIndexPath: indexPath) as? VideoCell
                
                if let vidCell = videoCell {
                    cell = self.configureVideoCell(vidCell, indexPath: indexPath)
                }
            
            // No Content, Error
            } else if let dictionary : NSDictionary = obj as? NSDictionary {
                if let message : String? = dictionary.objectForKey("message") as? String {
                    cell = UITableViewCell()
                    cell?.textLabel?.text = message
                    cell?.textLabel?.textAlignment = .Center
                }
            }
        }
        
        guard let validCell = cell else {
            return UITableViewCell()
        }
        
        return validCell;
    }
}

extension ViewController: CaptureVideoDelegate {
    
    func didCaptureVideo(recordViewController: RecordVideoViewController) {
        
        if let model = self.model {
            
            model.videos = model.pathsForAllVideos()
            self.tableView.reloadData()
        }
    }
}

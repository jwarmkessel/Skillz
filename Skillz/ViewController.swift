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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
    let recordViewController : RecordViewController = RecordViewController()
    
    @IBOutlet weak var tableView: UITableView!
 
    let kEstimatedRowHeight : CGFloat = 600.0
    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    var model : FeedModel?
    var tempVisibleCells : [UITableViewCell?]?
    
    //MARK: ScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        print(self.tableView.visibleCells.count)
        if let videoCell : VideoCell? = self.tableView.visibleCells.first as? VideoCell {
            
            let cellHeight = videoCell?.contentView.frame.size.height
            print(cellHeight)
            
            let tableViewOffsetIncludingHeader = self.tableView.contentOffset.y + 64.0
            print(tableViewOffsetIncludingHeader)
            
            if (tableViewOffsetIncludingHeader % 457 == 0) {
                videoCell?.player?.pause()
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func configureVideoCell(cell : VideoCell, indexPath : NSIndexPath) -> VideoCell {
        cell.temporaryText?.text = "Create video content"
        cell.selectionStyle = .None
        
        var isDir = ObjCBool(false)

        if let model = self.model,
            let vid = model.videos,
            let obj : AnyObject? = vid[indexPath.row],
            let vidName = obj as? String {
            
            let videoPath = documentsURL.path! + "/" + vidName
            
            if NSFileManager.defaultManager().fileExistsAtPath(videoPath, isDirectory: &isDir) {
                
                let pathURL = NSURL.fileURLWithPath(videoPath)
                
                if (cell.player == nil) {
                    cell.player = AVPlayer(URL: pathURL)
                    
                    if let avPlayer = cell.player {    
                        let playerLayer = AVPlayerLayer(player: avPlayer)
                        
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                        playerLayer.frame = cell.videoImageView.bounds
                        
                        let half : CGFloat = 2.0
                        
                        cell.videoImageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/half);
                        cell.videoImageView.layer.addSublayer(playerLayer)
                        cell.setNeedsLayout()
                        cell.setNeedsDisplay()
                        
                        NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: cell.player?.currentItem, queue: nil, usingBlock: { (NSNotification) -> Void in
                            
                            cell.player?.currentItem?.seekToTime(kCMTimeZero)
                            cell.player?.play()
                        })
                        
                        avPlayer.play()
                    }
                }
                else {
                    cell.player?.seekToTime(kCMTimeZero)
                    cell.player?.play()
                }
            }
        }
        
        return cell
    }
    
    //FIXME: THIS IS NOT BEING USED.
    func videoCellInstructions(player: AVPlayerItem, asset: AVAsset) -> AVMutableVideoComposition? {
        //See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
        
        
        
        let mainInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
        
        
        if let compTrack1 = asset.tracks.first as? AVMutableCompositionTrack {
            let firstLayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compTrack1)

            var scale : CGAffineTransform = CGAffineTransformMakeScale(0.7,0.7)
            var move : CGAffineTransform = CGAffineTransformMakeTranslation(230,230)
            
            firstLayerInstruction.setTransform(CGAffineTransformConcat(scale, move), atTime: kCMTimeZero)
            
            //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
            do {
                
                try compTrack1.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack:compTrack1.asset!.tracksWithMediaType(AVMediaTypeVideo).first!, atTime: kCMTimeZero)
            } catch {
                print("annoying")
            }
            
            if let compTrack2 = asset.tracks.last as? AVMutableCompositionTrack {
                
                let secondLayerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compTrack1)
                
                scale = CGAffineTransformMakeScale(1.2,1.5)
                move = CGAffineTransformMakeTranslation(0,0)
                
                secondLayerInstruction.setTransform(CGAffineTransformConcat(scale, move), atTime: kCMTimeZero)
                
                //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
                do {
                    
                    try compTrack2.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack:compTrack2.asset!.tracksWithMediaType(AVMediaTypeVideo).first!, atTime: kCMTimeZero)
                } catch {
                    print("annoying")
                }
            
                //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
                mainInstruction.layerInstructions = [firstLayerInstruction, secondLayerInstruction]
                
                //Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
                let mainCompositionInst : AVMutableVideoComposition  = AVMutableVideoComposition()
                
                mainCompositionInst.instructions = [mainInstruction]
                mainCompositionInst.frameDuration = CMTimeMake(1, 30)
                mainCompositionInst.renderSize = CGSizeMake(640, 480)
                
                return mainCompositionInst
                
            }
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("recordViewController") as! RecordViewController
        self.presentViewController(vc, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if (segue.identifier == "videoHomework") {
//
//            let row = self.tableView.indexPathForSelectedRow?.row
//                
//            if let model = self.model, let vid = model.videos, let _ : AnyObject? = vid[row!] {
//                
//                
//                if let vidName : String = vid[row!] as? String {
//                    
//                    let videoPath = documentsURL.path! + "/" + vidName
//                    
//                    var isDir = ObjCBool(false)
//                    
//                    if NSFileManager.defaultManager().fileExistsAtPath(videoPath, isDirectory: &isDir) {
//                        
//                        let pathURL = NSURL.fileURLWithPath(videoPath)
//
//                        let watchAndSpeakModel : WatchAndSpeakModel = WatchAndSpeakModel.init(previewURL: pathURL)
//                        
//                        let watchAndSpeakController : WatchAndSpeakController = segue.destinationViewController as! WatchAndSpeakController
//                        watchAndSpeakController.model = watchAndSpeakModel
//                    }
//                }
//            }
//        }
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
    
    func tableView(tableView: UITableView,
        didEndDisplayingCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
            if let videoCell : VideoCell? = cell as? VideoCell {
                videoCell?.player?.pause()
            }
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

//This works below! Use this for when user taps the video.
//                                let player = AVPlayer(URL: pathURL)
//                                let playerViewController = AVPlayerViewController()
//                                playerViewController.player = player
//                                self.presentViewController(playerViewController, animated: true) {
//                                    playerViewController.player!.play()
//                                }

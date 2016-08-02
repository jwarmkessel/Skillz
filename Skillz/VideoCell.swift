//
//  VideoCell.swift
//  Skillz
//
//  Created by Justin Warmkessel on 1/13/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

protocol VideoCellDelegate: class {
    func tryLessonButtonHandlerTapped(_ videoCell : VideoCell)
}

class VideoCell: UITableViewCell {
    weak var delegate:VideoCellDelegate?
    
    @IBAction func tryLessonButtonHandler(_ sender: UIButton, forEvent event: UIEvent) {
        self.delegate?.tryLessonButtonHandlerTapped(self)
    }
    
    @IBOutlet weak var profileUserName: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var topLineDecoration: UIView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var temporaryText: UILabel!
    var player : AVPlayer?
    var playerLayer : AVPlayerLayer?
    
    func mediaPlayerLayer(_ videoPath : String, indexPath : IndexPath)
    {
        self.selectionStyle = .none
        self.topLineDecoration(nil, alpha: 0.0, indexPath: indexPath)
    
        var isDir = ObjCBool(false)
        if FileManager.default.fileExists(atPath: videoPath, isDirectory: &isDir) {
            
            let pathURL = URL(fileURLWithPath: videoPath)
//            let pathURL = NSURL( string:"https://schools01.blob.core.windows.net/asset-3a7a834e-2bdc-4fa7-9f61-0c818b2f96b6/JustinIsADope_1080x1080_6000.mp4?sv=2012-02-12&sr=c&si=5b0430c9-15e1-48dd-b831-dbb91a8139ba&sig=7T%2B1xjOUoHGQImCcjV2IToz8MMNoH41V%2F1DHIUq7Vqs%3D&st=2016-06-29T03%3A09%3A57Z&se=2117-01-01T03%3A09%3A57Z" )
            if (self.player != nil)
            {
                let newItem : AVPlayerItem = AVPlayerItem(url: pathURL)
                self.player?.replaceCurrentItem(with: newItem)
            }
            else
            {
                self.player = AVPlayer(url: pathURL)
                
                if (self.playerLayer != nil)
                {
                    self.playerLayer?.player = self.player
                }
                else
                {
                    let playerLayer = AVPlayerLayer(player: self.player)
                    
                    //FIXME: This is a hack
                    let rect : CGRect = CGRect(x: 0.0, y: 0.0, width: UIScreen.main().bounds.size.width, height: UIScreen.main().bounds.size.width)
                    
                    
                    //FRBLocationWithDirectionCell*   cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    
                    
                    playerLayer.frame = rect
                    playerLayer.videoGravity = AVLayerVideoGravityResize
                    
                    self.videoImageView.layer.addSublayer(playerLayer)
                }
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: nil, using: { (NSNotification) -> Void in
                
                self.player?.currentItem?.seek(to: kCMTimeZero)
                self.player?.play()
            })
            
            //FIXME: should probably wait until video is ready until playing.
            //player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
            
            self.player?.isMuted = true
            self.player?.play()
            
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        if self.player?.currentItem?.status == .readyToPlay {
            self.player?.play()
            
        }
    }

    func configureTextLabel(_ text: String?)
    {
        if let textDescription = text
        {
            self.detailLabel.text = textDescription
        }
    }
    
    func topLineDecoration(_ backgroundColor : UIColor?, alpha : CGFloat, indexPath: IndexPath)
    {
        if let color = backgroundColor
        {
            self.topLineDecoration.backgroundColor = color
            self.topLineDecoration.alpha = alpha
        }
        else
        {
            self.topLineDecoration.backgroundColor = !self.isFirstCell(indexPath) ? UIColor.lightGray() : self.topLineDecoration.backgroundColor
            self.topLineDecoration.alpha = 0.8
        }
    }
    
    func isFirstCell(_ indexPath : IndexPath) -> Bool
    {
        return (indexPath as NSIndexPath).row == 0 ? true : false
    }
}

extension AVPlayerViewControllerDelegate
{
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: NSError)
    {
        
    }
    
    func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController)
    {
        
    }
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool
    {
        return true
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: (Bool) -> Void)
    {
        
    }
}


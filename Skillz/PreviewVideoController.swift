//
//  PreviewVideoController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class PreviewVideoController : UIViewController{
    var model : PreviewVideo?
    var player : AVPlayer?
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var previewVideoView: UIImageView!

    @IBAction func doneButtonHandler(sender: AnyObject) {

        if let navController = self.navigationController
        {
            navController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureVideoCell()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func configureVideoCell() {
        
        if (self.player == nil) {
            self.player = AVPlayer(URL: (model?.contentURL)!)
            
            if let avPlayer = self.player {
                let playerLayer = AVPlayerLayer(player: avPlayer)
                
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                playerLayer.frame = self.previewVideoView.bounds
                
                let half : CGFloat = 2.0
                
                self.previewVideoView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/half);
                self.previewVideoView.layer.addSublayer(playerLayer)

                
                NSNotificationCenter.defaultCenter().addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: self.player?.currentItem, queue: nil, usingBlock: { (NSNotification) -> Void in
                    
                    self.player?.currentItem?.seekToTime(kCMTimeZero)
                    self.player?.play()
                })
                
                avPlayer.play()
            }
        }
        else {
            self.player?.seekToTime(kCMTimeZero)
            self.player?.play()
        }
        
    }
}
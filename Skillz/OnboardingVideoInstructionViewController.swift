//
//  OnboardingVideoInstructionViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 5/17/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import MediaPlayer
import Speech
//import AVKit

class OnboardingVideoInstructionViewController: UIViewController {
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var beginButton: UIButton!
   
    @IBAction func beginButtonHandler(_ sender: UIButton, forEvent event: UIEvent) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
        
        UIApplication.shared().keyWindow?.rootViewController = vc
    }
    var player : AVPlayer?
    var playerLayer : AVPlayerLayer?
    
    //pragma mark
    func speechRecognizerPermission()
    {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized: break
                    //User gave access to speech recognition
                    
                case .denied: break
                    //User denied access to speech recognition
                    
                case .restricted: break
                    //Speech recognition restricted on this device
                    
                case .notDetermined: break
                    //Speech recognition not yet authorized
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.speechRecognizerPermission()

        // Do any additional setup after loading the view.
        let path = Bundle.main.pathForResource("Instructor", ofType: "mov")
        
        if let pathString = path
        {
            let fileManager : FileManager = FileManager()
            if (fileManager.fileExists(atPath: pathString))
            {
                let pathURL : URL = URL.init(fileURLWithPath: pathString, isDirectory: false)
                
                self.player = AVPlayer.init(url: pathURL)
                self.playerLayer = AVPlayerLayer(player: self.player)
    
                if let playerLayer = self.playerLayer
                {    
                    let height : CGFloat = self.videoImageView.layer.frame.height
                    let width : CGFloat = self.videoImageView.layer.frame.width
                    let rect : CGRect = CGRect(x: 0.0, y: 0.0, width: height, height: width + 20.0)
    
                    playerLayer.frame = rect
    
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    
                    self.videoImageView.layer.addSublayer(playerLayer)
                    
                    if let player = self.player {
                        player.play()
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

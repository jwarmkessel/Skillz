//
//  RecordViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    var model           : RecordVideo                   = RecordVideo()
    var previewLayer    : AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var videoPreviewViewControl: UIImageView!
    
    func createPreviewLayerComponents() {
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: model.session)

        if let layer = self.previewLayer {
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            layer.frame = videoPreviewViewControl.frame
            layer.connection.videoOrientation = .Portrait
        }
        
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()

        //Attach to UIView
        videoPreviewViewControl.layer.addSublayer(previewLayer!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        self.createPreviewLayerComponents()
    
        var videoConnection : AVCaptureConnection?
        
        for connection in (model.movieFileOutput?.connections)! {
            for port in connection.inputPorts! {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            
            if videoConnection != nil {
                break
            }
        }
        
        videoConnection?.videoOrientation = .Portrait
        
        if (model.session?.canSetSessionPreset(AVCaptureSessionPreset640x480) != nil) {
            model.session?.sessionPreset = AVCaptureSessionPreset640x480
        }
        
        model.session?.startRunning()
    }
}
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

class RecordViewController: UIViewController, RecordVideoDelegate {
    var model           : RecordVideo                   = RecordVideo()
    var previewLayer    : AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoPreviewViewControl: UIImageView!
    
    @IBAction func cancelButtonHandler(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resetElapsedTime() {
        model.elapsedProgressBarMovement = 0
        model.elapsedTime = 0
    }
    
    func removeAllComponentVideosBeingTracked() {
        model.arrayOfVideos.removeAll()
    }
    
    @IBAction func resetButtonHandler(sender: AnyObject) {
        self.resetElapsedTime()
        self.removeAllComponentVideosBeingTracked()
        self.configureProgressView()
        model.deleteAllVideoSessionsInsideFolderPath()
        
        self.view.userInteractionEnabled = true
    }
    
    @IBAction func saveButtonHandler(sender: AnyObject) {
        self.stopVideoRecording()
        model.mixCompositionMerge()
    }
    
    func didFinishTask(sender: RecordVideo)
    {        
        self.performSegueWithIdentifier("previewVideo", sender: self)
    }
    
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
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.stopVideoRecording()
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.stopVideoRecording()
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        if let touch = touches.first {
            let position = touch.locationInView(view)

            
            if(CGRectContainsPoint(self.videoPreviewViewControl.frame, position))
            {
                model.elapsedTimer = NSTimer.scheduledTimerWithTimeInterval(model.kTimerInterval, target: self, selector: #selector(RecordViewController.updateElapsedTime), userInfo: nil, repeats: true)
                
                if let newURL = self.generateVideoAbsoluteURLPath(NSUUID().UUIDString) {
                    self.model.arrayOfVideos.append(newURL)
                    model.movieFileOutput?.startRecordingToOutputFileURL(newURL, recordingDelegate: model)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if (segue.identifier == "previewVideo") {
            
            if let completedVideoURL = model.completedVideoURL {
                let previewVideo : PreviewVideo = PreviewVideo.init(url: completedVideoURL)

                if let previewVideoVC : PreviewVideoController = segue.destinationViewController as? PreviewVideoController {
                    previewVideoVC.model = previewVideo
                }
            }
        }
    }
    
    func updateElapsedTime () {
        let percentagePerSecond : Double = 100.0 / (self.model.kMaxSecondsForVideo/self.model.kTimerInterval)
        
        self.model.elapsedProgressBarMovement += (percentagePerSecond / 100)
        
        UIView.animateWithDuration(self.model.kTimerInterval) {
            
            self.progressView.progress = Float(self.model.elapsedProgressBarMovement)
            
        }
        
        self.model.elapsedTime += self.model.kTimerInterval
        //let elapsedFromMax = self.model.kMaxSecondsForVideo - self.model.elapsedTime
        //elapsedTimeLabel.text = "00:" + String(format: "%02d", Int(round(elapsedFromMax)))
        
        if self.model.elapsedTime >= self.model.kMaxSecondsForVideo {
            self.model.isRecording = true
        }
    }
    
    func stopVideoRecording() {
        model.elapsedTimer?.invalidate()
        model.movieFileOutput?.stopRecording()
    }
    
    func createRecordingSessionDirectoryStructure(directoryPath : String) {
        let fileManager : NSFileManager = NSFileManager.init()
        if (!fileManager.fileExistsAtPath(directoryPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("RecordVideoViewController: Could not create directory from the method createRecordingSessionDirectoryStructure()")
            }
        }
    }
    
    func generateVideoAbsoluteURLPath(fileName: String?) -> NSURL?{
        
        self.createRecordingSessionDirectoryStructure(model.documentsURL.path! + "/recordingSession/")
        
        if let file = fileName {
            self.createRecordingSessionDirectoryStructure(model.documentsURL.path! + "/recordingSession/\(model.directoryName!)")
            let path = model.documentsURL.path! + "/recordingSession/\(model.directoryName!)/\(file)" + ".mp4"
            
            return NSURL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func configureProgressView() {
//        let transform : CGAffineTransform  = CGAffineTransformMakeScale(1.0, 50.0);
//        self.progressView.transform = transform
        
        dispatch_async(dispatch_get_main_queue()) {
            self.progressView.setProgress(0, animated: true)
        }
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        self.stopVideoRecording()
        model.mixCompositionMerge()
    }
    
    func setupNotifications() {
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model.delegate = self;
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureProgressView()
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
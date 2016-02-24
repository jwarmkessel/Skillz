//
//  RecordVideoCellTableViewCell.swift
//  Skillz
//
//  Created by Justin Warmkessel on 2/22/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import AVFoundation

protocol RecordVideoCellDelegate {
    func didCaptureVideo (recordViewController : RecordVideoViewController)
}

class RecordVideoCellTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        self.contentView.userInteractionEnabled = true
        self.configureProgressView()

        self.videoPreviewViewControl.addTarget(self, action: Selector("videoTouchDown:"), forControlEvents: .TouchDown)
        self.videoPreviewViewControl.addTarget(self, action: Selector("videoTouchCancel:"), forControlEvents: .TouchCancel)
        self.videoPreviewViewControl.addTarget(self, action: Selector("videoTouchUpInside:"), forControlEvents: .TouchUpInside)
        self.videoPreviewViewControl.addTarget(self, action: Selector("videoTouchUpOutside:"), forControlEvents: .TouchUpOutside)
        
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if device != nil {
            self.setupRecording()
        }
        
        self.contentView.bringSubviewToFront(self.progressView)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //@IBOutlet weak var viewPreviewImageView: UIImageView!
    @IBOutlet weak var dismissControllerButton: UIButton!
    @IBAction func endRecording(sender: AnyObject) {
        self.contentView.userInteractionEnabled = false
        self.stopVideoRecording()
        self.mixCompositionMerge()
    }
    
    @IBOutlet weak var videoPreviewViewControl: UIControl!
    //@IBOutlet weak var videoPreviewViewControl: UIView!
    //@IBOutlet weak var videoPreviewViewControl: UIControl!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoViewBottomLayout: NSLayoutConstraint!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    
    var delegate        : RecordVideoCellDelegate?
    var movieFileOutput : AVCaptureMovieFileOutput?     = nil
    var elapsedTimer    : NSTimer?                      = nil
    var fileName        : String?                       = nil
    var session         : AVCaptureSession?             = nil
    var previewLayer    : AVCaptureVideoPreviewLayer?   = nil
    var arrayOfVideos   : [AnyObject]                   = [AnyObject]()
    var isRecording                                     = false
    var elapsedTime                                     = 0.0
    let kMaxSecondsForVideo                             = 10.0
    let captureFramesPerSecond                          = 30.0
    let documentsURL                                    = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    var elapsedProgressBarMovement : Double             = 0
    var kTimerInterval : NSTimeInterval                 = 0.02
    
    func videoTouchUpOutside(event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchUpInside(event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchCancel(event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchDown(event: UIControlEvents) {
        
        elapsedTimer = NSTimer.scheduledTimerWithTimeInterval(kTimerInterval, target: self, selector: Selector("updateElapsedTime"), userInfo: nil, repeats: true)
        
        fileName = NSUUID().UUIDString
        
        if let newURL = self.generateVideoAbsoluteURLPath(fileName) {
            self.arrayOfVideos.append(newURL)
            movieFileOutput?.startRecordingToOutputFileURL(newURL, recordingDelegate: self)
        }
    }

    
    
    func configureProgressView() {
        let transform : CGAffineTransform  = CGAffineTransformMakeScale(1.0, 50.0);
        self.progressView.transform = transform
        self.progressView.progress = 0
    }
    
    
    func setupCaptureSession () {
        
        /* What is a capture session */
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetHigh
        
        
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            
            /* Capture device input */
            let input = try AVCaptureDeviceInput(device: device)
            
            session?.addInput(input)
            
        } catch {
            print ("video initialization error")
        }
        
        /* Here is an Audio session */
        AVAudioSession.sharedInstance().requestRecordPermission
            {
                (granted: Bool) -> Void in
                if granted {
                    let audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
                    do {
                        let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
                        self.session?.addInput(audioInput)
                    } catch {
                        print ("audio initialization error")
                    }
                }
        }
        
        let queue = dispatch_queue_create("com.skillz.videoCaptureQueue", nil)
        
        /* Video Output */
        
        let output = AVCaptureVideoDataOutput ()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: queue)
        session?.addOutput(output)
        
        /* Capture Video Preview Layer */
        previewLayer = AVCaptureVideoPreviewLayer (session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRectMake(0, 50, videoPreviewViewControl.frame.size.width, videoPreviewViewControl.frame.size.height - 50)
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        
        //TODO: delete this code
        //let currentOrientation = UIDevice.currentDevice().orientation
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        
        
        
        previewLayer?.connection.videoOrientation = .Portrait
        videoPreviewViewControl.layer.addSublayer(previewLayer!)
        
        /* AVCaptureMovieFileOutput, Capture Movie File Output */
        movieFileOutput = AVCaptureMovieFileOutput()
        
        let maxDuration = CMTimeMakeWithSeconds(kMaxSecondsForVideo, Int32(captureFramesPerSecond))
        
        movieFileOutput?.maxRecordedDuration = maxDuration
        movieFileOutput?.minFreeDiskSpaceLimit = 1024 * 1024
        
        if (session?.canAddOutput(movieFileOutput) != nil) {
            session?.addOutput(movieFileOutput)
        }
        
        var videoConnection:AVCaptureConnection? = nil
        for connection in (movieFileOutput?.connections)! {
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
        
        if (session?.canSetSessionPreset(AVCaptureSessionPreset640x480) != nil) {
            session?.sessionPreset = AVCaptureSessionPreset640x480
        }
        
        session?.startRunning()
    }
    
    func updateElapsedTime () {
        
        //let movementPerSecond : Double = Double(self.progressView.bounds.width)/750
        let percentagePerSecond : Double = 100.0 / (kMaxSecondsForVideo/kTimerInterval)
        
        elapsedProgressBarMovement += (percentagePerSecond / 100)
        
        UIView.animateWithDuration(kTimerInterval) {
            
            self.progressView.progress = Float(self.elapsedProgressBarMovement)
            
        }
        
        elapsedTime += kTimerInterval
        let elapsedFromMax = kMaxSecondsForVideo - elapsedTime
        elapsedTimeLabel.text = "00:" + String(format: "%02d", Int(round(elapsedFromMax)))
        
        if elapsedTime >= kMaxSecondsForVideo {
            isRecording = true
        }
    }
    
    func setupRecording () {
        if session != nil {
            session!.stopRunning()
            session = nil
        }
        
        isRecording = false
        self.setupCaptureSession()
        elapsedTime = 0
        self.updateElapsedTime()
    }
    
    //MARK: Touch Down
    @IBAction func recVideoButtonTouchDown(sender: UIButton) {
        //        elapsedTimer = NSTimer.scheduledTimerWithTimeInterval(kTimerInterval, target: self, selector: Selector("updateElapsedTime"), userInfo: nil, repeats: true)
        //        sender.setImage(UIImage (named: "ButtonStop"), forState: UIControlState.Normal)
        //
        //        fileName = NSUUID().UUIDString
        //
        //        if let newURL = self.generateVideoAbsoluteURLPath(fileName) {
        //            self.arrayOfVideos.append(newURL)
        //            movieFileOutput?.startRecordingToOutputFileURL(newURL, recordingDelegate: self)
        //        }
    }
    
    func generateVideoAbsoluteURLPath(fileName: String?) -> NSURL?{
        if let file = fileName {
            let path = documentsURL.path! + "/" + file + ".mp4"
            return NSURL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    //    @IBAction func longPressTry(sender: UILongPressGestureRecognizer) {
    //
    //        let state : UIGestureRecognizerState = sender.state
    //
    //        switch(state) {
    //            case .Cancelled : print("Long Press Cancelled")
    //            case .Failed : print("Long Press failed")
    //            case .Ended : print("Long Press ENDED")
    //            case .Possible : print("Long Press Possible")
    //            case .Began : print("Long Press Began")
    //            default : print("Long Press No Fucking Clue")
    //        }
    //    }
    
    
    //MARK: Touch Up
    @IBAction func recVideoButtonTouchUpInside(sender: UIButton) {
        //self.stopVideoRecording()
    }
    
    func stopVideoRecording() {
        elapsedTimer?.invalidate()
        movieFileOutput?.stopRecording()
    }
    
    func generateThumbnailFromVideo () {
        let videoURL = NSURL(fileURLWithPath: (documentsURL.path! + "/" + fileName! + ".mp4"))
        let thumbnailPath = documentsURL.path! + "/" + fileName! + ".jpg"
        
        let asset = AVAsset(URL: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMake(2, 1)
        
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            let videoThumb = UIImage(CGImage: imageRef)
            let imgData = UIImageJPEGRepresentation(videoThumb, 0.8)
            
            NSFileManager.defaultManager().createFileAtPath(thumbnailPath, contents: imgData, attributes: nil)
        } catch let error as NSError {
            print("Image generation failed with error \(error)")
        }
    }
    
    func overlapVideoFiles() {
        //        //Here where load our movie Assets using AVURLAsset
        //        AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: @”gizmo” ofType: @”mp4″]] options:nil];
        //        AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: @”gizmo” ofType: @”mp4″]] options:nil];
        //
        //        //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
        //        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        //
        //        //Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
        //        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        //        //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
        //        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        //
        //        //Now we repeat the same process for the 2nd track as we did above for the first track.Note that the new track also starts at kCMTimeZero meaning both tracks will play simultaneously.
        //        AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        //        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    
    func mixCompositionMerge() {
        if let videos = self.arrayOfVideos as? [NSURL] {
            
            let mixcomposition : AVMutableComposition = AVMutableComposition()
            
            var current : CMTime = kCMTimeZero
            
            for url : NSURL in videos {
                
                let asset = AVURLAsset.init(URL: url)
                
                do {
                    
                    try mixcomposition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofAsset: asset, atTime: current)
                    
                } catch {
                    
                    print("annoying")
                    
                }
                
                current = CMTimeAdd(current, asset.duration);
                
                let fileManager : NSFileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtURL(url)
                } catch {
                    
                    print("annoying")
                }
            }
            
            let exporter = AVAssetExportSession(asset: mixcomposition, presetName: AVAssetExportPresetHighestQuality)
            
            let newFileName = NSUUID().UUIDString
            
            if let exporter = exporter, let completeMovieURL = self.generateVideoAbsoluteURLPath(newFileName) {
                
                exporter.outputURL = completeMovieURL
                exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
                
                exporter.exportAsynchronouslyWithCompletionHandler({
                    
                    [unowned self] in
                    
                    switch exporter.status{
                    case  AVAssetExportSessionStatus.Failed:
                        print("failed \(exporter.error)")
                    case AVAssetExportSessionStatus.Cancelled:
                        print("cancelled \(exporter.error)")
                    default:
                        print("complete")
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    })
                    })
            }
            
            
        }
    }
    
}

extension RecordVideoCellTableViewCell: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(outputFileURL);
        self.generateThumbnailFromVideo()
    }
}

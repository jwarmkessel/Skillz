//
//  RecordVideoViewController.swift
//  Skillz
//
//  Created by Justin Warmkessel on 2/22/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import UIKit
import AVFoundation

protocol CaptureVideoDelegate {
    func didCaptureVideo (_ recordViewController : RecordVideoViewController)
}

class RecordVideoViewController: EDUViewController {
    
    @IBOutlet weak var dismissControllerButton: UIButton!
    
    @IBAction func endRecording(_ sender: AnyObject) {
        self.view.isUserInteractionEnabled = false
        self.stopVideoRecording()
        self.mixCompositionMerge()
    }
    
    @IBOutlet weak var videoPreviewViewControl: UIControl!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoViewBottomLayout: NSLayoutConstraint!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    
    var delegate        : RecordVideoCellDelegate?
    var movieFileOutput : AVCaptureMovieFileOutput?     = nil
    var elapsedTimer    : Timer?                        = nil
    var directoryName   : String?                       = nil
    var session         : AVCaptureSession?             = nil
    var previewLayer    : AVCaptureVideoPreviewLayer?   = nil
    var arrayOfVideos   : [AnyObject]                   = [AnyObject]()
    var isRecording                                     = false
    var elapsedTime                                     = 0.0
    let kMaxSecondsForVideo                             = 10.0
    let captureFramesPerSecond                          = 30.0
    let documentsURL                                    = FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
    var elapsedProgressBarMovement : Double             = 0
    var kTimerInterval : TimeInterval                   = 0.02
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.directoryName = UUID().uuidString
        self.arrayOfVideos.removeAll()
        self.elapsedProgressBarMovement = 0
        self.elapsedTime = 0
        
        self.view.isUserInteractionEnabled = true
        self.configureProgressView()
        
        self.videoPreviewViewControl.addTarget(self, action: #selector(RecordVideoViewController.videoTouchDown(_:)), for: .touchDown)
        self.videoPreviewViewControl.addTarget(self, action: #selector(RecordVideoViewController.videoTouchCancel(_:)), for: .touchCancel)
        self.videoPreviewViewControl.addTarget(self, action: #selector(RecordVideoViewController.videoTouchUpInside(_:)), for: .touchUpInside)
        self.videoPreviewViewControl.addTarget(self, action: #selector(RecordVideoViewController.videoTouchUpOutside(_:)), for: .touchUpOutside)
        
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        if device != nil {
            self.setupRecording()
        }
        
        self.view.bringSubview(toFront: self.progressView)
    }
    
    func videoTouchUpOutside(_ event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchUpInside(_ event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchCancel(_ event: UIControlEvents) {
        self.stopVideoRecording()
    }
    
    func videoTouchDown(_ event: UIControlEvents) {
        
        elapsedTimer = Timer.scheduledTimer(timeInterval: kTimerInterval, target: self, selector: #selector(RecordVideoViewController.updateElapsedTime), userInfo: nil, repeats: true)
        
        if let newURL = self.generateVideoAbsoluteURLPath(UUID().uuidString) {
            self.arrayOfVideos.append(newURL)
            movieFileOutput?.startRecording(toOutputFileURL: newURL, recordingDelegate: self)
        }
    }
    
    func configureProgressView() {
        let transform : CGAffineTransform  = CGAffineTransform(scaleX: 1.0, y: 50.0);
        self.progressView.transform = transform
        
        DispatchQueue.main.async {
            self.progressView.setProgress(0, animated: true)
        }
    }
    
    func setupCaptureSession () {
        
        /* What is a capture session */
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetHigh
        
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
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
                    
                }
        }
        
        let audioCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioCaptureDevice)
            self.session?.addInput(audioInput)
        } catch {
            print ("audio initialization error")
        }
        
        let queue = DispatchQueue(label: "com.skillz.videoCaptureQueue", attributes: [])
        
        /* Video Output */
        
        let output = AVCaptureVideoDataOutput ()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: queue)
        session?.addOutput(output)
        
        /* Capture Video Preview Layer */
        previewLayer = AVCaptureVideoPreviewLayer (session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRect(x: 0, y: 50, width: videoPreviewViewControl.frame.size.width, height: videoPreviewViewControl.frame.size.height - 50)
        
        UIDevice.current().beginGeneratingDeviceOrientationNotifications()
        
        //TODO: delete this code
        //let currentOrientation = UIDevice.currentDevice().orientation
        UIDevice.current().endGeneratingDeviceOrientationNotifications()
        
        
        
        previewLayer?.connection.videoOrientation = .portrait
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
        
        videoConnection?.videoOrientation = .portrait
        
        if (session?.canSetSessionPreset(AVCaptureSessionPreset640x480) != nil) {
            session?.sessionPreset = AVCaptureSessionPreset640x480
        }
        
        session?.startRunning()
    }
    
    func updateElapsedTime () {
        
        //let movementPerSecond : Double = Double(self.progressView.bounds.width)/750
        let percentagePerSecond : Double = 100.0 / (kMaxSecondsForVideo/kTimerInterval)
        
        elapsedProgressBarMovement += (percentagePerSecond / 100)
        
        UIView.animate(withDuration: kTimerInterval) {
            
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
    @IBAction func recVideoButtonTouchDown(_ sender: UIButton) {
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
    
    func createRecordingSessionDirectoryStructure(_ directoryPath : String) {
        let fileManager : FileManager = FileManager.init()
        if (!fileManager.fileExists(atPath: directoryPath)) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("RecordVideoViewController: Could not create directory from the method createRecordingSessionDirectoryStructure()")
            }
        }
    }
    
    func generateVideoAbsoluteURLPath(_ fileName: String?) -> URL?{
        
        self.createRecordingSessionDirectoryStructure(documentsURL.path! + "/recordingSession/")
        
        if let file = fileName {
            self.createRecordingSessionDirectoryStructure(documentsURL.path! + "/recordingSession/\(self.directoryName!)")
            let path = documentsURL.path! + "/recordingSession/\(self.directoryName!)/\(file)" + ".mov"
            
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func completedRecordingURLPath(_ fileName: String?) -> URL?{
    
        if let file = fileName {
        
            let path = documentsURL.path! + "/\(file).mov"
            
            return URL(fileURLWithPath: path)
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
    @IBAction func recVideoButtonTouchUpInside(_ sender: UIButton) {
        //self.stopVideoRecording()
    }
    
    func stopVideoRecording() {
        elapsedTimer?.invalidate()
        movieFileOutput?.stopRecording()
    }
    
//    func generateThumbnailFromVideo () {
//        let videoURL = NSURL(fileURLWithPath: (documentsURL.path! + "/recordingSession/\(self.directoryName!)/\(fileName!)" + ".mp4"))
//        let thumbnailPath = documentsURL.path! + "/recordingSession/\(self.directoryName!)/\(fileName!)" + ".jpg"
//        
//        let asset = AVAsset(URL: videoURL)
//        let imageGenerator = AVAssetImageGenerator(asset: asset)
//        imageGenerator.appliesPreferredTrackTransform = true
//        
//        let time = CMTimeMake(2, 1)
//        
//        do {
//            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
//            let videoThumb = UIImage(CGImage: imageRef)
//            let imgData = UIImageJPEGRepresentation(videoThumb, 0.8)
//            
//            NSFileManager.defaultManager().createFileAtPath(thumbnailPath, contents: imgData, attributes: nil)
//        } catch let error as NSError {
//            print("Image generation failed with error \(error)")
//        }
//    }
    
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
        if let videos = self.arrayOfVideos as? [URL] {
            
            let mixcomposition : AVMutableComposition = AVMutableComposition()
            
            var current : CMTime = kCMTimeZero
            
            for url : URL in videos {
                
                let asset = AVURLAsset.init(url: url)
                
                do {
                    
                    try mixcomposition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: asset, at: current)
                    
                } catch {
                    
                    print("annoying")
                    
                }
                
                current = CMTimeAdd(current, asset.duration);
                
//                let fileManager : NSFileManager = NSFileManager.defaultManager()
//                do {
//                    try fileManager.removeItemAtURL(url)
//                } catch {
//                    
//                    print("annoying")
//                }
            }
            
            let exporter = AVAssetExportSession(asset: mixcomposition, presetName: AVAssetExportPresetHighestQuality)
            
            let newFileName = UUID().uuidString
            
            if let exporter = exporter, let completeMovieURL = self.completedRecordingURLPath(newFileName){
                
                exporter.outputURL = completeMovieURL
                exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
                
                exporter.exportAsynchronously(completionHandler: {
                    
                    [unowned self] in
                    
                    switch exporter.status {
                        case  AVAssetExportSessionStatus.failed:
                            print("failed \(exporter.error)")
                        case AVAssetExportSessionStatus.cancelled:
                            print("cancelled \(exporter.error)")
                        default:
                            print("complete")
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.tabBarController?.selectedIndex =  0
                            })
                    }
                })
            }
        }
    }
}

extension RecordVideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(outputFileURL);
        //self.generateThumbnailFromVideo()
    }
}

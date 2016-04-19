//
//  RecordVideo.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import AVFoundation

class RecordVideo : NSObject {
    var session         : AVCaptureSession?
    var movieFileOutput : AVCaptureMovieFileOutput?
    var dataOutput      : AVCaptureVideoDataOutput?
    var device          : AVCaptureDevice?
    var audioDevice     : AVCaptureDevice?
    let documentsURL                                    = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
    
    
    var directoryName   : String?                       = NSUUID().UUIDString
    var arrayOfVideos   : [AnyObject]                   = [AnyObject]()
    var isRecording                                     = false
    var elapsedTimer    : NSTimer?                      = nil
    var elapsedTime                                     = 0.0
    let kMaxSecondsForVideo                             = 10.0
    let captureFramesPerSecond                          = 30.0
    var elapsedProgressBarMovement : Double             = 0
    var kTimerInterval : NSTimeInterval                 = 0.02
    
    override init() {
        super.init()
        
        if (self.checkDeviceMediaAvailability()) {
            self.setupMediaComponents()
        } else {
            //Device not available to do media related stuff
        }
    }
    
    func setupMediaComponents () {
        
        self.createSession()
        self.createSessionInput()
        self.createAudioInput()
        self.createSessionOutput()
        self.createMovieFileOutput()
    }
    
    func checkDeviceMediaAvailability() -> Bool {
        var availability : Bool = false
        
        self.device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if (self.device != nil) {
            availability = true
            self.session?.stopRunning()
            self.session = nil
        }
        
        return availability
    }
    
    func createSession() {
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetHigh
    }
    
    func createSessionInput() {
        do {
            /* Capture device input */
            let input = try AVCaptureDeviceInput(device: self.device)
            
            session?.addInput(input)
            
        } catch {
            print ("video initialization error")
        }
    }
    
    func createSessionOutput() {
        let queue = dispatch_queue_create("com.skillz.videoCaptureQueue", nil)
        
        self.dataOutput = AVCaptureVideoDataOutput()
        
        if let output = self.dataOutput {
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
            output.setSampleBufferDelegate(self, queue: queue)
            session?.addOutput(output)
        }
    }
    
    func createAudioInput() {
        AVAudioSession.sharedInstance().requestRecordPermission {
            (granted: Bool) -> Void in
            if granted {
                self.audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
                
                do {
                    let audioInput = try AVCaptureDeviceInput(device: self.audioDevice)
                    self.session?.addInput(audioInput)
                } catch {
                    print ("audio initialization error")
                }
            }
        }
    }
    
    func createMovieFileOutput() {
        self.movieFileOutput = AVCaptureMovieFileOutput()

        let maxDuration = CMTimeMakeWithSeconds(kMaxSecondsForVideo, Int32(captureFramesPerSecond))
        
        self.movieFileOutput?.maxRecordedDuration = maxDuration
        self.movieFileOutput?.minFreeDiskSpaceLimit = 1024 * 1024
        
        if (self.session?.canAddOutput(self.movieFileOutput) != nil) {
            self.session?.addOutput(self.movieFileOutput)
        }
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
                    
                    //FIXME: If there's an issue we may have to reprocess OR alert the user to the problem and how to solve (if can).
                    print("annoying")
                }
                
                current = CMTimeAdd(current, asset.duration);
            }
            
            let exporter = AVAssetExportSession(asset: mixcomposition, presetName: AVAssetExportPresetHighestQuality)
            
            let newFileName = NSUUID().UUIDString
            
            if let exporter = exporter, let completeMovieURL = self.completedRecordingURLPath(newFileName){
                
                exporter.outputURL = completeMovieURL
                exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
                
                exporter.exportAsynchronouslyWithCompletionHandler({
                    
//                    [unowned self] in
                    
                    switch exporter.status {
                    case  AVAssetExportSessionStatus.Failed:
                        print("failed \(exporter.error)")
                    case AVAssetExportSessionStatus.Cancelled:
                        print("cancelled \(exporter.error)")
                    default:
                        print("complete")
                    }
                    })
            }
        }
    }

    func completedRecordingURLPath(fileName: String?) -> NSURL?{
        
        if let file = fileName {
            
            let path = documentsURL.path! + "/\(file).mp4"
            
            return NSURL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func deleteAllVideoSessionsInsideFolderPath() {
        
        var documentDirURL = self.documentsURL
        
        documentDirURL = documentDirURL.URLByAppendingPathComponent("recordingSession/")
        documentDirURL = documentDirURL.URLByAppendingPathComponent("\(self.directoryName!)")

        
        let fileManager : NSFileManager = NSFileManager.init()
        do {
            let folderPath = documentDirURL.path!
            let paths = try fileManager.contentsOfDirectoryAtPath(folderPath)
            for path in paths
            {
                try fileManager.removeItemAtPath("\(folderPath)/\(path)")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
//        let fileManager : NSFileManager = NSFileManager.init()
//        
//        
//        if (!fileManager.fileExistsAtPath(documentDirURL.path!)) {
//            do {
//                let folderPath = documentDirURL.path!
//                let paths = try fileManager.contentsOfDirectoryAtPath(folderPath)
//                for path in paths
//                {
//                    try fileManager.removeItemAtPath("\(folderPath)/\(path)")
//                }
//            } catch let error as NSError {
//                print(error.localizedDescription)
//            }
//        }
//        else {
//            print("No file exists here.")
//        }
    }
}

extension RecordVideo: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(outputFileURL);
    }
}
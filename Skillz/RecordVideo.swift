//
//  RecordVideo.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecordVideoDelegate: class {
    func didFinishTask(sender: RecordVideo)
}

class RecordVideo : NSObject {
    weak var delegate:RecordVideoDelegate?
    var session         : AVCaptureSession?
    var movieFileOutput : AVCaptureMovieFileOutput?
    var dataOutput      : AVCaptureVideoDataOutput?
    var device          : AVCaptureDevice?
    var audioDevice     : AVCaptureDevice?
    var videoConnection : AVCaptureConnection?
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
    var previousCameraInput : AVCaptureInput?
    var completedVideoURL : NSURL?
    
    
    func setupConnection() {        
       self.session?.startRunning()
    }
    
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
        session?.sessionPreset = AVCaptureSessionPresetMedium
        
        if ((session?.canSetSessionPreset(AVCaptureSessionPreset640x480)) == true)
        {
            session?.beginConfiguration()
            
            session?.sessionPreset = AVCaptureSessionPreset640x480;
            
            session?.commitConfiguration()
        }
        else
        {
            //Failure case.
        }
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

        if let fileOutput : AVCaptureMovieFileOutput = self.movieFileOutput
        {
            if let connections = fileOutput.connections
            {
                for connection in connections {
                    for port in connection.inputPorts! {
                        if port.mediaType == AVMediaTypeVideo {
                            self.videoConnection = connection as? AVCaptureConnection
                            self.videoConnection?.videoOrientation = .Portrait
                            
                            
                            
                            break
                        }
                    }
                    
                    if self.videoConnection != nil {
                        
                        fileOutput.setRecordsVideoOrientationAndMirroringChanges(true, asMetadataTrackForConnection: self.videoConnection)
                        break
                    }
                }
                
                self.videoConnection?.videoOrientation = .Portrait
                
                
                if (self.session?.canSetSessionPreset(AVCaptureSessionPreset640x480) != nil) {
                    self.session?.sessionPreset = AVCaptureSessionPreset640x480
                }
            }
        }

        
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
            let videoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
            
            var current : CMTime = kCMTimeZero
            
            for url : NSURL in videos {
                
                let asset = AVURLAsset.init(URL: url)
                
                do {
                    
                    try mixcomposition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofAsset: asset, atTime: current)
                    
                    let assetVideoTrack : AVAssetTrack? = asset.tracksWithMediaType(AVMediaTypeVideo).first
                    let compositionAssetTrack : AVMutableCompositionTrack? = mixcomposition.tracksWithMediaType(AVMediaTypeVideo).first
                    
                    if let assetTrack = assetVideoTrack, let compTrack = compositionAssetTrack
                    {
                        
                        
                        if let layerInstruction : AVMutableVideoCompositionInstruction = self.createAssetCompositionInstruction(asset, videoComposition: videoComposition, current: current)
                        {
                            videoComposition.instructions.append(layerInstruction)
                        }
                        
                        compTrack.preferredTransform = assetTrack.preferredTransform
                    }
                
                } catch {
                    
                    //FIXME: If there's an issue we may have to reprocess OR alert the user to the problem and how to solve (if can).
                    print("annoying")
                }
                
                current = CMTimeAdd(current, asset.duration);
            }
            
            videoComposition.renderSize = CGSizeMake(480.0, 480.0)
            videoComposition.frameDuration = CMTimeMake(1, 30);
            let newFileName = NSUUID().UUIDString

            self.createExporterAndExport(mixcomposition, videoComposition: videoComposition, completeMovieURL: self.completedRecordingURLPath(newFileName)!)
        }
    }
    
    func createAssetCompositionInstruction(asset : AVAsset, videoComposition : AVMutableVideoComposition, current : CMTime) -> AVMutableVideoCompositionInstruction?
    {
        let assetVideoTrack : AVAssetTrack? = asset.tracksWithMediaType(AVMediaTypeVideo).first
        let instruction : AVMutableVideoCompositionInstruction =  AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(current, asset.duration)
        
        if let assetTrack = assetVideoTrack
        {
            let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
            let squareTransform : CGAffineTransform = CGAffineTransformMakeTranslation(assetTrack.naturalSize.height, 0);
            let finalTransform : CGAffineTransform = CGAffineTransformRotate(squareTransform, CGFloat(M_PI_2));
            layerInstruction.setTransform(finalTransform, atTime: current)
            instruction.layerInstructions.append(layerInstruction)
            
            return instruction
        }
        
        return nil
    }
    
    func createExporterAndExport(mixcomposition : AVMutableComposition, videoComposition : AVMutableVideoComposition, completeMovieURL : NSURL)
    {
        let exporter : AVAssetExportSession? = AVAssetExportSession(asset: mixcomposition, presetName: AVAssetExportPresetMediumQuality)
    
        if let exporter = exporter
        {
            exporter.videoComposition = videoComposition
            exporter.outputURL = completeMovieURL
            exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
            exporter.exportAsynchronouslyWithCompletionHandler({
                
                [unowned self] in
                
                switch exporter.status {
                case  AVAssetExportSessionStatus.Failed:
                    print("failed \(exporter.error)")
                case AVAssetExportSessionStatus.Cancelled:
                    print("cancelled \(exporter.error)")
                default:
                    self.completedVideoURL = completeMovieURL;
                    self.delegate?.didFinishTask(self)
                }
            })
        }
    }
    
//    func transformVideoToSquare(mixComposition : AVMutableComposition) ->AVMutableVideoComposition?
//    {
//        
//        let videoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
//        
//        videoComposition.frameDuration = mixComposition.duration
//        
//        let compTrackArray : [AVMutableCompositionTrack] = mixComposition.tracksWithMediaType(AVMediaTypeVideo)
//        
//        for assetTrack : AVMutableCompositionTrack in compTrackArray {
//            videoComposition.renderSize = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.height)
//            
//            let instruction : AVMutableVideoCompositionInstruction =  AVMutableVideoCompositionInstruction()
//            
//            //FIXME: Mixcompositoin duration could be totally wrong
//            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
//            
//            let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
//            let squareTransform : CGAffineTransform = CGAffineTransformMakeTranslation(assetTrack.naturalSize.height, 0);
//            
//            layerInstruction.setTransform(squareTransform, atTime: kCMTimeZero)
//            instruction.layerInstructions.append(layerInstruction)
//            videoComposition.instructions.append(instruction)
//            
//            
//        }
//        
//        
//    }
    
//    func transformVideoToSquare(asset : AVAsset) ->AVMutableVideoComposition?
//    {
//        
//        let clipVideoTrack = AVURLAsset.init(URL: url)
//        
//        let videoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
//        
//        videoComposition.frameDuration = clipVideoTrack.duration
//
//        let assetTrack : AVAssetTrack? = clipVideoTrack.tracksWithMediaType(AVMediaTypeVideo).first
//        
//        if let assetTrack = assetTrack
//        {
//            videoComposition.renderSize = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.height)
//            
//            let instruction : AVMutableVideoCompositionInstruction =  AVMutableVideoCompositionInstruction()
//            
//            instruction.timeRange = CMTimeRangeMake(kCMTimeZero, clipVideoTrack.duration)
//            
//            let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
//            let squareTransform : CGAffineTransform = CGAffineTransformMakeTranslation(assetTrack.naturalSize.height, 0);
//            
//            layerInstruction.setTransform(squareTransform, atTime: kCMTimeZero)
//            instruction.layerInstructions.append(layerInstruction)
//            videoComposition.instructions.append(instruction)
//            
//            let newFileName = NSUUID().UUIDString
//            let url = self.completedRecordingURLPath(newFileName)
//            
//            self.createVideoExporterAndExport(videoComposition, asset: clipVideoTrack, completeMovieURL: url!)
//        }
//    }
//
//    func createVideoExporterAndExport(videoComposition : AVMutableVideoComposition, asset : AVAsset, completeMovieURL : NSURL)
//    {
//        let exporter : AVAssetExportSession? = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
//        
//        if let exporter = exporter
//        {
//            exporter.videoComposition = videoComposition
//            exporter.outputURL = completeMovieURL
//            exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
//            exporter.exportAsynchronouslyWithCompletionHandler({
//                
//                [unowned self] in
//                
//                switch exporter.status {
//                case  AVAssetExportSessionStatus.Failed:
//                    print("failed \(exporter.error)")
//                case AVAssetExportSessionStatus.Cancelled:
//                    print("cancelled \(exporter.error)")
//                default:
//                    
////                    let fileManager : NSFileManager = NSFileManager()
////                    
////                    do
////                    {
////                         try fileManager.removeItemAtURL(self.completedVideoURL!)
////                    }
////                    catch
////                    {
////                        
////                    }
//                    
//                    self.completedVideoURL = completeMovieURL;
//                    
//                    self.delegate?.didFinishTask(self)
//                }
//            })
//        }
//    }
    
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
    }
}

extension RecordVideo: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(connections)
    }
}
//
//  RecordVideo.swift
//  Skillz
//
//  Created by Justin Warmkessel on 4/11/16.
//  Copyright © 2016 Justin Warmkessel. All rights reserved.
//

import Foundation
import AVFoundation
import Speech

protocol RecordVideoDelegate: class {
    func didFinishVideoEditingTask(_ sender: RecordVideo)
    func didFinishSpeechToText(_ sender: RecordVideo)
}

class RecordVideo : NSObject {
    weak var delegate:RecordVideoDelegate?
    var session         : AVCaptureSession?
    var movieFileOutput : AVCaptureMovieFileOutput?
    var dataOutput      : AVCaptureVideoDataOutput?
    var device          : AVCaptureDevice?
    var audioDevice     : AVCaptureDevice?
    var videoConnection : AVCaptureConnection?
    let documentsURL                                    = FileManager.default.urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
    var speechToTextResults : String?
    var directoryName   : String?                       = UUID().uuidString
    var arrayOfVideos   : [AnyObject]                   = [AnyObject]()
    var isRecording                                     = false
    var elapsedTimer    : Timer?                      = nil
    var elapsedTime                                     = 0.0
    let kMaxSecondsForVideo                             = 10.0
    let captureFramesPerSecond                          = 30.0
    var elapsedProgressBarMovement : Double             = 0
    var kTimerInterval : TimeInterval                 = 0.02
    var previousCameraInput : AVCaptureInput?
    var completedVideoURL : URL?
    
    func setupConnection() {        
       self.session?.startRunning()
    }
    
    override init() {
        super.init()
        
        self.speechRecognizerPermission()
        
        if (self.checkDeviceMediaAvailability()) {
            self.setupMediaComponents()
        } else {
            //Device not available to do media related stuff
        }
    }
    
    func setupMediaComponents () {
        
        var passed : Bool
        
        passed = self.createSession()
        passed = self.createSessionInput()
        passed = self.createAudioInput()
        passed = self.createSessionOutput()
        passed = self.createMovieFileOutput()
        
        if (passed == true)
        {
            print("All Systems are a GO!")
        }
        else
        {
            print("Media Failure")
        }
    }
    
    func checkDeviceMediaAvailability() -> Bool {
        var availability : Bool = Bool()
        
        self.device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        if (self.device != nil) {
            availability = true
            self.session?.stopRunning()
            self.session = nil
        }
        
        return availability
    }
    
    func createSession() -> Bool {
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
            print("Issue creating session")
        }
        
        if ((session) != nil)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func createSessionInput() -> Bool {
        
        var canCreateSessionInput : Bool = Bool()
        
        do {
            /* Capture device input */
            let input = try AVCaptureDeviceInput(device: self.device)
            
            if ((session?.canAddInput(input)) == true) {
                session?.addInput(input)
                canCreateSessionInput = true
            }
            else {
                canCreateSessionInput = false
            }
            
            return canCreateSessionInput
        } catch {
            print ("RecordVideo:createSessionInput() error")
            
        }
        
        return canCreateSessionInput
    }
    
    func createSessionOutput() -> Bool {
        var canCreateSessionOutput : Bool
        
        let queue = DispatchQueue(label: "com.skillz.videoCaptureQueue", attributes: [])
        
        self.dataOutput = AVCaptureVideoDataOutput()
        
        if let output = self.dataOutput , ((session?.canAddOutput(output)) == true){
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
            output.setSampleBufferDelegate(self, queue: queue)
            session?.addOutput(output)
            
            canCreateSessionOutput = true
        }
        else
        {
            canCreateSessionOutput = false
        }
        
        return canCreateSessionOutput
    }
    
    func createAudioInput() -> Bool  {
        
        var canCreateAudioInput : Bool = Bool()
        let avAudioSession = AVAudioSession.sharedInstance()

        if (isAudioSessionPermissionGranted(audioSession: avAudioSession))
        {
            self.audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
            do {
                let audioInput = try AVCaptureDeviceInput(device: self.audioDevice)
                
                if ((self.session?.canAddInput(audioInput)) == true) {
                    self.session?.addInput(audioInput)
                    canCreateAudioInput = true
                }
                else {
                    print ("audio initialization error")
                    canCreateAudioInput = false
                }
            } catch {
                print ("audio initialization error")
            }
            
            canCreateAudioInput = true
        }
        else
        {
            AVAudioSession.sharedInstance().requestRecordPermission {
                (granted: Bool) -> Void in
                if granted {
                    self.audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
                    
                    do {
                        let audioInput = try AVCaptureDeviceInput(device: self.audioDevice)
                        
                        if ((self.session?.canAddInput(audioInput)) == true) {
                            self.session?.addInput(audioInput)
                            canCreateAudioInput = true
                        }
                        else {
                            print ("audio initialization error")
                            canCreateAudioInput = false
                        }
                    } catch {
                        print ("audio initialization error")
                    }
                }
            }
            
            canCreateAudioInput = false
        }
        
        return canCreateAudioInput
    }
    
    func isAudioSessionPermissionGranted( audioSession : AVAudioSession) -> Bool {
        
        var isAudioPermissionGranted : Bool = Bool()
        
        let permission : AVAudioSessionRecordPermission = audioSession.recordPermission()
        
        if (permission == .undetermined) {
            isAudioPermissionGranted = false
        } else if (permission == .granted) {
            isAudioPermissionGranted = true
        } else if (permission == .denied) {
            isAudioPermissionGranted = false
        }
        
        return isAudioPermissionGranted
    }
    
    func createMovieFileOutput() -> Bool {
        
        var canCreateMovieFileOutput : Bool = Bool()
        
        self.movieFileOutput = AVCaptureMovieFileOutput()

        if let fileOutput : AVCaptureMovieFileOutput = self.movieFileOutput
        {
            if let connections = fileOutput.availableVideoCodecTypes
            {
                for connection in connections {
                    for port in connection.inputPorts! {
                        if port.mediaType == AVMediaTypeVideo {
                            self.videoConnection = connection as? AVCaptureConnection
                            self.videoConnection?.videoOrientation = .portrait
                            
                            
                            
                            break
                        }
                    }
                    
                    if self.videoConnection != nil {
                        
                        fileOutput.setRecordsVideoOrientationAndMirroringChanges(true, asMetadataTrackFor: self.videoConnection)
                        break
                    }
                }
                
                self.videoConnection?.videoOrientation = .portrait
                
                
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
            
            canCreateMovieFileOutput = true
        }
        else
        {
            canCreateMovieFileOutput = false
        }
        
        return canCreateMovieFileOutput
    }
    
    func mixCompositionMerge() {
        if let videos = self.arrayOfVideos as? [URL] {
            
            let mixcomposition : AVMutableComposition = AVMutableComposition()
            let videoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
            
            var current : CMTime = kCMTimeZero
            
            for url : URL in videos {
                
                let asset = AVURLAsset.init(url: url)
                
                do {
                    
                    try mixcomposition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: asset, at: current)
                    
                    let assetVideoTrack : AVAssetTrack? = asset.tracks(withMediaType: AVMediaTypeVideo).first
                    let compositionAssetTrack : AVMutableCompositionTrack? = mixcomposition.tracks(withMediaType: AVMediaTypeVideo).first
                    
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
            
            videoComposition.renderSize = CGSize(width: 480.0, height: 480.0)
            videoComposition.frameDuration = CMTimeMake(1, 30);
            let newFileName = UUID().uuidString

            self.createExporterAndExport(mixcomposition, videoComposition: videoComposition, completeMovieURL: self.completedRecordingURLPath(newFileName)!)
        }
    }
    
    func createAssetCompositionInstruction(_ asset : AVAsset, videoComposition : AVMutableVideoComposition, current : CMTime) -> AVMutableVideoCompositionInstruction?
    {
        let assetVideoTrack : AVAssetTrack? = asset.tracks(withMediaType: AVMediaTypeVideo).first
        let instruction : AVMutableVideoCompositionInstruction =  AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(current, asset.duration)
        
        if let assetTrack = assetVideoTrack
        {
            let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
        
            let squareTransform : CGAffineTransform = CGAffineTransform(translationX: assetTrack.naturalSize.height, y: 0);
            let finalTransform : CGAffineTransform = squareTransform.rotate(CGFloat(M_PI_2));
            layerInstruction.setTransform(finalTransform, at: current)
            instruction.layerInstructions.append(layerInstruction)
            
            return instruction
        }
        
        return nil
    }
    
    func createExporterAndExport(_ mixcomposition : AVMutableComposition, videoComposition : AVMutableVideoComposition, completeMovieURL : URL)
    {
        let exporter : AVAssetExportSession? = AVAssetExportSession(asset: mixcomposition, presetName: AVAssetExportPresetMediumQuality)
    
        if let exporter = exporter
        {
            exporter.videoComposition = videoComposition
            exporter.outputURL = completeMovieURL
            exporter.outputFileType = AVFileTypeMPEG4 //AVFileTypeQuickTimeMovie
            exporter.exportAsynchronously(
                completionHandler: {
                    [unowned self] in
                
                    switch exporter.status
                    {
                    case  AVAssetExportSessionStatus.failed:
                        print("failed \(exporter.error)")
                    case AVAssetExportSessionStatus.cancelled:
                        print("cancelled \(exporter.error)")
                    default:
                        self.completedVideoURL = completeMovieURL;
                        self.delegate?.didFinishVideoEditingTask(self)
                    }
                }
            )
        }
    }
    
    func completedRecordingURLPath(_ fileName: String?) -> URL?{
        
        if let file = fileName {
            
            let path = documentsURL.path! + "/\(file).mov"
            
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func deleteAllVideoSessionsInsideFolderPath() {
        
        var documentDirURL = self.documentsURL
        
        documentDirURL = try! documentDirURL.appendingPathComponent("recordingSession/")
        documentDirURL = try! documentDirURL.appendingPathComponent("\(self.directoryName!)")

        
        let fileManager : FileManager = FileManager.init()
        do {
            let folderPath = documentDirURL.path!
            let paths = try fileManager.contentsOfDirectory(atPath: folderPath)
            for path in paths
            {
                try fileManager.removeItem(atPath: "\(folderPath)/\(path)")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
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
    
    func speechKitTest(fileURL : URL)
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
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        let recognitionTask: SFSpeechRecognitionTask = (recognizer?.recognitionTask(with: request, resultHandler:
            {
                (result, error)   in
                if let error = error
                {
                    print("There was an error: \(error)")
                }
                else
                {
                    print (result?.bestTranscription.formattedString)
                }
        })
            )!
        
        print(recognitionTask)
    }
}

extension RecordVideo: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(connections)
    }
}

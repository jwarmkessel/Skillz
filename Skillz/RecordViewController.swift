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

enum CameraType {
    case front 
    case back
}

class RecordViewController: UIViewController, RecordVideoDelegate {
    let kPreviewRecordedVideoSegueIdentifier  = "previewRecordedVideo"
    
    var model           : RecordVideo                   = RecordVideo()
    var previewLayer    : AVCaptureVideoPreviewLayer?
    var playerLayer     : AVPlayerLayer?
    var player          : AVPlayer?
    
    @IBOutlet weak var instructionContentMetaDataTextView: UITextView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var videoPreviewViewControl: UIImageView!
    @IBOutlet weak var flipCameraButton: UIButton!
    
    @IBAction func cancelButtonHandler(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func flipCameraButtonHandler(_ sender: AnyObject) {
        self.reloadCamera()
    }
    func resetElapsedTime() {
        model.elapsedProgressBarMovement = 0
        model.elapsedTime = 0
    }
    
    func removeAllComponentVideosBeingTracked() {
        model.arrayOfVideos.removeAll()
    }
    
    @IBAction func resetButtonHandler(_ sender: AnyObject) {
        self.resetElapsedTime()
        self.removeAllComponentVideosBeingTracked()
        self.configureProgressView()
        model.deleteAllVideoSessionsInsideFolderPath()
        
        self.view.isUserInteractionEnabled = true
    }
    
    @IBAction func saveButtonHandler(_ sender: AnyObject) {

        self.stopVideoRecording()
        model.mixCompositionMerge()
    }
    
    //pragma mark - RecordVideoDelegate
    func didFinishSpeechToText(_ sender: RecordVideo) {
        
    }
    
    func didFinishVideoEditingTask(_ sender: RecordVideo)
    {
        DispatchQueue.main.async {
            //TODO Update buttons and actions
            //TODO Replace the camera preview layer
            
            if let videoURL = self.model.completedVideoURL, let previewLayer = self.previewLayer
            {
                previewLayer.isHidden = true
                self.player = AVPlayer.init(url: videoURL)
                
                if self.playerLayer == nil
                {
                    self.playerLayer = AVPlayerLayer.init()
                    self.playerLayer!.bounds = CGRect(x: 0, y: 0, width: 750.0, height: 824.0)
                }
                
                self.videoPreviewViewControl.layer.addSublayer(self.playerLayer!)
                
                self.playerLayer?.player = self.player
                
                self.player?.play()
            }
            else
            {
                //Nothing to do
            }
        }
    }
    
    func createPreviewLayerComponents() {
        UIDevice.current().beginGeneratingDeviceOrientationNotifications()
        
        if let session = model.session
        {
            self.previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        }
        
        if let previewLayer = self.previewLayer {
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
            //FIXME: This is super broken. Will only work for 6S
            previewLayer.bounds = CGRect(x: 0, y: 0, width: 750.0, height: 824.0)
//            layer.frame = videoPreviewViewControl.frame
            
            self.view.layoutIfNeeded()
            self.view.setNeedsLayout()
            
            if let connector = previewLayer.connection
            {
                connector.videoOrientation = .portrait
            }
            
            //Attach to UIView
            videoPreviewViewControl.layer.addSublayer(previewLayer)
        }
        
        UIDevice.current().endGeneratingDeviceOrientationNotifications()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stopVideoRecording()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.stopVideoRecording()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            let position = touch.location(in: view)

            
            if(self.videoPreviewViewControl.frame.contains(position))
            {
                model.elapsedTimer = Timer.scheduledTimer(timeInterval: model.kTimerInterval, target: self, selector: #selector(RecordViewController.updateElapsedTime), userInfo: nil, repeats: true)
                
                if let newURL = self.generateVideoAbsoluteURLPath(UUID().uuidString) {
                    self.model.arrayOfVideos.append(newURL)
                    model.movieFileOutput?.startRecording(toOutputFileURL: newURL, recordingDelegate: model)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {

        if (segue.identifier == "previewRecordedVideo")
        {    
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
        
        UIView.animate(withDuration: self.model.kTimerInterval) {
            
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
        
        self.createRecordingSessionDirectoryStructure(model.documentsURL.path! + "/recordingSession/")
        
        if let file = fileName {
            self.createRecordingSessionDirectoryStructure(model.documentsURL.path! + "/recordingSession/\(model.directoryName!)")
            let path = model.documentsURL.path! + "/recordingSession/\(model.directoryName!)/\(file)" + ".mov"
            
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    func configureProgressView() {
//        let transform : CGAffineTransform  = CGAffineTransformMakeScale(1.0, 50.0);
//        self.progressView.transform = transform
        
        DispatchQueue.main.async {
            self.progressView.setProgress(0, animated: true)
        }
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        self.stopVideoRecording()
        model.mixCompositionMerge()
    }
    
    func setupNotifications() {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
//        CGRect bounds=view.layer.bounds;
//        avLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        avLayer.bounds=bounds;
//        avLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    }
    
    
//    func speechKitTest()
//    {
//        let recognizer = SFSpeechRecognizer()
//        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
//        
//        let recognitionTask: SFSpeechRecognitionTask = recognizer?.recognitionTask(with: request, resultHandler: { (result, error)   in
//            if let error = error {
//                print("There was an error: \(error)")
//            } else {
//                print (result?.bestTranscription.formattedString)
//            }
//        })
//    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model.delegate = self;
        self.navigationController?.isNavigationBarHidden = true
        
        self.configureProgressView()
        self.createPreviewLayerComponents()
        
        //Super important
        model.setupConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var camera = CameraType.back
    
    func reloadCamera() {
        //Change camera source
        if let session = model.session
        {
            //Indicate that some changes will be made to the session
            session.beginConfiguration()
            
            //Remove existing input
            if let currentCameraInput : AVCaptureInput? = self.frontOrBackCameraDeviceFromInputs(session)
            {
                session.removeInput(currentCameraInput)
                
                //Get new input
                var newCamera : AVCaptureDevice? = nil
                
                if let deviceInput : AVCaptureDeviceInput = currentCameraInput as? AVCaptureDeviceInput
                {
                    
                    if (deviceInput.device.position == .back)
                    {
                        newCamera = self.cameraWithPosition(.front)
                    }
                    else if (deviceInput.device.position == .front)
                    {
                        newCamera = self.cameraWithPosition(.back)
                    }
                    
                    var newVideoInput : AVCaptureDeviceInput? = nil
                    
                    do {
                        newVideoInput = try AVCaptureDeviceInput(device: newCamera)
                    } catch _ {
                        //Error handling, if needed  
                    }
                    
                    session.addInput(newVideoInput)
                    
                    session.commitConfiguration()
                }
            }
        }
    }

    func frontOrBackCameraDeviceFromInputs(_ session : AVCaptureSession) -> AVCaptureDeviceInput?
    {
        for (index, input) in session.inputs.enumerated() {
            print("Index and Device \(index): \(input)")
           
            if let device : AVCaptureDevice = input.device
            {
                if (device.localizedName == "Back Camera" || device.localizedName == "Front Camera")
                {
                    return input as? AVCaptureDeviceInput
                }
            }
        }
        
        return nil
    }
    
    func cameraWithPosition(_ position : AVCaptureDevicePosition) -> AVCaptureDevice?
    {
        let devices : NSArray = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for (index, device) in devices.enumerated() {
            print("Index and Device \(index): \(device)")
            if (device.position == position)
            {
                return device as? AVCaptureDevice
            }
        }
        
        return nil
    }
}//Ending Bracket

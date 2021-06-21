//
//  ViewController.swift
//  Credit Card Scanner
//
//  Created by Julian Martinez on 5/31/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let captureSession      = AVCaptureSession()
    private let videoDataOutput     = AVCaptureVideoDataOutput()
    
    private lazy var previewLayer   = AVCaptureVideoPreviewLayer(session: captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setCameraInput()
        setCameraOutput()
        showCameraFeed()
    }
    
    private func configureView() {
        view.backgroundColor = .systemTeal
    }
    
    private func setCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes : [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType   : .video,
            position    : .back
        ).devices.first else {
            print("This device does not support required input device")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(cameraInput)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func showCameraFeed() {
        previewLayer.videoGravity   = .resizeAspectFill
        previewLayer.frame          = view.frame
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func setCameraOutput() {
        videoDataOutput.videoSettings = [
            (kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)
        ] as [
            String : Any
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video) else {
            print("An error was encontered while unwrapping videoDataOutput connection.")
            return
        }
        
        connection.videoOrientation = .portrait
    }
}


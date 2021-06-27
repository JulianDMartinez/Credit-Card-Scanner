//
//  ViewController.swift
//  Credit Card Scanner
//
//  Created by Julian Martinez on 5/31/21.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    private let captureSession      = AVCaptureSession()
    private let videoDataOutput     = AVCaptureVideoDataOutput()
    private let maskLayer           = CAShapeLayer()
    
    private lazy var previewLayer   = AVCaptureVideoPreviewLayer(session: captureSession)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        configureVC()
        setCameraInput()
        setCameraOutput()
        showCameraFeed()
        
    }
    
    
    private func configureVC() {
        
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
    
    
    private func showCameraFeed() {
        
        previewLayer.videoGravity   = .resizeAspectFill
        previewLayer.frame          = view.frame
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
    }
    
    
    private func detectRectangle(in image: CVPixelBuffer) {
        
        let request = VNDetectRectanglesRequest { request, error in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRectangleObservation] else {
                    print("There was an error obtaining the rectangle observations.")
                    return
                }
                
                #warning("Missing remove mask function from tutorial.")
                
                guard let rect = results.first else {
                    print("There was an error encountered when seeking first memember of results")
                    return
                }
                

                
                print(rect)
                self.drawBoundingBox(rect: rect)
                
                #warning("Missing isTapped and doPerspectiveCorrection from tutorial.")
            }
        }
        
        request.minimumAspectRatio  = VNAspectRatio(1.3)
        request.maximumAspectRatio  = VNAspectRatio(1.6)
        request.minimumSize         = Float(0.5)
        request.maximumObservations = 1
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("The following error was encountered when trying to perform the request \(error)")
        }
        
    }
    
    private func drawBoundingBox(rect: VNRectangleObservation) {
        
        let transform   = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -previewLayer.frame.height)
        let scale       = CGAffineTransform.identity.scaledBy(x: previewLayer.frame.width, y: previewLayer.frame.height)
        let bounds      = rect.boundingBox.applying(scale).applying(transform)
        createLayer(in: bounds)
        
    }
    
    
    private func createLayer(in rect: CGRect) {
        
        maskLayer.frame         = rect
        maskLayer.cornerRadius  = 10
        maskLayer.opacity       = 0.75
        maskLayer.borderColor   = UIColor.red.cgColor
        maskLayer.borderWidth   = 5.0
        
        previewLayer.insertSublayer(maskLayer, at: 1)
    
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("Unable to get image from sample buffer.")
            return
        }
        
        detectRectangle(in: frame)
    }
}


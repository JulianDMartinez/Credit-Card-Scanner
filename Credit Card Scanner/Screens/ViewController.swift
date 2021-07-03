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
    private let outlineLayer        = CAShapeLayer()
    private let captureButton       = UIButton()
    private var detectedRectangle   = VNRectangleObservation()
    private var ciImage             = CIImage()
    
    private lazy var previewLayer   = AVCaptureVideoPreviewLayer(session: captureSession)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        configureVC()
        setCameraInput()
        setCameraOutput()
        showCameraFeed()
        setUpOutlineLayer()
        configureCaptureButton()
        
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
        
        previewLayer.frame          = view.frame
        previewLayer.videoGravity   = .resize
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
    }
    
    private func setUpOutlineLayer() {
        outlineLayer.frame = previewLayer.bounds
        previewLayer.insertSublayer(outlineLayer, at: 1)
    }
    
    private func configureCaptureButton() {
        view.addSubview(captureButton)
        
        let buttonHeight: CGFloat = 70
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: buttonHeight - 5, weight: .ultraLight)
        
        captureButton.setImage(UIImage(systemName: "camera.circle")?.applyingSymbolConfiguration(symbolConfiguration), for: .normal)
        captureButton.imageView?.tintColor  = .label
        captureButton.backgroundColor       = .systemGray6
        captureButton.layer.cornerRadius    = buttonHeight / 2
        
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -11),
            captureButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            captureButton.widthAnchor.constraint(equalToConstant: buttonHeight),
        ])
    }
    
    @objc func captureButtonTapped() {
        doPerspectiveCorrection(detectedRectangle, from: ciImage)
    }
    
    
    private func detectRectangle(in image: CVPixelBuffer) {
        
        ciImage = CIImage(cvPixelBuffer: image)
        
        let request = VNDetectRectanglesRequest { request, error in
            DispatchQueue.main.async { [self] in
                guard let results = request.results as? [VNRectangleObservation] else {
                    print("There was an error obtaining the rectangle observations.")
                    return
                }
                
//                #warning("Missing remove mask function from tutorial.")
                
                guard let rect = results.first else {
                    return
                }
                
                self.detectedRectangle = rect
                
                self.drawBoundingBox(rect: self.detectedRectangle)
                
//                #warning("Missing isTapped and doPerspectiveCorrection from tutorial.")
            }
        }
        
        request.minimumAspectRatio  = VNAspectRatio(1.3)
        request.maximumAspectRatio  = VNAspectRatio(1.6)
        request.minimumSize         = Float(0.4)
        request.maximumObservations = 1
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("The following error was encountered when trying to perform the request \(error)")
        }
        
    }
    
    private func doPerspectiveCorrection(_ observation: VNRectangleObservation, from ciImage: CIImage) {

        var image = ciImage
        
        let topLeft     = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight    = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft  = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)

        image = image.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft"      : CIVector(cgPoint: topLeft),
            "inputTopRight"     : CIVector(cgPoint: topRight),
            "inputBottomLeft"   : CIVector(cgPoint: bottomLeft),
            "inputBottomRight"  : CIVector(cgPoint: bottomRight)
        ])

        let context = CIContext()
        let cgImage = context.createCGImage(image, from: image.extent)
        let output  = UIImage(cgImage: cgImage!)
        
        UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil)
    }
    
    private func drawBoundingBox(rect: VNRectangleObservation) {
        
        let outlinePath = UIBezierPath()
        
        outlineLayer.lineCap        = .butt
        outlineLayer.lineJoin       = .round
        outlineLayer.lineWidth      = 5.0
        outlineLayer.strokeColor    = UIColor.systemYellow.cgColor
        outlineLayer.fillColor      = UIColor.systemYellow.withAlphaComponent(0.25).cgColor
        
        let bottomTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -previewLayer.frame.height)
        
        let topRight = VNImagePointForNormalizedPoint(rect.topRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height))
        let topLeft = VNImagePointForNormalizedPoint(rect.topLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height))
        let bottomRight = VNImagePointForNormalizedPoint(rect.bottomRight, Int(previewLayer.frame.width), Int(previewLayer.frame.height))
        let bottomLeft = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(previewLayer.frame.width), Int(previewLayer.frame.height))
        
        outlinePath.move(to: topLeft.applying(bottomTopTransform))
        
        outlinePath.addLine(to: topRight.applying(bottomTopTransform))
        outlinePath.addLine(to: bottomRight.applying(bottomTopTransform))
        outlinePath.addLine(to: bottomLeft.applying(bottomTopTransform))
        outlinePath.addLine(to: topLeft.applying(bottomTopTransform))
        outlinePath.addLine(to: topRight.applying(bottomTopTransform))
        
        outlineLayer.path = outlinePath.cgPath
        
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

extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}

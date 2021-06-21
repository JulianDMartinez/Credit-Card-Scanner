//
//  ViewController.swift
//  Credit Card Scanner
//
//  Created by Julian Martinez on 5/31/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = .systemTeal
    }
    
    private func setCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],mediaType: .video, position: .back).devices.first else {
            fatalError("No back camera device found.")
            }

    }
}


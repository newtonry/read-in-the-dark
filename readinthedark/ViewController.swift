//
//  ViewController.swift
//  readinthedark
//
//  Created by Ryan Newton on 11/21/17.
//  Copyright © 2017 Ryan Newton. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    var flashOn = false
    var captureDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeCamera()
    }

    func initializeCamera() {
        do {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()

            captureSession?.addInput(input)
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)


            captureSession?.startRunning()
            NSLog("DONE")
        } catch {
            print(error)
            return
        }
    }
    
    @IBAction func flashButton(_ sender: UIButton) {
        flashOn = !flashOn
        do {
            try captureDevice?.lockForConfiguration()
            captureDevice?.torchMode = flashOn ? .on : .off
        } catch {
            NSLog("There was some issue with lockForConfiguration")
        }
    }

}


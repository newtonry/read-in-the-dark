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
    var captureDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeCamera()
    }

    func initializeCamera() {
        do {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()

            captureSession.addInput(input)
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer)


            captureSession?.startRunning()
            
            // Lock for config. Move this
            do {
                try captureDevice.lockForConfiguration()
                
            } catch {
                NSLog("There was some issue with lockForConfiguration")
            }

            
        } catch {
            print(error)
            return
        }
    }
    
    
    @IBAction func onMakeBrighter(_ sender: UIButton) {
        // Handle min/max iso
        captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: 400, completionHandler: nil)
        NSLog("\(AVCaptureDevice.currentExposureDuration)")
        NSLog("\(AVCaptureDevice.currentISO)")
        NSLog("\(captureDevice.activeFormat.minISO)")
        NSLog("\(captureDevice.activeFormat.maxISO)")
    }
    
    @IBAction func flashButton(_ sender: UIButton) {
        flashOn = !flashOn
        captureDevice.torchMode = flashOn ? .on : .off
    }

}


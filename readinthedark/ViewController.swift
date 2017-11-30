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
    var lastTranslationX: CGFloat = 0
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
    
    func getNewISO(translation: CGPoint, velocity: CGPoint) -> Float {
        let offset = (translation.x - lastTranslationX) * 3 // TODO add something with velocity later
        var newISO = captureDevice.iso + Float(offset)
        newISO = max(newISO, captureDevice.activeFormat.minISO)
        newISO = min(newISO, captureDevice.activeFormat.maxISO)
        NSLog("\(newISO)")
        return newISO
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let velocity = sender.velocity(in: view)
        if sender.state == .changed {
            let newISO = getNewISO(translation: translation, velocity: velocity)
            captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: newISO, completionHandler: nil)            
            lastTranslationX = translation.x            
        } else if sender.state == .ended {
            lastTranslationX = 0
        }
    }
    
    @IBAction func flashButton(_ sender: UIButton) {
        flashOn = !flashOn
        captureDevice.torchMode = flashOn ? .on : .off
    }

}


//
//  ViewController.swift
//  readinthedark
//
//  Created by Ryan Newton on 11/21/17.
//  Copyright © 2017 Ryan Newton. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import TesseractOCR


class ViewController: UIViewController {
    
    @IBOutlet weak var readTextView: UILabel!
    @IBOutlet weak var previewView: UIView!
    var flashOn = false
    
    var requests = [VNRequest]()
    
    
    var lastTranslationX: CGFloat = 0
    var captureDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeCamera()
        startTextDetection()
    }

    func initializeCamera() {
        do {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))

            captureSession.addInput(input)
            captureSession.addOutput(output)
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
    
    
    
    // Tesseract
    func readImage(image: UIImage) {
        NSLog("Well SHIT")
        
        guard let tesseract = G8Tesseract(language: "eng") else {
            NSLog("Issues with tesseract")
            return
        }
        
        NSLog("Well SHIT 2")
        
        tesseract.engineMode = .tesseractCubeCombined
        
        tesseract.pageSegmentationMode = .auto
        
        NSLog("Tesseract set")
        
        
//        let testImage = UIImage(named: "Lenore3.png")
//        tesseract.image = testImage?.g8_blackAndWhite()
        tesseract.image = image.g8_blackAndWhite()
        
        NSLog("Tesseract recognzing")

        tesseract.recognize()

        
        if let recognizedText = tesseract.recognizedText {
            NSLog(recognizedText)
            DispatchQueue.main.async {
                self.readTextView.text = recognizedText
            }
        }
    }
    
    
    
    
    // Vision Kit
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.requests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        
        let result = observations.map({$0 as? VNTextObservation})
        
        NSLog("\(result)")
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
//        let translation = sender.translation(in: view)
//        let velocity = sender.velocity(in: view)
//        if sender.state == .changed {
//            let newISO = getNewISO(translation: translation, velocity: velocity)
//            captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: newISO, completionHandler: nil)
//            lastTranslationX = translation.x
//        } else if sender.state == .ended {
//            lastTranslationX = 0
//        }
    }
    
    @IBAction func flashButton(_ sender: UIButton) {
        flashOn = !flashOn
        captureDevice.torchMode = flashOn ? .on : .off
    }

}


// TODO Review all this
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func getImageFromBuffer(sampleBuffer: CMSampleBuffer, from connecrtion: AVCaptureConnection) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        // TODO review this
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        
        // TODO review this
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return
        }
        guard let cgImage = context.makeImage() else {
            return
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        
        readImage(image: image)
        
        
//
//
//        var requestOptions:[VNImageOption : Any] = [:]
//
//        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
//            requestOptions = [.cameraIntrinsics:camData]
//        }
//
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
//
//        do {
//            try imageRequestHandler.perform(self.requests)
//        } catch {
//            print(error)
//        }
    }
}


//
//  CameraController.swift
//  ICS224-Lab10
//
//  Created by ICS 224 on 2023-04-12.
//

import Foundation
import Photos
import UIKit

class CameraController : NSObject, AVCapturePhotoCaptureDelegate, ObservableObject
{
    var showCameraAlert = false
    var imageSource = UIImagePickerController.SourceType.camera
    var outputDevice = AVCapturePhotoOutput()
    @Published var image : UIImage = UIImage(systemName: "car")!
    @Published var pictureInterval : Double = 2.0
    
    public func openCamera(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video){
            response in
            if response && UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
                self.showCameraAlert = false
                self.imageSource = UIImagePickerController.SourceType.camera
            } else {
                self.showCameraAlert = true
            }
        }
    }
    
    public func createCaptureSession(){
        do {
            let captureSession = AVCaptureSession()
            let camera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices
            let inputDevice = try AVCaptureDeviceInput(device: camera[0])
            if (captureSession.canAddInput(inputDevice)){
                captureSession.addInput(inputDevice)
            }
            if (captureSession.canAddOutput(outputDevice)){
                captureSession.addOutput(outputDevice)
            }
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            DispatchQueue.global().async{
                captureSession.startRunning()
            }
        } catch {
            print("Caputure Failed \(error)")
        }
    }
    
    @objc public func handleTakePhoto(){
        let settings = AVCapturePhotoSettings()
        if let photoPreviewType = settings.availablePreviewPhotoPixelFormatTypes.first {
            settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            outputDevice.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        DispatchQueue.main.async {
            if error != nil {
                //self.errorMessage = error!.localizedDescription
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                //self.errorMessage = "No photo"
                return
            }
            self.image = UIImage(data: data) ?? UIImage(systemName: "car")!
        }
    }
    
}


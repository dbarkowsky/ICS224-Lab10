//
//  CameraController.swift
//  ICS224-Lab10
//
//  Created by ICS 224 on 2023-04-12.
//

import Foundation
import Photos
import UIKit


/// Class to handle camera controls and collecting photos
/// - imageSource : UIImagePickerController - The source of captured images.
/// - outputDevice : AVCapturePhotoOutput - The output where photos are captured.
/// - captureSession : AVCaptureSession - Current session for the capture device (camera)
/// - @Published image : UIImage - Image last taken by camera.
/// - @Published pictureInterval : Double - The time between photos taken.
class CameraController : NSObject, AVCapturePhotoCaptureDelegate, ObservableObject
{
    var imageSource = UIImagePickerController.SourceType.camera
    var outputDevice = AVCapturePhotoOutput()
    let captureSession = AVCaptureSession()
    @Published var image : UIImage = UIImage(systemName: "car")!
    @Published var pictureInterval : Double = 2.0
    
    /// Requests access to camera and provides prompt to user
    public func openCamera(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video){
            response in
            if response && UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
                self.imageSource = UIImagePickerController.SourceType.camera
            }
        }
    }
    
    /// Creates a capture session with the front video camera.
    /// Adds input and output devices to caputure session.
    ///  Starts the capture session.
    public func createCaptureSession(){
        do {
            // Try to disable the camera's shutter sound
            AudioServicesDisposeSystemSoundID(1108)
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
                self.captureSession.startRunning()
            }
        } catch {
            print("Capture Failed \(error)")
        }
    }
    
    /// Initializes capture settings.
    /// If the session is running, captures and returns a photo.
    @objc public func handleTakePhoto(){
        let settings = AVCapturePhotoSettings()
        if captureSession.isRunning {
            outputDevice.capturePhoto(with: settings, delegate: self)
        }
    }
    
    /// In the main thread, sets the class's image to the new photo.
    /// From AVCapturePhotoCaptureDelegate
    /// - Parameters:
    ///   - output: AVCapturePhotoOutput (The output source).
    ///   - photo: The current photo taken from the output.
    ///   - error: Possible errors from delegate.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        DispatchQueue.main.async {
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                print("No photo")
                return
            }
            self.image = UIImage(data: data) ?? UIImage(systemName: "car")!
        }
    }
}


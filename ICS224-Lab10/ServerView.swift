//
//  ServerView.swift
//  SampleServer
//
//  Created by Michael on 2023-02-02.
//

import SwiftUI
import MultipeerConnectivity
import Photos

struct ServerView: View {
    @StateObject var network = NetworkSupport(browse: true) // browser
    
    @State var message = ""
    @State var networkError = ""
    @State var reply = ""
    @State var selectedPeer : MCPeerID? = nil
    @State var pictureInterval : Double = 2.0
    @State var cameraOn : Bool = false
    @State var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    @State var pictureNum : Int = 0
    @State var imageSource = UIImagePickerController.SourceType.camera
    @State var showCameraAlert = false
    @State var image : UIImage = UIImage(systemName: "hare")!
    @State var outputDevice = AVCapturePhotoOutput()
//    @State var outputDevice : AVCapturePhotoOutput = nil
    var images : [UIImage] = [UIImage(imageLiteralResourceName: "kingdedede"), UIImage(systemName: "tortoise")!, UIImage(systemName: "ladybug")!]
    
    
    var pics = ["car", "hare", "tortoise"]
    
    var body: some View {
        VStack {
            if selectedPeer == nil || !cameraOn {
                Text("Choose a connection:")
                Button(action: {
                    if (selectedPeer != nil){
                        
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        if (status == .authorized){
                            cameraOn = true
                        } else {
                            AVCaptureDevice.requestAccess(for: AVMediaType.video){
                                response in
                                if response && UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
                                    self.showCameraAlert = false
                                    self.imageSource = UIImagePickerController.SourceType.camera
                                } else {
                                    self.showCameraAlert = true
                                }
                            }
                            if (status == .authorized){
                                cameraOn = true
                            }
                        }
                    }
                }){
                    Text("Start Camera")
                }
//                .alert(isPresented: $showCameraAlert){
//                    Alert(title: "Error", message: Text("Camera not available"), dismissButton: .default(Text("OK")))
//                }
                List(network.peers, id: \.self.hashValue) {
                    peer in
                    Button(action: {
                        networkError = ""
                        do {
                            try network.contact(peerID: peer, request: Request(placeholder: "SomePlaceholder"))
                            selectedPeer = peer
                        }
                        catch let error {
                            networkError = error.localizedDescription
                        }
                    }) {
                        Text(peer.displayName)
                    }
                }
            }
            else {
                
                HStack{
                    Text("\(Int(pictureInterval))")
                    Slider(value: $pictureInterval, in: 1...60, step: 1)
                }
                
                .onAppear {
                    Task {
                        
                        await sendPicture()
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
                    }
                }
                .onReceive(timer){
                    timerInput in
                    Task { await sendPicture() }
                }
                Button(action:{
                    selectedPeer = nil
                    cameraOn = false
                }){
                    Text("Stop Camera")
                }
                Image(uiImage: image).resizable().scaledToFit()
            }
            
            
        }
        .onChange(of: network.incomingMessage) { newValue in
            if let decodedMessage = try? JSONDecoder().decode(String.self, from: network.incomingMessage) {
                reply = decodedMessage
            }
        }
        .onChange(of: network.peers) { newValue in
            if network.peers.filter({$0 == selectedPeer}).count == 0 {
                selectedPeer = nil
            }
        }
        .padding()
        Text(networkError)
    }
    
    func takePicture(){
        print("in takePicture")
        let settings = AVCapturePhotoSettings()
        outputDevice.capturePhoto(with: settings, delegate: photoOutput(outputDevice, didFinishProcessingPhoto photo: AVCapturePhoto, error: "Error?" as! Error))
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        DispatchQueue.main.async{
            if error != nil {
                //self.errorMessage = error!.localizedDescription
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                //self.errorMessage = "No photo"
                return
            }
            self.image = UIImage(data: data)!
        }
    }
    
    func sendPicture(){
        Task {
            print("in sendPicture")
//            let settings = AVCapturePhotoSettings
//            outputDevice.capturePhoto(with: AVCapturePhotoSettings, delegate: <#T##AVCapturePhotoCaptureDelegate#>)
            if let message = try? JSONEncoder().encode(pics[Int(pictureNum % images.count)]), let peer = selectedPeer {
                network.send(message: images[Int(pictureNum % images.count)].pngData()!, to: [peer]) // TODO: put in camera info
            }
            pictureNum += 1
        }
    }
    
}



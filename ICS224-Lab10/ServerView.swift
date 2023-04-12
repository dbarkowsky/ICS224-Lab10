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
    @ObservedObject var camera : CameraController
    @State var message = ""
    @State var networkError = ""
    @State var reply = ""
    @State var selectedPeer : MCPeerID? = nil
    @State var cameraOn : Bool = false
    @State var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
  
    
    
    var images : [UIImage] = [UIImage(imageLiteralResourceName: "kingdedede"), UIImage(systemName: "tortoise")!, UIImage(systemName: "ladybug")!]
    @State var pictureNum : Int = 0
    @State var image : UIImage = UIImage(systemName: "hare")!
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
                            camera.openCamera()
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
                    Text("\(Int(camera.pictureInterval))")
                    Slider(value: $camera.pictureInterval, in: 1...60, step: 1)
                }
                
                .onAppear {
                    Task {
                        camera.createCaptureSession()
                        camera.handleTakePhoto()
                        sendPicture()
                    }
                }
                .onReceive(timer){
                    timerInput in
                    Task {
                        // get a new photo
                        camera.handleTakePhoto()
                        sendPicture()
                    }
                }
                Button(action:{
                    selectedPeer = nil
                    cameraOn = false
                }){
                    Text("Stop Camera")
                }
                Image(uiImage: camera.image).resizable().scaledToFit()
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
    

    
    func sendPicture(){
        Task {
            print("in sendPicture")
//            if let message = try? JSONEncoder().encode(pics[Int(pictureNum % images.count)]), let peer = selectedPeer {
//                network.send(message: images[Int(pictureNum % images.count)].pngData()!, to: [peer]) // TODO: put in camera info
//            }
            if let peer = selectedPeer {
                network.send(message: camera.image.pngData()!, to: [peer])
            }
            pictureNum += 1
        }
    }
    
}



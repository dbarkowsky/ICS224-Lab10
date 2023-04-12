
import SwiftUI
import MultipeerConnectivity
import Photos

/// View for the server. Handles peer connection selection, starting camera, and photo intervals.
/// - @StateObject network : NetworkSupport - Class that controls network connections.
/// - @ObservedObject camera : CameraController - Class that controls device camera.
/// - @State networkError : String - Description of network error.
/// - @State selectedPeer : MCPeerID - The connected peer, a client, who receives the photos.
/// - @State cameraOn : Bool - A boolean to detect whether the camera is authorized. Helps determine view selection.
/// - @State timer : Timer - A timer used to loop photo-taking process.
struct ServerView: View {
    @StateObject var network = NetworkSupport(browse: true) // browser
    @ObservedObject var camera : CameraController
    @State var networkError = ""
    @State var selectedPeer : MCPeerID? = nil
    @State var cameraOn : Bool = false
    @State var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // View when selecting network
            if selectedPeer == nil || !cameraOn {
                // Hide start button until peer is not nil
                if (selectedPeer != nil){
                    Button(action: {
                        let status = AVCaptureDevice.authorizationStatus(for: .video)
                        if (status == .authorized){
                            cameraOn = true
                        } else {
                            camera.openCamera()
                            if (status == .authorized){
                                cameraOn = true
                            }
                        }
                    }){
                        Text("Start Camera")
                    }.padding(.bottom, 3)
                }
                Text("Choose a connection:")
                // List identified peers
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
                // Show photo capture view
                HStack{
                    Text("\(Int(camera.pictureInterval))")
                    Slider(value: Binding(
                        get: {
                            camera.pictureInterval
                        },
                        set: {
                            newVal in
                            camera.pictureInterval = newVal
                            // Update timer interval from slider
                            timer = Timer.publish(every: camera.pictureInterval, on: .main, in: .common).autoconnect()
                        }), in: 1...60, step: 1)
                }
                
                .onAppear {
                    // Tries to send picture. Usually defaults to "Car" because camera isn't ready yet
                    Task {
                        camera.createCaptureSession()
                        camera.handleTakePhoto()
                        sendPicture(camera.image)
                    }
                }
                .onReceive(timer){
                    timerInput in
                    Task {
                        // get a new photo
                        camera.handleTakePhoto()
                        // Needs slight delay, otherwise camera.image isn't set yet.
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                            sendPicture(camera.image)
                        }
                        
                    }
                }
                Button(action:{
                    selectedPeer = nil
                    cameraOn = false
                }){
                    Text("Stop Camera")
                }
                VStack{
                    Image(uiImage: camera.image)
                        .resizable()
                        .scaledToFit()
                }
                .rotationEffect(.degrees(90))
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
    
    
    /// Takes a photo and sends it to a connected peer
    /// - Parameter photo: Photo to be sent to peer : UIImage
    public func sendPicture(_ photo: UIImage){
        Task {
            print("in sendPicture")
            if let peer = selectedPeer {
                network.send(message: photo.pngData()!, to: [peer])
            }
        }
    }
    
   
    
}




import SwiftUI


/// View container for Client side of Surveillance application, displays Images received from an outside source
/// - @StateObject network -  NetworkSupport class for managing and advertising connections to the device
/// - @State sourceImage - UIImage to display in the view, Images are received from the network
struct ClientView: View {
    @StateObject var network = NetworkSupport(browse: false) // advertiser
    @State var sourceImage : UIImage = UIImage(systemName: "tortoise")!
    var body: some View {
        VStack {
            if network.peers.count > 0 { //Number of connections to the device
                Text("Receiving Image")
                VStack {
                    VStack{
                        Spacer()
                        Image(uiImage: sourceImage)
                            .resizable()
                            .scaledToFit()
                            
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .rotationEffect(.degrees(180))
            } else {
                Text("No Connection")
            }
        }
        .onChange(of: network.incomingMessage) { newValue in
            sourceImage = UIImage(data: network.incomingMessage)!
        }
        .padding()
    }
}

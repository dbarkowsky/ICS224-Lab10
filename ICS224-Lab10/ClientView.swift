
import SwiftUI

struct ClientView: View {
    @StateObject var network = NetworkSupport(browse: false) // advertiser
    @State var message = ""
    @State var reply : UIImage = UIImage(systemName: "tortoise")!
    
    var body: some View {
        VStack {
            if network.peers.count > 0 {
                VStack {
                    Text("Receiving Image")
                    VStack{
                        Spacer()
                        Image(uiImage: reply)
                            .resizable()
                            .scaledToFit()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text("No Connection")
            }
        }
        .onChange(of: network.incomingMessage) { newValue in
//            if let decodedMessage = try? JSONDecoder().decode(String.self, from: network.incomingMessage) {
//                reply = decodedMessage
//            }
            reply = UIImage(data: network.incomingMessage)!
        }
        .padding()
    }
}

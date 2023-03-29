//
//  NetworkSupport.swift
//
//  Created by Michael on 2022-02-24.
//  For use in ICS 224.
//  Do NOT distribute.
//
//  Be sure to go to Product > Build Documentation in Xcode in order to read the formatted version of the documentation.
//

import Foundation
import MultipeerConnectivity
import os

/// The service type identifier.
/// Make this unique to the project to avoid interfering with other Multipeer services.
/// The identifier must only consist of lowercase characters and digits.
let serviceType = "mattdylan"

/// The maximum timeout, in seconds, to wait for a peer to respond to an invitation.
let timeout = 30

/// Describes browser requirements to an advertiser at setup time.
/// It is ok to use an arbitrary placeholder String, but eventually this *should* contain version information and other relevant data.
struct Request: Codable {
    /// A placeholder that is to be transmitted at setup time.
    var placeholder: String
}

/// This class supports Multipeer services.
/// There should be one browser and multiple advertisers.
/// Browser and advertiser status are set in ``init(browse:)``.
/// Confirm that if your ``serviceType`` is *xyz*, the project's "Info > Bonjour services" property contains the String *_xyz._tcp*.
/// The browser must connect to each advertiser using ``contact(peerID:request:)``.
/// Once connected, messages can be sent by either side using ``send(message:to:)``.
/// The observable ``peers``, ``incomingMessage``, and ``sender`` properties are updated by this class as needed.
/// Nothing else is needed to use this class.
class NetworkSupport: NSObject, ObservableObject {
    
    // MARK: - Internal Properties and Methods
    
    /// The local peer identifier.
    private var peerID: MCPeerID
    
    /// The current session.
    private var session: MCSession
    
    /// For an advertiser, provides access to the MCNearbyServiceAdvertiser; nil otherwise.
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    /// For a browser, provides access to the MCNearbyServiceBrowser; nil otherwise.
    private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    
    /// Adds the given peer to the ``peers`` array, if the peer is not yet in the array.
    /// The array is updated in a thread-safe manner.
    /// - Parameter peer: The peer to be added.
    private func add(peer: MCPeerID) {
        DispatchQueue.main.async {
            if !self.peers.contains(peer) {
                os_log("addPeer \(peer)")
                self.peers.append(peer)
            }
        }
    }

    /// Removes the given peer from the ``peers`` array, if the peer is in the array.
    /// The array is updated in a thread-safe manner.
    /// - Parameter peer: The peer to be removed.
    private func remove(peer: MCPeerID) {
        DispatchQueue.main.async {
            guard let index = self.peers.firstIndex(of: peer) else {
                return
            }
            os_log("removePeer")
            self.peers.remove(at: index)
        }
    }

    /// Stops browsing for peers.
    deinit {
        os_log("deinit")
        nearbyServiceBrowser?.stopBrowsingForPeers()
    }

    // MARK: - Public Properties and Methods
    
    /// Contains the list of peers.  In case of a browser, this array contains contacted and uncontacted peers.  It is up to the browser to keep track of which peers have and have not already been contacted via  ``contact(peerID:request:)``.
    @Published var peers: [MCPeerID] = [MCPeerID]()
    
    /// Contains the most recent incoming message.
    @Published var incomingMessage = Data()
    
    /// Contains the name of the sender of most recent incoming message.
    @Published var sender: MCPeerID?
    
    /// Creates a Multipeer advertiser or browser.
    /// - Parameter browse: true creates a browser, false creates an advertiser.
    init(browse: Bool) {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        if !browse {
            nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        }
        else {
            nearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        }
        
        super.init()
        
        session.delegate = self
        nearbyServiceAdvertiser?.delegate = self
        nearbyServiceBrowser?.delegate = self
        if browse {
            nearbyServiceBrowser?.startBrowsingForPeers()
        }
        else {
            nearbyServiceAdvertiser?.startAdvertisingPeer()
        }
    }

    /// Establishes a session with an advertiser.
    /// - Parameters:
    ///   - peerID: The peer ID of the advertiser.
    ///   - request: The connection request.  This can contain additional information that can be used by an advertiser to accept or reject a connection.
    func contact(peerID: MCPeerID, request: Request) throws {
        os_log("contactPeer \(peerID) \(request.placeholder)")
        let request = try JSONEncoder().encode(request)
        nearbyServiceBrowser?.invitePeer(peerID, to: session, withContext: request, timeout: TimeInterval(timeout))
    }

    /// Sends a message to the given peers.
    /// In case of an error, ``incomingMessage``, ``sender``, and ``peers`` array are all reset.
    /// This is done in a thread-safe manner.
    /// - Parameters
    ///   - message: The message that is to be transmitted.
    ///   - to: The list of peers that should receive the message; these peers must already have been contacted by the browser via ``contact(peerID:request:)``.
    func send(message: Data, to: [MCPeerID]) {
        if peers.count == 0 {
            return
        }
        
        do {
            try session.send(message, toPeers: to, with: .reliable)
            os_log("send \(message)")
        }
        catch let error {
            os_log("send \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.incomingMessage = Data()
                self.sender = nil
                self.peers.removeAll()
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate Methods.  Used Internally.

extension NetworkSupport : MCNearbyServiceAdvertiserDelegate {
    /// Delegate Method MCNearbyServiceAdvertiserDelegate.advertiser(_:didNotStartAdvertisingPeer:).
    /// Currently only logs.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        os_log("didNotStartAdvertisingPeer \(error.localizedDescription)")
    }
    
    /// Delegate Method MCNearbyServiceAdvertiserDelegate.advertiser(_:didReceiveInvitationFromPeer:withContext:invitationHandler:).
    /// Right now, all connection requests are accepted.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        do {
            let request = try JSONDecoder().decode(Request.self, from: context ?? Data())
            os_log("didReceiveInvitationFromPeer \(peerID.displayName) \(request.placeholder)")
            
            invitationHandler(true, self.session)
        }
        catch let error {
            os_log("didReceiveInvitationFromPeer \(error.localizedDescription)")
        }
    }
}
    
// MARK: - MCNearbyServiceBrowserDelegate Methods.  Used Internally.

extension NetworkSupport : MCNearbyServiceBrowserDelegate {
    /// Delegate Method MCNearbyServiceBrowserDelegate.browser(_:didNotStartBrowsingForPeers:).
    /// Currently only logs.
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        os_log("didNotStartBrowsingForPeers \(error.localizedDescription)")
    }
    
    /// Delegate Method MCNearbyServiceBrowserDelegate.browser(_:foundPeer:withDiscoveryInfo:).
    /// Adds the given peer to the ``peers`` array, if the peer is not yet in the array.
    /// The array is updated in a thread-safe manner.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let info2 = info?.description ?? ""
        os_log("foundPeer \(peerID) \(info2)")
        add(peer: peerID)
    }
    
    /// Delegate Method MCNearbyServiceBrowserDelegate.browser(_:lostPeer:).
    /// Removes the given peer from the ``peers`` array, if the peer is in the array.
    /// The array is updated in a thread-safe manner.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        os_log("lostPeer \(peerID)")
        remove(peer: peerID)
    }
}
    
// MARK: - MCSessionDelegate Methods. Used Internally.

extension NetworkSupport : MCSessionDelegate {
    /// Delegate Method MCSessionDelegate.session(_:didReceive:fromPeer:).
    /// Updates ``incomingMessage`` with the message that was just received and ``sender`` with the sender of the message.
    /// The ``incomingMessage`` and ``sender`` are updated in a thread-safe manner.
    func session(_ session: MCSession, didReceive: Data, fromPeer: MCPeerID) {
        os_log("didReceive \(didReceive) \(fromPeer)")
        DispatchQueue.main.async {
            self.incomingMessage = didReceive
            self.sender = fromPeer
        }
    }
    
    /// Delegate Method MCSessionDelegate.session(_:didStartReceivingResourceWithName:fromPeer:with:).
    /// Currently only logs.
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {
        os_log("didStartReceivingResourceWithName \(didStartReceivingResourceWithName) \(fromPeer) \(with)")
    }
    
    /// Delegate Method MCSessionDelegate.session(_:didFinishReceivingResourceWithName:fromPeer:at:withError:).
    /// Currently only logs.
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {
        let at2 = at?.description ?? ""
        let withError2 = withError?.localizedDescription ?? ""
        os_log("didFinishReceivingResourceWithName \(didFinishReceivingResourceWithName) \(fromPeer) \(at2) \(withError2)")
    }
    
    /// Delegate Method MCSessionDelegate.session(_:didReceive:withName:fromPeer:).
    /// Currently only logs.
    func session(_ session: MCSession, didReceive: InputStream, withName: String, fromPeer: MCPeerID) {
        os_log("didReceive:withName \(didReceive) \(withName) \(fromPeer)")
    }
    
    /// Delegate Method MCSessionDelegate.session(_:peer:didChange:).
    /// Updates the ``peers`` array, if a peer connected or disconnected.
    /// The array is updated in a thread-safe manner.
    func session(_ session: MCSession, peer: MCPeerID, didChange: MCSessionState) {
        switch didChange {
        case .notConnected:
            os_log("didChange notConnected \(peer)")
            remove(peer: peer)
        case .connecting:
            os_log("didChange connecting \(peer)")
        case .connected:
            os_log("didChange connected \(peer)")
            add(peer: peer)
        default:
            os_log("didChange \(peer)")
        }
    }
    
    /// Delegate Method MCSessionDelegate.session(_:didReceiveCertificate:fromPeer:certificateHandler:).
    /// Currently accepts all certificates.
    func session(_ session: MCSession, didReceiveCertificate: [Any]?, fromPeer: MCPeerID, certificateHandler: (Bool) -> Void) {
        let didReceiveCertificate2 = didReceiveCertificate?.description ?? ""
        os_log("didReceiveCertificate \(didReceiveCertificate2) \(fromPeer)")
        certificateHandler(true)
    }
}

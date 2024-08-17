//
//  TouchDebugService.swift
//  TouchDebugTool
//
//  Created by Spotlight Deveaux on 2024-08-16.
//

import Foundation
import IOBluetooth
import OSLog

extension SDPAttributeIdentifierCodes {
    /// Simple helper to help syntax remain vaguely clean while operating with attribute identifiers.
    static func + (lhs: SDPAttributeIdentifierCodes, rhs: UInt32) -> SDPAttributeIdentifierCodes {
        let originalValue = lhs.rawValue
        let newValue = originalValue + rhs
        return SDPAttributeIdentifierCodes(rawValue: newValue)
    }

    /// A hack to return a string value for usage within a service definition dictionary.
    var key: String {
        "\(rawValue)"
    }
}

/// Syntatic sugar.
extension BluetoothSDPUUID16 {
    static let l2cap = BluetoothSDPUUID16(kBluetoothSDPUUID16L2CAP)
    static let rfcomm = BluetoothSDPUUID16(kBluetoothSDPUUID16RFCOMM)
}

let serviceLogger = Logger(subsystem: "space.joscomputing.TouchDebugTool", category: "ServiceDiscovery")

/// Our Touch Debug Service has a specific UUID, `718b484e-ed00-416a-b19a-e80b32c1b477`.
let DEBUG_SERVICE_UUID = Data([0x71, 0x8B, 0x48, 0x4E, 0xED, 0x00, 0x41, 0x6A, 0xB1, 0x9A, 0xE8, 0x0B, 0x32, 0xC1, 0xB4, 0x77])

/// Registers our touch debug service with the system SDP server..
func registerService() {
    // Per documentation, name attributes must be offset by a language code.
    // Per searching, the language base is 0x100. (This is not documented within Apple SDKs.)
    let kBluetoothEnglishBase: UInt32 = 0x100
    let kBluetoothServiceEnglishName = kBluetoothSDPAttributeIdentifierServiceName + kBluetoothEnglishBase

    // We have a special 128-bit UUID used: "718b484e-ed00-416a-b19a-e80b32c1b477".
    let serviceUUID = IOBluetoothSDPUUID(data: DEBUG_SERVICE_UUID)

    let serviceDefinition: [String: AnyObject] = [
        // We don't really need to set a name, but we are anyway :)
        kBluetoothServiceEnglishName.key: "Touch Debug Profile" as NSString,
        // We only register our special service UUID.
        kBluetoothSDPAttributeIdentifierServiceClassIDList.key: [serviceUUID] as NSArray,
        // Specify that we're really RFCOMM.
        // Per Chromium's Bluetooth source, specifying a channel ID of 0 will allow automatic allocation:
        // https://github.com/chromium/chromium/blob/929422a714385ad8b884bab67290197d77a8f2af/device/bluetooth/bluetooth_socket_mac.mm#L303-L321
        kBluetoothSDPAttributeIdentifierProtocolDescriptorList.key: [
            [IOBluetoothSDPUUID(uuid16: BluetoothSDPUUID16.l2cap)!],
            [
                IOBluetoothSDPUUID(uuid16: BluetoothSDPUUID16.rfcomm)!,
                // Refer to the header of the `IOBluetoothSDPDataElement` class
                // for information on this dictionary's format.
                // Here, we specify a channel ID of zero for automatic allocation.
                [
                    "DataElementType": kBluetoothSDPDataElementTypeUnsignedInt,
                    "DataElementSize": 1,
                    "DataElementValue": 0,
                ],
            ],
        ] as NSArray,
    ]

    // Publish our service for all new devices to obtain.
    IOBluetoothSDPServiceRecord.publishedServiceRecord(with: serviceDefinition)
}

class TouchDebugService {
    let protocolHandler = TouchDebugProtocol()
    var rfcommChannel: IOBluetoothRFCOMMChannel?

    /// Begins watching for Bluetooth devices to connect.
    func beginWatching() {
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(connected(notification:device:)))
    }

    @objc func connected(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard let nameOrAddress = device.nameOrAddress else {
            serviceLogger.info("Device without name or address found! Ignoring.")
            return
        }

        serviceLogger.info("Device connected: \(nameOrAddress)")

        // Determine whether this device also has the debug profile.
        let serviceRecord = device.getServiceRecord(for: IOBluetoothSDPUUID(data: DEBUG_SERVICE_UUID))
        guard let serviceRecord else {
            serviceLogger.info("Device lacks touch debug profile, ignoring.")
            return
        }

        serviceLogger.debug("Found service record: \(serviceRecord, privacy: .public)")

        // Determine if we were allocated an RFCOMM channel.
        var channelId: BluetoothRFCOMMChannelID = 0
        let channelStatus = serviceRecord.getRFCOMMChannelID(&channelId)
        guard channelStatus == kIOReturnSuccess else {
            serviceLogger.error("Failed to determine RFCOMM channel ID: \(channelStatus, privacy: .public)")
            return
        }

        serviceLogger.debug("Allocated RFCOMM channel is \(channelId, privacy: .public)")

        let openStatus = device.openRFCOMMChannelAsync(&rfcommChannel, withChannelID: channelId, delegate: protocolHandler)
        guard openStatus == kIOReturnSuccess else {
            serviceLogger.error("Failed to open RFCOMM channel: \(openStatus, privacy: .public)")
            return
        }

        // We'll keep track of this device. Register for disconnect notifications.
        device.register(forDisconnectNotification: self, selector: #selector(disconnected(notification:device:)))
    }

    @objc func disconnected(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        let nameOrAddress = device.nameOrAddress ?? "Unknown name or address"

        print("Device disconnected: \(nameOrAddress)")
        notification.unregister()
    }

    func write(_ data: Data) {
        guard let rfcommChannel else {
            print("Cannot write data when channel is not open!")
            return
        }

        var lol = data
        rfcommChannel.writeSync(&lol, length: UInt16(lol.count))
    }
}

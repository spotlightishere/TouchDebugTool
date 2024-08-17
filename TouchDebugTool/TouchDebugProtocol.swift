//
//  TouchDebugProtocol.swift
//  TouchDebugTool
//
//  Created by Spotlight Deveaux on 2024-08-16.
//

import Foundation
import IOBluetooth
import OSLog

let protocolLogger = Logger(subsystem: "space.joscomputing.TouchDebugTool", category: "Debug Protocol")

extension Data {
    var hex: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

class TouchDebugProtocol: IOBluetoothRFCOMMChannelDelegate {
    func rfcommChannelData(_: IOBluetoothRFCOMMChannel, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let returnedData = Data(bytes: dataPointer, count: dataLength)
        protocolLogger.debug("Got data with length \(dataLength, privacy: .public): \(returnedData.hex, privacy: .public)")
    }

    func rfcommChannelOpenComplete(_: IOBluetoothRFCOMMChannel, status error: IOReturn) {
        protocolLogger.debug("Channel open status: \(error, privacy: .public)")
    }

    func rfcommChannelClosed(_: IOBluetoothRFCOMMChannel) {
        protocolLogger.debug("Channel closed!")
    }

    func rfcommChannelControlSignalsChanged(_: IOBluetoothRFCOMMChannel) {
        protocolLogger.debug("Signals changed!")
    }

    func rfcommChannelFlowControlChanged(_: IOBluetoothRFCOMMChannel) {
        protocolLogger.debug("Flow control changed!")
    }
}

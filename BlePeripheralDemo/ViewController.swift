//
//  ViewController.swift
//  BlePeripheralDemo
//
//  Created by Djordje Ljubinkovic on 8/6/18.
//  Copyright © 2018 ljubinkovicdj. All rights reserved.
//

import UIKit
import CoreBluetooth

// This app will act as a peripheral device.
class ViewController: UIViewController {

	@IBOutlet weak var isAdvertisingLabel: UILabel!

	var gattWrapper: GattWrapper?
	var cadencePeripheralManager: CBPeripheralManager?

	// MARK: - Lifecycle Events
	override func viewDidLoad() {
		super.viewDidLoad()

		cadencePeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

		guard let cadencePeripheralManager = cadencePeripheralManager else {
			return
		}

		gattWrapper = GattWrapper()

		cadencePeripheralManager.delegate = self
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		cadencePeripheralManager!.stopAdvertising()
	}

	@IBAction func openCloseCaseButtonTapped(_ sender: UIButton) {

	}
}

extension ViewController: CBPeripheralManagerDelegate {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		if peripheral.state != CBManagerState.poweredOn {
			isAdvertisingLabel.text = "Not advertising, please turn on bluetooth."
			cadencePeripheralManager!.stopAdvertising()
			return
		}

		guard var gattWrapper = gattWrapper else {
			fatalError("GattWrapper not initialized!")
		}

		gattWrapper.addService(of: GattService.cadenceCase)
		gattWrapper.addService(of: GattService.cadenceBlisterPack)

		// fires peripheralManager didAdd service
		gattWrapper.publishServicesCharacteristicsToDatabase(&cadencePeripheralManager!)

		// fires peripheralManagerDidStartAdvertising
		gattWrapper.advertiseDataFromPeripheral(&cadencePeripheralManager!)
	}

	// Optional methods
	// Adding Services - called after publishing services to the device's database.
	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
		if let error = error {
			print("Error publishing service: \(error.localizedDescription)")
			return
		}

		print("PUBLISH CALLED!!!\n")
		print("Cadence peripheral has the following service: \(service)\n")
	}

	// Advertising Peripheral Data - called after the peripheral manager starts advertising.
	func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
		if let error = error {
			print("Error advertising: \(error.localizedDescription)")
			return
		}

		// Once you begin advertising data, remote centrals can discover and initiate a connection with you.
		if peripheral.isAdvertising {
			print("Cadence peripheral is advertising!")
			isAdvertisingLabel.text = "I AM ADVERTISING!"
		}
	}

	// Monitoring Subscriptions to Characteristic Values
	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {}
	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {}
	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {}

	// Receiving read and write requests
	// When a connected central requests to read the value of one of your characteristics, the peripheral manager calls the peripheralManager:didReceiveReadRequest: method of its delegate object. The delegate method delivers the request to you in the form of a CBATTRequest object, which has a number of properties that you can use to fulfill the request.
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {

		if request.characteristic.uuid.isEqual(GattCharacteristicId.cadenceCaseOpenClosedUUID) { // returns 1 bit in hex format 0x00 and 0x01
			if let cadenceCaseEventsDataValue = gattWrapper?.getCharacteristic(from: GattServiceId.cadenceCaseUUID,
																			   with: GattCharacteristicId.cadenceCaseOpenClosedUUID)?.value {
				if request.offset > cadenceCaseEventsDataValue.count {
					cadencePeripheralManager!.respond(to: request,
													  withResult: CBATTError.invalidOffset)
				}
			}
			let bytes: [CChar] = [0x01]
			let nsData = NSData.init(bytes: bytes, length: 1)
			let dataToSend = Data(referencing: nsData)

			request.value = dataToSend

			// After you set the value, respond to the remote central to indicate that the request was successfully fulfilled.
			// Do so by calling the respondToRequest:withResult: method of the CBPeripheralManager class, passing back the request (whose value you updated) and the result of the request:

			// Call the respondToRequest:withResult: method exactly once each time the peripheralManager:didReceiveReadRequest: delegate method is called.
			cadencePeripheralManager!.respond(to: request, withResult: CBATTError.success)
		}

		// If the characteristics’ UUIDs do not match, or if the read can not be completed for any other reason, you would not attempt to fulfill the request. Instead, you would call the respondToRequest:withResult: method immediately and provide a result that indicated the cause of the failure. For a list of the possible results you may specify, see the CBATTError Constants enumeration in Core Bluetooth Constants Reference.
		cadencePeripheralManager!.respond(to: request, withResult: CBATTError.attributeNotFound)
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {}
}

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

	var cadencePeripheralManager: CBPeripheralManager?

	// MARK: - CURRENT TIME SERVICE
	let currentTimeServiceUUID = CBUUID(string: "1805")
	// current time service characteristics
	let currentTimeUUID = CBUUID(string: "2A2B")

	// MARK: - CADENCE CASE SERVICE
	let cadenceBetaTestCaseUUID = CBUUID(string: "66CF34AF-224D-4A34-A90F-955F816ABE02")
	// characteristics
	/**
	Notifies the client when the case state change (open vs. closed) has been detected

	properties: [notify, read]

	return: hex
	*/
	let caseEventsUUID = CBUUID(string: "651FD921-CADD-4B3F-816E-BF80285C496E")

	// MARK: - CADENCE BLISTER PACK (FOIL) DETECTION SERVICE
	let cadenceBlisterPackDetectionUUID = CBUUID(string: "A0DD7243-53AE-42F9-BF2B-5981D5C30EA6")
	// characteristics
	/**
	Notifies the client when the blister pack has been placed / removed

	properties: [notify, read]

	return: hex
	*/
	let blisterPackEventsUUID = CBUUID(string: "4DE63F41-3C3F-4A56-9875-A723BF4BE3A3")
	/**
	Enable / Disable blister pack detection. If battery is low, the case will auto disable and notify the client. The client may turn it back on if it wishes.

	properties: [notify, write, read]

	return: bool
	*/
	let blisterPackIsDetectingUUID = CBUUID(string: "CFEC9272-B8AF-4F9D-9B5E-2788CC1925EF")

	var cadenceCaseService: CBMutableService!
	var cadenceBlisterPackDetectionService: CBMutableService!

	// MARK: - Lifecycle Events
	override func viewDidLoad() {
		super.viewDidLoad()

		cadencePeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

		guard let cadencePeripheralManager = cadencePeripheralManager else {
			return
		}

		cadencePeripheralManager.delegate = self

//		// Cadence Case Service(Characteristics)
//		cadenceCaseService = CBMutableService(type: cadenceBetaTestCaseUUID, primary: true)
//		// If you specify a value for the characteristic, the value is cached and its properties and permissions are set to be readable. Therefore, if you need the value of a characteristic to be writeable, or if you expect the value to change during the lifetime of the published service to which the characteristic belongs, you must specify the value to be nil. Following this approach ensures that the value is treated dynamically and requested by the peripheral manager whenever the peripheral manager receives a read or write request from a connected central.
//		let cadenceCaseEventsCharacteristic = CBMutableCharacteristic(type: caseEventsUUID,
//																	  properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.read],
//																	  value: nil,
//																	  permissions: [CBAttributePermissions.readable])
//		cadenceCaseService.characteristics = [cadenceCaseEventsCharacteristic]
//
//		// Cadence Blister Pack Detection Service(Characteristics)
//		cadenceBlisterPackDetectionService = CBMutableService(type: cadenceBlisterPackDetectionUUID, primary: true) // change to false??
//		let cadenceBlisterPackEventsCharacteristic = CBMutableCharacteristic(type: blisterPackEventsUUID,
//																			 properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.read],
//																			 value: nil,
//																			 permissions: [CBAttributePermissions.readable])
//		let cadenceBlisterPackIsDetectingCharacteristics = CBMutableCharacteristic(type: blisterPackIsDetectingUUID,
//																				   properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.write, CBCharacteristicProperties.read],
//																				   value: nil,
//																				   permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
//		cadenceBlisterPackDetectionService.characteristics = [cadenceBlisterPackEventsCharacteristic, cadenceBlisterPackIsDetectingCharacteristics]

//		// Publish services and characteristics to the device's database.
//		cadencePeripheralManager.add(cadenceCaseService) // fires peripheralManager didAdd service
//		cadencePeripheralManager.add(cadenceBlisterPackDetectionService) // fires peripheralManager didAdd service
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		cadencePeripheralManager!.stopAdvertising()
	}
}

extension ViewController: CBPeripheralManagerDelegate {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		if peripheral.state != CBManagerState.poweredOn {
//			fatalError("Turn your bluetooth on!")
			isAdvertisingLabel.text = "Not advertising, please turn on bluetooth."
			cadencePeripheralManager!.stopAdvertising()
			return
		}

		// Cadence Case Service(Characteristics)
		cadenceCaseService = CBMutableService(type: cadenceBetaTestCaseUUID, primary: true)
		// If you specify a value for the characteristic, the value is cached and its properties and permissions are set to be readable. Therefore, if you need the value of a characteristic to be writeable, or if you expect the value to change during the lifetime of the published service to which the characteristic belongs, you must specify the value to be nil. Following this approach ensures that the value is treated dynamically and requested by the peripheral manager whenever the peripheral manager receives a read or write request from a connected central.
		let cadenceCaseEventsCharacteristic = CBMutableCharacteristic(type: caseEventsUUID,
																	  properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.read],
																	  value: nil,
																	  permissions: [CBAttributePermissions.readable])
		cadenceCaseService.characteristics = [cadenceCaseEventsCharacteristic]

		// Cadence Blister Pack Detection Service(Characteristics)
		cadenceBlisterPackDetectionService = CBMutableService(type: cadenceBlisterPackDetectionUUID, primary: true) // change to false??
		let cadenceBlisterPackEventsCharacteristic = CBMutableCharacteristic(type: blisterPackEventsUUID,
																			 properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.read],
																			 value: nil,
																			 permissions: [CBAttributePermissions.readable])
		let cadenceBlisterPackIsDetectingCharacteristics = CBMutableCharacteristic(type: blisterPackIsDetectingUUID,
																				   properties: [CBCharacteristicProperties.notify, CBCharacteristicProperties.write, CBCharacteristicProperties.read],
																				   value: nil,
																				   permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
		cadenceBlisterPackDetectionService.characteristics = [cadenceBlisterPackEventsCharacteristic, cadenceBlisterPackIsDetectingCharacteristics]

		// Publish services and characteristics to the device's database.
		cadencePeripheralManager!.add(cadenceCaseService) // fires peripheralManager didAdd service
		cadencePeripheralManager!.add(cadenceBlisterPackDetectionService) // fires peripheralManager didAdd service

		// CBAdvertisementDataServiceUUIDsKey
		let advertisementData = [
			CBAdvertisementDataServiceUUIDsKey: [cadenceCaseService.uuid, cadenceBlisterPackDetectionService.uuid]
		]

		peripheral.startAdvertising(advertisementData) // fires peripheralManagerDidStartAdvertising
	}

	// Optional methods
	// Adding Services - called after publishing services to the device's database.
	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
		if let error = error {
			print("Error publishing service: \(error.localizedDescription)")
			return
		}

		print("Cadence peripheral has the following service: \(service)")
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
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {}
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {}
}

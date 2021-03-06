//
//  BleWrapper.swift
//  BlePeripheralDemo
//
//  Created by Djordje Ljubinkovic on 8/7/18.
//  Copyright © 2018 ljubinkovicdj. All rights reserved.
//

import UIKit
import CoreBluetooth

enum GattServiceId {
	static let currentTimeUUID = CBUUID(string: "1805")

	static let cadenceCaseUUID = CBUUID(string: "66CF34AF-224D-4A34-A90F-955F816ABE02")

	static let cadenceBlisterPackUUID = CBUUID(string: "A0DD7243-53AE-42F9-BF2B-5981D5C30EA6")
}

enum GattCharacteristicId {
	static let currentTimeDisplayUUID = CBUUID(string: "2A2B")

	static let cadenceCaseOpenClosedUUID = CBUUID(string: "651FD921-CADD-4B3F-816E-BF80285C496E")

	static let cadenceBlisterPackPlacedRemovedUUID = CBUUID(string: "4DE63F41-3C3F-4A56-9875-A723BF4BE3A3")
	static let cadenceBlisterPackDetectionUUID = CBUUID(string: "CFEC9272-B8AF-4F9D-9B5E-2788CC1925EF")
}

enum GattService {
	case currentTime
	case cadenceCase
	case cadenceBlisterPack
}

enum GattCharacteristic {
	case currentTimeDisplay
	case cadenceCaseEvents
	case cadenceBlisterPackEvents
}

struct GattWrapper {

	private var gattAttributes: [CBMutableService: [CBCharacteristic]] = [:]

	mutating func addService(of serviceType: GattService) {
		let service = createService(of: serviceType)
		self.gattAttributes[service] = service.characteristics
	}

	func printGattAttributes() {
		for (service, characteristics) in gattAttributes {
			print("HERE IS THE PRINTOUT:\n\n\nService: \(service.description)\nCharacteristics: \(characteristics.description)\n")
		}
	}

	func getCharacteristic(from serviceId: CBUUID, with characteristicId: CBUUID) -> CBMutableCharacteristic? {
		for (service, characteristics) in gattAttributes {
			if service.uuid == serviceId {
				for characteristic in characteristics {
					if characteristic.uuid == characteristicId {
						return characteristic as? CBMutableCharacteristic
					}
				}
			}
		}
		return nil
	}

	func publishServicesCharacteristicsToDatabase(_ peripheralManager: inout CBPeripheralManager) {
		guard !self.gattAttributes.isEmpty else { fatalError("GATT Attributes are empty! Call init(serviceType: GattService) first!") }

		for (service, _) in gattAttributes {
			peripheralManager.add(service)
		}

	}

	func advertiseDataFromPeripheral(_ peripheralManager: inout CBPeripheralManager) {
		guard !self.gattAttributes.isEmpty else { fatalError("GATT Attributes are empty! Call init(serviceType: GattService) first!") }

		var serviceUUIDs: [CBUUID] = []

		for (service, _) in gattAttributes {
			serviceUUIDs.append(service.uuid)
		}

		// CBAdvertisementDataServiceUUIDsKey
		let advertisementData = [
			CBAdvertisementDataServiceUUIDsKey: serviceUUIDs
		]

		peripheralManager.startAdvertising(advertisementData) // fires peripheralManagerDidStartAdvertising
	}

	func stopAdvertisingDataFromPeripheral(_ peripheralManager: inout CBPeripheralManager) {
		peripheralManager.stopAdvertising()
	}

	private func createService(of serviceType: GattService) -> CBMutableService {
		var isPrimary = false
		var serviceUUID: CBUUID
		var characteristicType: GattCharacteristic

		switch serviceType {
		case .cadenceBlisterPack:
			isPrimary = true
			serviceUUID = GattServiceId.cadenceBlisterPackUUID
			characteristicType = GattCharacteristic.cadenceBlisterPackEvents
		case .cadenceCase:
			isPrimary = true
			serviceUUID = GattServiceId.cadenceCaseUUID
			characteristicType = GattCharacteristic.cadenceCaseEvents
		case .currentTime:
			isPrimary = false
			serviceUUID = GattServiceId.currentTimeUUID
			characteristicType = GattCharacteristic.currentTimeDisplay
		}

		let cadenceService = CBMutableService(type: serviceUUID,
											  primary: isPrimary)
		cadenceService.characteristics = createCharacteristic(of: characteristicType)
		return cadenceService
	}

	private func createCharacteristic(of characteristicType: GattCharacteristic) -> [CBMutableCharacteristic] {
		switch characteristicType {
		case .cadenceBlisterPackEvents:
			return [
				CBMutableCharacteristic(type: GattCharacteristicId.cadenceBlisterPackPlacedRemovedUUID,
										properties: [.notify, .write, .read],
										value: nil,
										permissions: [.readable, .writeable]),
				CBMutableCharacteristic(type: GattCharacteristicId.cadenceBlisterPackDetectionUUID,
										properties: [.notify, .read],
										value: nil,
										permissions: [.readable])
			]
		case .cadenceCaseEvents:
			return [
				CBMutableCharacteristic(type: GattCharacteristicId.cadenceCaseOpenClosedUUID,
										properties: [.notify, .read],
										value: nil,
										permissions: [.readable])
			]
		case .currentTimeDisplay:
			return [
				CBMutableCharacteristic(type: GattCharacteristicId.currentTimeDisplayUUID,
										properties: [.notify, .read],
										value: nil,
										permissions: [.readable])
			]
		}
	}
}

















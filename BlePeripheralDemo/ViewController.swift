//
//  ViewController.swift
//  BlePeripheralDemo
//
//  Created by Djordje Ljubinkovic on 8/6/18.
//  Copyright © 2018 ljubinkovicdj. All rights reserved.
//

import UIKit
import CoreBluetooth

extension UIView{
	func blink() {
		self.alpha = 0.2
		UIView.animate(withDuration: 1, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: {self.alpha = 1.0}, completion: nil)
	}
}

// This app will act as a peripheral device.
class ViewController: UIViewController {

	@IBOutlet weak var pairButton: UIButton!

	@IBOutlet weak var takePillButton: UIButton!

	@IBOutlet weak var medicationEventLightView: UIView!
	@IBOutlet weak var casePairedEventLightView: UIView!
	@IBOutlet weak var batteryLowEventLightView: UIView!

	@IBOutlet weak var dataFromCentralLabel: UILabel!

	var isOpenCase: Bool = false
	var isPaired: Bool = false

	var gattWrapper: GattWrapper?
	var cadencePeripheralManager: CBPeripheralManager?

	var stringFromCentral: [String] = []

	// MARK: - Lifecycle Events
	override func viewDidLoad() {
		super.viewDidLoad()

		pairButton.alpha = isOpenCase ? 1.0 : 0.0
		takePillButton.alpha = (isOpenCase && isPaired) ? 1.0 : 0.0
		medicationEventLightView.alpha = 0.0
		casePairedEventLightView.alpha = 0.0
		batteryLowEventLightView.alpha = 0.0

		dataFromCentralLabel.text = ""

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
		isOpenCase = !isOpenCase

		sender.setTitle(isOpenCase ? "Close the case" : "Open the case", for: .normal)

		//		self.pairButton.isHidden = !self.isOpenCase
		//		self.takePillButton.isHidden = !self.isOpenCase || !self.isPaired

		UIView.animate(withDuration: 1.1) {
			self.view.backgroundColor = self.isOpenCase ? UIColor.white : UIColor.black
			self.dataFromCentralLabel.textColor = self.isOpenCase ? UIColor.black : UIColor.white
			self.pairButton.alpha = self.isOpenCase ? 1.0 : 0.0
			self.takePillButton.alpha = (self.isOpenCase && self.isPaired) ? 1.0 : 0.0
		}

		// Send updated values to subscribed centrals
		// Get the updated value of the characteristic and send it to the central by calling the updateValue:forCharacteristic:onSubscribedCentrals: method of the CBPeripheralManager class.
		let updatedValue: [CChar] = isOpenCase ? [0x01] : [0x00]

		let nsData = NSData.init(bytes: updatedValue, length: 1)
		let dataToSend = Data(referencing: nsData)

		let didSendValue = cadencePeripheralManager?.updateValue(dataToSend,
																 for: gattWrapper!.getCharacteristic(from: GattServiceId.cadenceCaseUUID,
																									 with: GattCharacteristicId.cadenceCaseOpenClosedUUID)!,
																 onSubscribedCentrals: nil) // <CBCentral: 0x1c047a9c0 identifier = 72DE6DBD-6AB2-DDFB-2FC8-B714C2B9C8C1, MTU = 182> from peripheralManager:central:didSubscribeToCharacteristic: method.
		print("didSendValue: \(didSendValue)")
	}

	@IBAction func pairDeviceButtonTapped(_ sender: UIButton) {
		if (!isPaired) {
			isPaired = true
			// fires peripheralManagerDidStartAdvertising
			gattWrapper?.advertiseDataFromPeripheral(&cadencePeripheralManager!)
			casePairedEventLightView.isHidden = false
			casePairedEventLightView.blink()
		} else {
			isPaired = false
			gattWrapper?.stopAdvertisingDataFromPeripheral(&cadencePeripheralManager!)
			casePairedEventLightView.isHidden = true
			pairButton.setTitle("Pair", for: .normal)
		}
		UIView.animate(withDuration: 1.1) {
			self.takePillButton.alpha = (self.isOpenCase && self.isPaired) ? 1.0 : 0.0
		}
	}

	@IBAction func takePillButtonTapped(_ sender: UIButton) {
		let dateToSend = Date()

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		let dateString = dateFormatter.string(from: dateToSend)

		if let dataToSend = dateString.data(using: .utf8) {
			let convertedData = String(data: dataToSend, encoding: .utf8)
			print("dataToSend: \(convertedData!)")
			let didSendValue = cadencePeripheralManager?.updateValue(dataToSend,
																	 for: gattWrapper!.getCharacteristic(from: GattServiceId.cadenceBlisterPackUUID,
																										 with: GattCharacteristicId.cadenceBlisterPackPlacedRemovedUUID)!,
																	 onSubscribedCentrals: nil) // <CBCentral: 0x1c047a9c0 identifier = 72DE6DBD-6AB2-DDFB-2FC8-B714C2B9C8C1, MTU = 182> from peripheralManager:central:didSubscribeToCharacteristic: method.
			print("Should be true: \(didSendValue!)")
		}
	}

	@IBAction func clearCentralDataLabelTapped(_ sender: Any) {
		stringFromCentral = []
		dataFromCentralLabel.text = ""
	}
}

extension ViewController: CBPeripheralManagerDelegate {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		if peripheral.state != CBManagerState.poweredOn {
			cadencePeripheralManager!.stopAdvertising()
			return
		}

		gattWrapper?.addService(of: GattService.cadenceCase)
		gattWrapper?.addService(of: GattService.cadenceBlisterPack)

		// fires peripheralManager didAdd service
		gattWrapper?.publishServicesCharacteristicsToDatabase(&cadencePeripheralManager!)

		//		// fires peripheralManagerDidStartAdvertising
		//		gattWrapper?.advertiseDataFromPeripheral(&cadencePeripheralManager!)
	}

	// Optional methods
	// Adding Services - called after publishing services to the device's database.
	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
		if let error = error {
			print("Error publishing service: \(error.localizedDescription)")
			return
		}

		print("PUBLISH CALLED!!!\n")
		gattWrapper!.printGattAttributes()
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
			pairButton.setTitle("Unpair", for: .normal)
		}
	}

	// Monitoring Subscriptions to Characteristic Values

	// When a connected central subscribes to the value of one of your characteristics, the peripheral manager calls the peripheralManager:central:didSubscribeToCharacteristic: method of its delegate object:
	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
		print("Central subscribed to characteristic: \(characteristic)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {

	}

	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {

	}

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

			let bytes: [CChar] = isOpenCase ? [0x01] : [0x00]

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

	// When a connected central sends a request to write the value of one or more of your characteristics, the peripheral manager calls the peripheralManager:didReceiveWriteRequests: method of its delegate object.
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
		// This time, the delegate method delivers the requests to you in the form of an array containing one or more CBATTRequest objects, each representing a write request. After you have ensured that a write request can be fulfilled, you can write the characteristic’s value:

		// cadenceBlisterPackPlacedRemovedUUID is readable and writeable.
		let myCharacteristic = gattWrapper?.getCharacteristic(from: GattServiceId.cadenceBlisterPackUUID,
															  with: GattCharacteristicId.cadenceBlisterPackPlacedRemovedUUID)

		for request in requests {
			if request.characteristic.uuid.isEqual(GattCharacteristicId.cadenceBlisterPackPlacedRemovedUUID) {
				if let cadenceBlisterPackEventDataValue = gattWrapper?.getCharacteristic(from: GattServiceId.cadenceBlisterPackUUID,
																						 with: GattCharacteristicId.cadenceBlisterPackPlacedRemovedUUID) {
					myCharacteristic!.value = request.value

					let theStringFromCentral = String.init(data: myCharacteristic!.value!,
														   encoding: .utf16)
					print("This is what the central has wrote to me: \(theStringFromCentral)")
					stringFromCentral.append(theStringFromCentral!)
					dataFromCentralLabel.text = stringFromCentral.reversed().reduce("", { (res, leStr) in
						return leStr + res!
					})
					medicationEventLightView.isHidden = false
					medicationEventLightView.blink()
					cadencePeripheralManager!.respond(to: request, withResult: CBATTError.success)
				}
			}
			// Treat multiple requests as you would a single request—if any individual request cannot be fulfilled, you should not fulfill any of them. Instead, call the respondToRequest:withResult: method immediately and provide a result that indicates the cause of the failure.
			cadencePeripheralManager!.respond(to: request, withResult: CBATTError.invalidAttributeValueLength)
		}
	}
}

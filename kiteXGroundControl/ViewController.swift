//
//  ViewController.swift
//  kiteXGroundControl
//
//  Created by Andreas Okholm on 22/02/2017.
//  Copyright © 2017 Andreas Okholm. All rights reserved.
//

import Cocoa
import Mavlink
import ORSSerial

class ViewController: NSViewController {
    
    // MARK: Stored Properties
    
    let serialPortManager = ORSSerialPortManager.shared()
    
    var systemId: UInt8? = 1
    var compId: UInt8? = 1
    var timer: Timer?
    
    
    var serialPort: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort?.delegate = self
            serialPort?.baudRate = 57600
            serialPort?.numberOfStopBits = 1
            serialPort?.parity = .none
        }
    }
    
    var serialPort2: ORSSerialPort? {
        didSet {
            oldValue?.close()
            oldValue?.delegate = nil
            serialPort2?.delegate = self
            serialPort2?.baudRate = 57600
            serialPort2?.numberOfStopBits = 1
            serialPort2?.parity = .none
        }
    }
    
    
    @IBOutlet weak var thrustSlider: NSSlider!
    @IBOutlet weak var controlToggle: NSButton!
    
    
    
    // MARK: IBOutlets
    
    @IBOutlet weak var openCloseButton: NSButton!
    @IBOutlet weak var openCloseButton2: NSButton!
    @IBOutlet weak var usbRadioButton: NSButton!
    @IBOutlet weak var telemetryRadioButton: NSButton!
    @IBOutlet var receivedMessageTextView: NSTextView!
    @IBOutlet weak var clearTextViewButton: NSButton!
   
    
    // MARK: Initializers (View did load/disapear)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(ViewController.serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
        notificationCenter.addObserver(self, selector: #selector(ViewController.serialPortsWereDisconnected(_:)), name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)
        
        NSUserNotificationCenter.default.delegate = self

    }
    
    override func viewDidDisappear() {
        // FIXME perhaps now the right place
        NotificationCenter.default.removeObserver(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // MARK: - Notifications
    
    func serialPortsWereConnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were connected: \(connectedPorts)")
            postUserNotificationForConnectedPorts(connectedPorts)
        }
    }
    
    func serialPortsWereDisconnected(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
            print("Ports were disconnected: \(disconnectedPorts)")
            postUserNotificationForDisconnectedPorts(disconnectedPorts)
        }
    }
    
    func postUserNotificationForConnectedPorts(_ connectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.default
        for port in connectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
            userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
            userNote.soundName = nil;
            unc.deliver(userNote)
        }
    }
    
    func postUserNotificationForDisconnectedPorts(_ disconnectedPorts: [ORSSerialPort]) {
        let unc = NSUserNotificationCenter.default
        for port in disconnectedPorts {
            let userNote = NSUserNotification()
            userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
            userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
            userNote.soundName = nil;
            unc.deliver(userNote)
        }
    }

    
    
    
    fileprivate func startUsbMavlinkSession() {
        guard let port = self.serialPort, port.isOpen else {
            print("Serial port is not open")
            return
        }
        
        guard let data = "mavlink start -d /dev/ttyACM0\n".data(using: String.Encoding.utf32LittleEndian) else {
            print("Cannot create mavlink USB start command")
            return
        }
        
        port.send(data)
    }

    
    
    
    @IBAction func openOrClosePort(_ sender: AnyObject) {
        guard let port = serialPort else {
            return
        }
        
        if port.isOpen {
            port.close()
        }
        else {
            clearTextView(self)
            port.open()
            
            if usbRadioButton.state != 0 {
                startUsbMavlinkSession()
            }
        }
    }
    
    @IBAction func openOrClosePort2(_ sender: Any) {
        guard let port = serialPort2 else {
            return
        }
        
        if port.isOpen {
            port.close()
        }
        else {
            clearTextView(self)
            port.open()
            
            if usbRadioButton.state != 0 {
                startUsbMavlinkSession()
            }
        }

        
    }
    
    
    
    @IBAction func clearTextView(_ sender: AnyObject) {
        self.receivedMessageTextView.textStorage?.mutableString.setString("")
    }
    
    @IBAction func radioButtonSelected(_ sender: AnyObject) {
        // No-op - required to make radio buttons behave as a group
    }

    
    @IBAction func offboardToggle(_ sender: NSButton) {
        
        print(self.thrustSlider.doubleValue)
        
        print(sender.state)
        
        if (sender.state == NSOnState) {
            
            print("prepare offboard control ")
            
            sendOffboardEnable(on: true)
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {_ in
                
                if let serialPort = self.serialPort, let systemId = self.systemId, let compId = self.compId {
                    
                    var msg = MavlinkController.attitudeTarget(systemId: systemId, compId: compId, thrust: self.thrustSlider.floatValue/100)
                    serialPort.send(msg.data())
                    
                }
            }
            
        } else {
            timer?.invalidate()
            sendOffboardEnable(on: false)
        }
        
        
    }
    


}


extension ViewController: ORSSerialPortDelegate {
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        if (self.serialPort?.name == serialPort.name) {
            openCloseButton.title = "Close"
        } else {
            openCloseButton2.title = "Close"
        }
        
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        if (self.serialPort?.name == serialPort.name) {
            openCloseButton.title = "Open"
        } else {
            openCloseButton2.title = "Open"
        }
    }
    
    //    func serialPortWasRemoved(fromSystem serialPort: ORSSerialPort) {
    //
    //    }
    //
    
    /**
     *  Called when a serial port is removed from the system, e.g. the user unplugs
     *  the USB to serial adapter for the port.
     *
     *	In this method, you should discard any strong references you have maintained for the
     *  passed in `serialPort` object. The behavior of `ORSSerialPort` instances whose underlying
     *  serial port has been removed from the system is undefined.
     *
     *  @param serialPort The `ORSSerialPort` instance representing the port that was removed.
     */
    public func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        self.serialPort = nil
        self.openCloseButton.title = "Open"
        
        
    }
    
    
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        var bytes = [UInt8](repeating: 0, count: data.count)
        (data as NSData).getBytes(&bytes, length: data.count)
        
        for byte in bytes {
            var message = mavlink_message_t()
            var status = mavlink_status_t()
            let channel = UInt8(MAVLINK_COMM_1.rawValue)
            if mavlink_parse_char(channel, byte, &message, &status) != 0 {
                
                
                systemId = message.sysid // Only handles one drone
                compId = message.compid
                //                print("SystemId: \(message.sysid) componentId: \(message.compid)")

                if let posNED = message.isLocalPositionNED(), let nedObserver = EventManager.shared.NEDObserver {
                    
                    nedObserver.newPosition(event: posNED)
                }
                
                receivedMessageTextView.textStorage?.mutableString.append(message.description)
                receivedMessageTextView.needsDisplay = true
                
            }
        }
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        print("SerialPort \(serialPort.name) encountered an error: \(error)")
    }
    
    func sendOffboardEnable(on: Bool) {
        
        if let serialPort = self.serialPort, let systemId = self.systemId, let compId = self.compId {
            let flag = Float(on ? 1 : 0)
            
            var com = mavlink_command_long_t()
            com.target_system = systemId
            com.target_component = compId // Thiss seems right
            com.command = UInt16(MAV_CMD_NAV_GUIDED_ENABLE.rawValue)
            com.confirmation = UInt8(true)
            com.param1 = flag // // flag >0.5 => start, <0.5 => stop
            
            
            var message = mavlink_message_t()
            mavlink_msg_command_long_encode(systemId, compId, &message, &com);
            
            serialPort.send(message.data())
            
        }
    }
}

extension ViewController: NSUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        let popTime = DispatchTime.now() + Double(Int64(3.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            center.removeDeliveredNotification(notification)
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}


//
//  MavlinkController.swift
//  kiteXGroundControl
//
//  Created by Andreas Okholm on 22/02/2017.
//  Copyright © 2017 Andreas Okholm. All rights reserved.
//  Heavily! inspired by the demo by Michael Koukoullis

import Foundation
import Cocoa
import Mavlink


struct MavlinkController {
    
    static func attitudeTarget(systemId: UInt8, compId: UInt8, thrust: Float32) -> mavlink_message_t {
        
        var attitudeTarget = mavlink_attitude_target_t()
        
        //        time_boot_ms          uint32_t	Timestamp in milliseconds since system boot
        //        target_system         uint8_t     System ID
        //        target_component      uint8_t     Component ID
        //        type_mask             uint8_t     Mappings: If any of these bits are set, the corresponding input should be ignored: bit 1: body roll rate, bit 2: body pitch rate, bit 3: body yaw rate. bit 4-bit 6: reserved, bit 7: throttle, bit 8: attitude
        //        q	float[4]	Attitude quaternion (w, x, y, z order, zero-rotation is 1, 0, 0, 0)
        //        body_roll_rate        float       Body roll rate in radians per second
        //        body_pitch_rate       float       Body roll rate in radians per second
        //        body_yaw_rate         float       Body roll rate in radians per second
        //        thrust                float       Collective thrust, normalized to 0 .. 1 (-1 .. 1 for vehicles capable of reverse trust)
        
        
        attitudeTarget.time_boot_ms = UInt32(ProcessInfo.processInfo.systemUptime * 1000)
        attitudeTarget.type_mask = UInt8(0) // Bitmask should work for now.

        attitudeTarget.q = (1,0,0,0)

        attitudeTarget.body_roll_rate = 0
        attitudeTarget.body_pitch_rate = 0
        attitudeTarget.body_yaw_rate = 0
        
        attitudeTarget.thrust = thrust
        
        var msg = mavlink_message_t()
        
        mavlink_msg_attitude_target_encode(systemId, compId, &msg, &attitudeTarget)
        
        return msg
    }
}


extension mavlink_message_t: CustomStringConvertible {
    public var description: String {
        var message = self
        switch msgid {
        case 0:
            var heartbeat = mavlink_heartbeat_t()
            mavlink_msg_heartbeat_decode(&message, &heartbeat);
            return "HEARTBEAT mavlink_version: \(heartbeat.mavlink_version)\n"
        case 1:
            var sys_status = mavlink_sys_status_t()
            mavlink_msg_sys_status_decode(&message, &sys_status)
            return "SYS_STATUS comms drop rate: \(sys_status.drop_rate_comm)%\n"
        case 30:
            var attitude = mavlink_attitude_t()
            mavlink_msg_attitude_decode(&message, &attitude)
            return "ATTITUDE roll: \(attitude.roll) pitch: \(attitude.pitch) yaw: \(attitude.yaw)\n"
        case 32:
            var local_position_ned = mavlink_local_position_ned_t()
            mavlink_msg_local_position_ned_decode(&message, &local_position_ned)
            return "LOCAL POSITION NED x: \(local_position_ned.x) y: \(local_position_ned.y) z: \(local_position_ned.z)\n"
        case 33:
            return "GLOBAL_POSITION_INT\n"
        case 74:
            var vfr_hud = mavlink_vfr_hud_t()
            mavlink_msg_vfr_hud_decode(&message, &vfr_hud)
            return "VFR_HUD heading: \(vfr_hud.heading) degrees\n"
        case 76:
            var command_long = mavlink_command_long_t()
            mavlink_msg_command_long_decode(&message, &command_long)
            return "COMMAND_LONG command:\(command_long.command), param1 \(command_long.param1)\n"
        case 83:
            var attitude_target = mavlink_attitude_target_t()
            mavlink_msg_attitude_target_decode(&message, &attitude_target)
            return "ATTITUDE_TARGET \(attitude_target.thrust)\n"
        case 87:
            return "POSITION_TARGET_GLOBAL_INT\n"
        case 105:
            var highres_imu = mavlink_highres_imu_t()
            mavlink_msg_highres_imu_decode(&message, &highres_imu)
            return "HIGHRES_IMU Pressure: \(highres_imu.abs_pressure) millibar\n"
        case 147:
            var battery_status = mavlink_battery_status_t()
            mavlink_msg_battery_status_decode(&message, &battery_status)
            return "BATTERY_STATUS current consumed: \(battery_status.current_consumed) mAh\n"
        default:
            return "OTHER Message id \(message.msgid) received\n"
        }
    }
}

extension mavlink_message_t {
    
    func isLocalPositionNED() -> mavlink_local_position_ned_t? {
        
        guard msgid == 32 else {
            return nil
        }
        
        var message = self
        
        var local_position_ned = mavlink_local_position_ned_t()
        mavlink_msg_local_position_ned_decode(&message, &local_position_ned)
        return local_position_ned
    }
    
}

extension mavlink_message_t {
    
    mutating func data() -> Data {
        
        let buffer = Data.init(count: 300) // 300 from mavlink example c_uart_interface_example
        
        return buffer.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) -> Data in
            let mutablePointer  = UnsafeMutablePointer(mutating: u8Ptr)
            
            let length = mavlink_msg_to_send_buffer(mutablePointer, &self)
            
            return buffer.subdata(in: 0..<Int(length) )
        }

    }
    
}


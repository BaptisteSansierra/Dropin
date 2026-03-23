//
//  CLLocationCoordinate2D+Format.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/3/26.
//

import CoreLocation

extension CLLocationCoordinate2D {
    
    init?(string: String) {
        guard !string.isEmpty else { return nil }
        let cleanString = string.trimmingCharacters(in: [" "])
        // Look for separator
        var parts: [String] = []
        parts = cleanString
            .split(separator: ",")
            .map({ $0.trimmingCharacters(in: [" "]) })
        if parts.count != 2 {
            parts = cleanString
                .split(separator: " ")
                .map({ $0.trimmingCharacters(in: [" "]) })
        }
        guard parts.count == 2 else { return nil }
        // Convert to doubles
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.decimalSeparator = "."
        guard let lat = formatter.number(from: parts[0])?.doubleValue,
              let lon = formatter.number(from: parts[1])?.doubleValue else {
            return nil
        }
        self.init(latitude: lat, longitude: lon)
    }
    
    /*  TODO: implement both sides conversions
    enum Format {
        case dd
        case dms
        case dm
    }

    enum StringValue {
        case dd(String, String)
        case dms(String, String, String, String, String, String)
        case dm(String, String, String, String, String, String)
    }
     */

    func formatted() -> String {
        let latStr = latitude.formatted(.number
                                            .precision(.fractionLength(0...6))
                                            .locale(Locale(identifier: "en_US_POSIX")))
        let lonStr = longitude.formatted(.number
                                             .precision(.fractionLength(0...6))
                                             .locale(Locale(identifier: "en_US_POSIX")))
        return "\(latStr),\(lonStr)"
    }

    
    private func toDMS(_ coordinate: CLLocationCoordinate2D) -> (String, String) {
        func convert(_ value: Double, positive: String, negative: String) -> String {
            let direction = value >= 0 ? positive : negative
            let absValue = abs(value)
            
            let degrees = Int(absValue)
            let minutesFull = (absValue - Double(degrees)) * 60
            let minutes = Int(minutesFull)
            let seconds = (minutesFull - Double(minutes)) * 60
            
            return "\(degrees)°\(minutes)'\(String(format: "%.2f", seconds))\"\(direction)"
        }
        
        let lat = convert(coordinate.latitude, positive: "N", negative: "S")
        let lon = convert(coordinate.longitude, positive: "E", negative: "W")
        
        return ("\(lat)", "\(lon)")
    }
    
    func toDM(_ coordinate: CLLocationCoordinate2D) -> (String, String) {
        func convert(_ value: Double, positive: String, negative: String) -> String {
            let direction = value >= 0 ? positive : negative
            let absValue = abs(value)
            
            let degrees = Int(absValue)
            let minutes = (absValue - Double(degrees)) * 60
            
            return "\(degrees)°\(String(format: "%.3f", minutes))'\(direction)"
        }
        
        let lat = convert(coordinate.latitude, positive: "N", negative: "S")
        let lon = convert(coordinate.longitude, positive: "E", negative: "W")
        
        return ("\(lat)", "\(lon)")
    }
    
}

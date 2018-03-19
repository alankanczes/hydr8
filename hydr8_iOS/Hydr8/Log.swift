//
//  Log.swift
//  Hydr8
//
//  Created by Alan Kanczes on 2/3/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//


import Foundation
import UIKit


enum LogLevel {
    case DETAIL
    case DEBUG
    case INFO
    case WARN
    case ERROR
}

class Log {
    
    private static var log: UITextView?
    private static var visibleLogLevels = Set<LogLevel>()
    
    // Set new static log to be accessed by all -- bad pattern -- can only have one log -- is this rigt?  Check out swift logging
    static func setLog (statusLog: UITextView, showLogLevels: [LogLevel])
    {
        Log.log = statusLog
        
        // Add visible log levels
        for logLevel in showLogLevels {
            Log.visibleLogLevels.insert(logLevel)
        }
    }
    
    static func logIt(_ message: String, _ logLevel: LogLevel = LogLevel.INFO) {
        
        if Log.visibleLogLevels.contains(logLevel) {
            print(message)
        }
        
        // App visible log
        if Log.log != nil {
            if (Log.visibleLogLevels.isEmpty || Log.visibleLogLevels.contains(logLevel)) {
                Log.log!.text = Log.log!.text + "\r\(logLevel): \(message)"
            }
        } else {
            print ("LOG IS NOT INITIALIZED!")
        }
    }
}

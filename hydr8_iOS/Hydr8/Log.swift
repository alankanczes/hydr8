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
    case detail
    case debug
    case info
    case warn
    case error
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
    
    // Clear UI log textview, if it is available.
    static func clear ()
    {
        log?.text = ""
    }
    
    
    static func write(_ message: String, _ logLevel: LogLevel = LogLevel.info) {
        
        if Log.visibleLogLevels.contains(logLevel) {
            print("[\(logLevel)] \(message)")
        }
        
        // App visible log exists, yay!
        if Log.log != nil {
            // Log levels are not set (log everything) or level is in set of requested visibility
            if (Log.visibleLogLevels.isEmpty || Log.visibleLogLevels.contains(logLevel)) {
                DispatchQueue.main.async(execute: {
                    /* Do UI work here */
                    Log.log!.text = Log.log!.text + "\r\(logLevel): \(message)"
                    });
            }
        } else {
            print ("LOG IS NOT INITIALIZED!")
        }
    }
}

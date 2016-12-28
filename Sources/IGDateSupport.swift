///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


//  Moved to Kitura on 5/4/16
//  IGDateSupport.swift
//  SocialMaxx
//
//  Created by bill donner on 1/17/16.
//

import Foundation
struct MI {
    var m:Matrix
    var i:Int
}
struct  IGDateSupport {
    
    
    static func hourBucket(_ unixTime: Double,dateFormatter:DateFormatter)->Int {
        let date = Date(timeIntervalSince1970: unixTime)
        
        // Returns date formatted as 24 hour time.
        dateFormatter.dateFormat = "HH"
        return Int( dateFormatter.string(from:date))!
        
    }
    static func dayOfWeekBucket(_ unixTime: Double,dateFormatter:DateFormatter)->Int {
        let date = Date(timeIntervalSince1970: unixTime)
        
        // Returns date formatted as 24 hour time.
        dateFormatter.locale = Locale(identifier: Locale.current.identifier)
        dateFormatter.dateFormat = "EEEE"
        let s =  dateFormatter.string(from:date)
        switch s  {
        case "Sunday": return 0
        case "Monday": return 1
        case "Tuesday": return 2
        case "Wednesday": return 3
        case "Thursday": return 4
        case "Friday": return 5
        case "Saturday": return 6
            
        default: fatalError("bad day of week bucket " + s)
            break
        }
        
        
    }
    static func dateStringFromUnixTime(_ unixTime: Double,dateFormatter:DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: unixTime)
        
        // Returns date formatted as 12 hour time.
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from:date)
    }
    static func timeStringFromUnixTime(_ unixTime: Double,dateFormatter:DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: unixTime)
        
        // Returns date formatted as yearm mon day
        dateFormatter.dateFormat = "MM/dd/yy"
        return dateFormatter.string(from:date)
    }
    
    static func dayStringFromTime(_ unixTime: Double,dateFormatter:DateFormatter) -> String {
        let date = Date(timeIntervalSince1970: unixTime)
        dateFormatter.locale = Locale(identifier: Locale.current.identifier)
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from:date)
    }
    //2nd arg not present on ios
    static func computeTimeBucketFromIGTimeStamp(_ ts:String,dateFormatter:DateFormatter) -> (hourOfDay:Int,dayOfWeek:Int) {
        if let dd = Double(ts) {
            let hourOfDay = hourBucket(dd,dateFormatter: dateFormatter)
            let dayOfWeek = dayOfWeekBucket(dd,dateFormatter: dateFormatter)
            return (hourOfDay,dayOfWeek)
        }
        return (hourOfDay:0,dayOfWeek:0)
    }
    
    
    
    static func dateOfFirstLike(_ igp:SocialDataProcessor,likerID:String) throws -> String {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeFirst,
            onepost = igp.pd.ouMediaPosts[idx] as  MediaData,
            created = onepost.createdTime // as per IG spec
            return created
        }
        throw SMaxxError.bad(arg:917)
    }
    static func dateOfLastLike(_ igp:SocialDataProcessor,likerID:String) throws -> String {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeLast,
            onepost = igp.pd.ouMediaPosts[idx] as  MediaData,
            created = onepost.createdTime // as per IG spec
            return created
        }
        throw SMaxxError.bad(arg:918)
    }
    
    static  func postOfLastLike(_ igp:SocialDataProcessor,likerID:String) throws ->  MediaData {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeLast,
            onepost = igp.pd.ouMediaPosts[idx] as MediaData
            return onepost
        }
        throw SMaxxError.bad(arg:918)
    }
    
    static  func postOfFirstLike(_ igp:SocialDataProcessor,likerID:String) throws -> MediaData {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeFirst,
            onepost = igp.pd.ouMediaPosts[idx] as  MediaData
            return onepost
        }
        throw SMaxxError.bad(arg:919)
    }
    
    
}

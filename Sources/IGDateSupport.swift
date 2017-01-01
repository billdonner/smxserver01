///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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
        throw SMaxxError.noLikersWithID
    }
    static func dateOfLastLike(_ igp:SocialDataProcessor,likerID:String) throws -> String {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeLast,
            onepost = igp.pd.ouMediaPosts[idx] as  MediaData,
            created = onepost.createdTime // as per IG spec
            return created
        }
        throw SMaxxError.noLikersWithID
    }
    
    static  func postOfLastLike(_ igp:SocialDataProcessor,likerID:String) throws ->  MediaData {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeLast,
            onepost = igp.pd.ouMediaPosts[idx] as MediaData
            return onepost
        }
        throw SMaxxError.noLikersWithID
    }
    
    static  func postOfFirstLike(_ igp:SocialDataProcessor,likerID:String) throws -> MediaData {
        
        if let t = igp.likersDict [likerID] {
            let idx  = t.postsBeforeFirst,
            onepost = igp.pd.ouMediaPosts[idx] as  MediaData
            return onepost
        }
        throw SMaxxError.noLikersWithID
    }
    
    
}

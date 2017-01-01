///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  PersonDataModel.swift
//  t3
//
//  Created by william donner on 5/25/16.
//
//

import Foundation

///
//MARK:- Persistent Model Classes - use NSCoding to read/write plists
///

// all writing saves the entire root context


///
//MARK:- SocialPersonData - is Persistent User Profile
///

@objc(Pd)
class PersonData:NSObject,NSCoding  //TODO: rename to SocialPersonData
{
    // bookkeeping
    var plistVersion : String  { // pull from info.plist
//        if let iDict = NSBundle.mainBundle().infoDictionary {
//            if let y = iDict["CFBundleShortVersionString"] as? String { return y }
//        }
        return "0.42"
    }
    var ouVersion: String?
    // first time we created this user record / plist / model
    var ouStartTime : Date?  //
    // last time we wrote ourselves to disk
    var ouUpdateTime : Date! //
    
    var ouTotalApiCount: Int = 0
    
    //this comes in thru the instagram api
    var ouUserInfo : UserData!
    var ouRelationshipToEndUser:RelationshipData!
    var ouMediaPosts:BunchOfMedia = [] // timesorted by orignal post time
    var ouAllFollowers:BunchOfPeople = []
    var ouAllFollowing:BunchOfPeople = []
    
    var ouMinMediaPostID: String = "999999999999999999999999999999999999999999999999"
    var ouMaxMediaPostID: String = "0"
    
    //1000083294764874892_275404302
    //995772699961933304_275404302
    //computed but not saved to disk
    
    func summarize () -> String {
        let uc =   ouUserInfo.igCounts
        
        return "* u:" + ouUserInfo.id + ":" + ouUserInfo.fullname  + "(" + ouUserInfo.username + ")" +
            " c:\(uc[0]),\(uc[1]),\(uc[2]) " +
            " r:" +  ouRelationshipToEndUser.incoming + "." +  ouRelationshipToEndUser.outgoing + " " +  currently()
    }
    
    
    func postsStatus()->String {
        
        return "\n*  p:\(ouMediaPosts.count) minid: \(ouMinMediaPostID) maxid: \(ouMaxMediaPostID)"
    }
    
    func currently()->String {
        
        let st = ouStartTime ?? Date(timeIntervalSince1970: 0.0)
        let ut = ouUpdateTime ?? Date(timeIntervalSince1970: 0.0)
        
        return "\n* v:\(ouVersion ?? "??") cr: \(st) lu:\(ut) \n* p:\(ouMediaPosts.count) f:\(ouAllFollowers.count) "
        //t:\(tagsFreqDict.count) tu:\(taggedUsersFreqDict.count) fil:\(filtersFreqDict.count)"
    }
    
    
    override init() {}


    required init?(coder aDecoder:NSCoder) {
        super.init()
        
        ouVersion = aDecoder.decodeObject(forKey: "version") as?  String
        if ouVersion == nil {
            print(">>>> no Version on disk -- setting to \(plistVersion)")
            ouVersion = plistVersion
        }
//        else {
//            guard ouVersion! == (plistVersion) else {
//                print(">>>> did change database -- will now reset")
//                return
//            }
//        }
        
        // if still here, the version number on Disk matches what we expect from Info.plist
        
        ouTotalApiCount = aDecoder.decodeObject(forKey: "totalapicount") as? Int ?? 0
        ouStartTime = aDecoder.decodeObject(forKey: "starttime") as?  Date
        ouUpdateTime = aDecoder.decodeObject(forKey: "updatetime") as?  Date
        ouUserInfo = aDecoder.decodeObject(forKey: "user") as? UserData
        ouRelationshipToEndUser = aDecoder.decodeObject(forKey: "status") as? RelationshipData
        ouMediaPosts = aDecoder.decodeObject(forKey: "posts") as? BunchOfMedia ?? []
        ouAllFollowers = aDecoder.decodeObject(forKey: "followers") as? BunchOfPeople   ?? []
        ouAllFollowing = aDecoder.decodeObject(forKey: "following") as? BunchOfPeople   ?? []
        ouMinMediaPostID = aDecoder.decodeObject(forKey: "ouMinMediaPostID") as? String ?? ""
        ouMaxMediaPostID = aDecoder.decodeObject(forKey: "ouMaxMediaPostID") as? String ?? ""

        
    }
    
    func encode (with aCoder: NSCoder) {
        aCoder.encode(plistVersion, forKey: "version")
        aCoder.encode(ouStartTime, forKey: "starttime")
        aCoder.encode(ouUpdateTime, forKey: "updatetime")
        aCoder.encode(ouTotalApiCount, forKey: "totalapicount")
        aCoder.encode(ouUserInfo, forKey: "user")
        aCoder.encode(ouRelationshipToEndUser, forKey: "status")
        aCoder.encode(ouAllFollowers, forKey: "followers")
        aCoder.encode(ouAllFollowing, forKey: "following")
        aCoder.encode(ouMediaPosts, forKey: "posts")
        aCoder.encode(ouMinMediaPostID, forKey: "ouMinMediaPostID")
        aCoder.encode(ouMaxMediaPostID, forKey: "ouMaxMediaPostID")
    }
    func savePd(_ userID:String) throws {
        
        let start = Date()
        ouUpdateTime = start
        if ouStartTime == nil {
            ouStartTime = ouUpdateTime
        }
        if ouVersion == nil {
            ouVersion = plistVersion
        }
        let tail = "/\(userID).smaxx"
        if  !NSKeyedArchiver.archiveRootObject(self, toFile:HomePageMainServer.membershipPath() + tail){
            throw SMaxxError.cantWriteIGPersonDataFile(message: tail)
        } else {
            let elapsed  =   "\(Int(Date().timeIntervalSince(start)*1000.0))ms"
            print("  **************** Saved Person Data to ", tail, " in ",elapsed,
                  " ****************")
        }
    }
    
    static func restore(_ userID:String) throws -> PersonData {
        let tail = "/\(userID).smaxx"
        do {
            if let pdx = NSKeyedUnarchiver.unarchiveObject(withFile:HomePageMainServer.membershipPath() + tail)  as? PersonData {
                return pdx
            }
            throw SMaxxError.cantDecodeIGPersonDataFile(message : tail)
        }
        catch  {
            throw  SMaxxError.cantRestoreIGPersonDataFile (message: tail)
        }
    }
}


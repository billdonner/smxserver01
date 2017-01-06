/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  ReportMakerFollowerReports.swift
//  SMaxxServer
//
//  Created by william donner on 5/8/16.
//
//

import Foundation
// MARK:- Follower Reports
extension ReportMakerMainServer {
    ///
    // MARK:-  follower reports all build similar JSON payloads for delivery back thru API
    ///
    class  func report_from_bunchoffollowers(_ igp:SocialDataProcessor, bop:BunchOfPeople,skip:Int = 0,limit:Int = 1000)-> ReportResult {
        var therows :[JSONDictionary] = []
        
        func emitpeoplerow(_ rowNum:Int, igperson:UserData) {
            let (c1,av1,c2,av2) = Instagram.countsAndAveragesFromPosts(igp,igPerson:igperson)
            // for each row indicate if this user is a member thru the smaxx-id field
            let smxid =  MembersCache.isMemberFromCache(igperson.id) ? igperson.id : ""
            
            therows.append( ["row":rowNum  ,"userid":igperson.username  ,"smaxx-id":smxid  , "pic":igperson.pic  ,"c1":c1  ,"av1":av1  ,"c2":c2  ,"av2":av2   ] )
            //Log.error("emitting igperson:\(igperson)")
        }
        var lim = 0
        for aperson in bop {
            if lim >= skip {
                emitpeoplerow (lim, igperson:aperson)
            }
            
            lim += 1
            if lim >= limit { break }
        }
        
        //Log.error("report from people= \(bop.count) rows= \(therows.count) skip \(skip) limit \(limit)")
        let body:JSONDictionary = [  "rows":therows as AnyObject]
        return (bop.count,body,.aboutPeople)
    }
    
    class func freqSort(_ slikers:[Instagram.Frqi],bop:BunchOfPeople)->BunchOfPeople {
        var nslikers = slikers
        nslikers.sort { $0.counter > $1.counter }
        var newpeople:BunchOfPeople = []
        for sliker in nslikers {
            let m = bop[sliker.key]
            newpeople.append(m)
        }
        return newpeople
    }
    
    ///
    // MARK:- All Followers with Highest Avg Like Rate
    ///
    class  func all_followers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  { //TODO
        let newfollowers = igp.pd.ouAllFollowers
        //        newfollowers.sort {
        //            $0.
        //        }
        // TODO: sort as in ios app
        return ReportMakerMainServer.report_from_bunchoffollowers(igp, bop:newfollowers,skip:skip,limit:limit)
    }
    ///
    // MARK:- Booster Followers with Highest Avg Like Rate
    ///
    class  func booster_followers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  { //TODO
        var newfollowers:BunchOfPeople = []
        for follower in igp.pd.ouAllFollowers {
            if igp.likersDict [follower.id] == nil {
                newfollowers.append(follower)
            } else {
                // Log.error("follower \(follower.id) is IN likers dict")}
            }
        }
        return ReportMakerMainServer.report_from_bunchoffollowers(igp, bop:newfollowers,skip:skip,limit:limit)
    }
    
    ///
    // MARK:- Ghost Followers follow us but dont like anything we've posted
    ///
    class  func ghost_followers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        var newfollowers:BunchOfPeople = []
        for follower in igp.pd.ouAllFollowers {
            if igp.likersDict [follower.id] == nil {
                newfollowers.append(follower)
            } else {
                // Log.error("follower \(follower.id) is IN likers dict")}
            }
        }
        return ReportMakerMainServer.report_from_bunchoffollowers(igp, bop:newfollowers,skip:skip,limit:limit)
    }
    
    ///
    // MARK:- Unrequited Followers follow us but we dont follow them
    ///
    class func makefollowingdict(_ people:BunchOfPeople)->PeopleDict {
        var d: PeopleDict = PeopleDict()
        for person in people { d[person.id] = person }
        return d
    }
    class func unrequited_followers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        
        let fd = makefollowingdict(igp.pd.ouAllFollowing)
        var newfollowers:BunchOfPeople = []
        for follower in igp.pd.ouAllFollowers {
            if fd [follower.id] == nil {
                newfollowers.append(follower)
            }
        }
        return ReportMakerMainServer.report_from_bunchoffollowers(igp, bop:newfollowers,skip:skip,limit:limit)
    }
    
    ///
    // MARK:- Secret Admirer Followers with Most Likes
    ///
    class  func secret_admirer_followers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  { //TODO
        var newfollowers:BunchOfPeople = []
        for follower in igp.pd.ouAllFollowers {
            if igp.likersDict [follower.id] == nil {
                newfollowers.append(follower)
            } else {
                // Log.error("follower \(follower.id) is IN likers dict")}
            }
        }
        return ReportMakerMainServer.report_from_bunchoffollowers(igp, bop:newfollowers,skip:skip,limit:limit)
    }
    
}

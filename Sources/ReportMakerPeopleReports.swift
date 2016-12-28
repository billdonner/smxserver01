///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  ReportMakerPeopleReports.swift
//  SMaxxServer
//
//  Created by william donner on 5/8/16.
//
//

import Foundation
// MARK:- People Reports
extension ReportMaker {
    ///
    // MARK:-  people reports all build similar JSON payloads for delivery back thru API
    ///
    class  func report_from_bunchofpeople(_ igp:SocialDataProcessor, bop:BunchOfPeople,skip:Int = 0,limit:Int = 1000)-> ReportResult {
        var therows :[JSONDictionary] = []
        
        func emitpeoplerow(_ rowNum:Int, igperson:UserData) {
            let (c1,av1,c2,av2) = Instagram.countsAndAveragesFromPosts(igp,igPerson:igperson)
//            therows.append( ["row":rowNum,"userid":igperson.username,"pic":igperson.pic,"c1":c1,"av1":av1,"c2":c2,"av2":av2 ] )
//            //Log.error("emitting igperson:\(igperson)")
            
            // for each row indicate if this user is a member thru the smaxx-id field
            let smxid =  Membership.isMember(igperson.id) ? igperson.id : ""
            therows.append( ["row":rowNum as AnyObject,"userid":igperson.username as AnyObject,"smaxx-id":smxid as AnyObject, "pic":igperson.pic as AnyObject,"c1":c1 as AnyObject,"av1":av1 as AnyObject,"c2":c2 as AnyObject,"av2":av2 as AnyObject ] )
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
        let body:JSONDictionary = [   "rows":therows as AnyObject]
        return (bop.count,body,.aboutPeople)
    }
    class func freqSortPeople(_ slikers:[Instagram.Frqc] )->BunchOfPeople {

        var newpeople:BunchOfPeople = []

        for sliker in slikers {
            if let m = sliker.user {
            newpeople.append(m)
            }
        }
        return newpeople
    }
    ///
    
    // MARK:- All Users Following Us
    ///
    class func all_followings_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
    
        let bop = igp.pd.ouAllFollowing
        return ReportMaker.report_from_bunchofpeople(igp ,bop:bop,skip:skip,limit:limit)
    }
    // MARK:- Users With Highest Total Likes
    ///
    class func top_likers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_,_) = Instagram.computeFreqCountForLikers(igp,filter:nil) //->([Frqc],Int)
        let bop = freqSortPeople(slikers )//->BunchOfMedia
        return ReportMaker.report_from_bunchofpeople(igp ,bop:bop,skip:skip,limit:limit)
    }
    ///
    // MARK:- Users With Highest Total Comments
    ///
    class func top_commenters_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_,_) = Instagram.computeFreqCountForCommenters(igp,filter:nil) //->([Frqc],Int)
        let bop = freqSortPeople(slikers )//->BunchOfMedia
        return ReportMaker.report_from_bunchofpeople(igp ,bop:bop,skip:skip,limit:limit)
    }
    ///
    // MARK:- Speechless Likers Who Have Never Commented
    ///
    class func speechless_likers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_,_) = Instagram.computeFreqCountForSpeechlessLikers(igp) //->([Frqc],Int)
        let bop = freqSortPeople(slikers )//->BunchOfMedia
        return ReportMaker.report_from_bunchofpeople(igp ,bop:bop,skip:skip,limit:limit)
    }
    ///
    // MARK:- Heartless Commenters Who Have Never Liked
    ///
    class func  heartless_commenters_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_,_) = Instagram.computeFreqCountForHeartlessCommenters(igp) //->([Frqc],Int)
        let bop = freqSortPeople(slikers )//->BunchOfMedia
        return ReportMaker.report_from_bunchofpeople(igp ,bop:bop,skip:skip,limit:limit)
    }
}


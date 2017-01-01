///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  ReportMakerPostsReports.swift
//  SMaxxServer
//
//  Created by william donner on 5/8/16.
//
//
import LoggerAPI
import Foundation

// MARK:- Posts Reports
extension ReportMakerMainServer {
    ///
    // MARK:-  post reports all build similar JSON payloads for delivery back thru API
    ///p7x24_report_from_bunchofposts
    class func p7x24_report_from_stringmatrix(_ strings:[[String]])-> ReportResult {
        let body:JSONDictionary = ["matrix":strings as AnyObject]
        return (1,body,.adHoc)
    }
    
    class func report_from_bunchofposts(_ igp:SocialDataProcessor, bop:BunchOfMedia
        ,skip:Int = 0,limit:Int = 1000)-> ReportResult {
        var therows :[JSONDictionary] = []
        
        func emitpostrow(_ rowNum:Int, ff:MediaData ) {
            let thelabel = ff.tags.reduce(" ") {$0.0 + " "} + ff.caption
            therows.append( ["row":rowNum as AnyObject,"created":Double(ff.createdTime)! as AnyObject, "pic":ff.standardPic as AnyObject,"likerscount":ff.likers.count as AnyObject, "commentscount":ff.comments.count as AnyObject,"title":thelabel as AnyObject ] )
        }
        
        var rownum = 0
        for bopo in bop {
            if rownum >= skip {
                emitpostrow(rownum,ff:bopo)
            }
            rownum += 1
            if rownum >= limit { break }
        }
        
        let body:JSONDictionary = ["rows":therows as AnyObject]
        return (bop.count,body,.aboutPosts)
    }
    
    class func freqSortPosts(_ slikers:[Instagram.Frqi],bop:BunchOfMedia)->BunchOfMedia {
        var nslikers = slikers
        nslikers.sort{ $0.counter > $1.counter }
        var newmedia:BunchOfMedia = []
        for sliker in nslikers {
            let m = bop[sliker.key]
            newmedia.append(m)
        }
        return newmedia
    }
    
    ///
    // MARK:- Top Posts sorted by count of likes
    ///
    class func top_posts_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_) = Instagram.computeFreqCountOfLikesForPosts(igp.pd.ouMediaPosts) //->([Frqi],Int)
        let bop = freqSortPosts(slikers,bop:igp.pd.ouMediaPosts)//->BunchOfMedia
        return ReportMakerMainServer.report_from_bunchofposts(igp,bop:bop, skip:skip,limit:limit)
    }
    ///
    // MARK:- Top Posts sorted by count of comments
    ///
    class func top_comments_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let (slikers,_) = Instagram.computeFreqCountOfCommentersForPosts(igp.pd.ouMediaPosts) //->([Frqi],Int)
        let bop = freqSortPosts(slikers,bop:igp.pd.ouMediaPosts)//->BunchOfMedia
        return ReportMakerMainServer.report_from_bunchofposts(igp,bop:bop, skip:skip,limit:limit)
    }
    ///
    // MARK:- When I Tend To Post in 15min weekly buckets
    ///
    class func when_posting_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let mi = Instagram.calculateMediaPostHisto24x7(igp.pd.ouMediaPosts)
        let alphas = AlphaMatrix(m:mi.m)
        let alphastrings = alphas.forRGB()
        return ReportMakerMainServer.p7x24_report_from_stringmatrix(alphastrings)
    }
    ///
    // MARK:- When Should I Post in 15min weekly buckets
    ///
    class func when_topost_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        let mi = Instagram.calculateMediaLikesHisto24x7(igp.pd.ouMediaPosts)
        let alphas = AlphaMatrix(m:mi.m)
        let alphastrings = alphas.forRGB()
        return ReportMakerMainServer.p7x24_report_from_stringmatrix(alphastrings)
    }
}

///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  ReportMakerTagReports.swift
//  SMaxxServer
//
//  Created by william donner on 5/8/16.
//
//
import LoggerAPI
import SwiftyJSON
import Foundation

// MARK:- Tag Reports
extension ReportMaker {
    fileprivate class func freqSortTags(_ freqs:StringAnalysisBlock)-> [Instagram.Frqtd] {
        var tagCounts:[Instagram.Frqtd] = []
        
        // linearilize
        for (_,vx) in freqs {
            if vx.count > 1 {
                tagCounts.append(Instagram.Frqtd(key: vx.val,ratio: Double(vx.likerTotal)/Double(vx.count) ))
            }
        }
        tagCounts.sort  {
            $0.ratio > $1.ratio
            
        }
        return tagCounts
    }
    
    ///
    // MARK:-  tag reports all build similar JSON payloads for delivery back thru API
    ///
    
    fileprivate class  func report_from_bunchoftagsD(_ igp:SocialDataProcessor, sab:StringAnalysisBlock,keys:[Instagram.Frqtd], skip:Int = 0,limit:Int = 1000) -> ReportResult {
        var therows :[JSONDictionary] = []
        
        func emittagrowd(_ rowNum:Int, key:String, stuff:StringLikerContext) {
            if let  tagBlock = sab[key]{
                //choose a picture
               // let beforefirst = tagBlock.postsBeforeFirst
                let beforelast = tagBlock.postsBeforeLast
                // let delta:Int   = (beforelast - beforefirst) + 1
                // pick anyone in between
                // let ran = beforefirst + Int(arc4random()) % delta
                
                let bf = igp.pd.ouMediaPosts [beforelast] // pick it out
                let thepic = bf.standardPic
                therows.append( ["row":rowNum as AnyObject,"pic":thepic as AnyObject,"val":stuff.val as AnyObject,"count":stuff.count as AnyObject,"before-first":stuff.postsBeforeFirst as AnyObject,"before-last":stuff.postsBeforeLast as AnyObject ] )
                //Log.error("emitting igperson:\(igperson)")
            }
        }
        
        var lim = 0
        for frqtd in keys {
            if lim >= skip {
                if let f = sab[frqtd.key] {
                    emittagrowd (lim, key:frqtd.key, stuff:f)
                }
                else { fatalError("did not find \(frqtd) in tags reports") }
            }
            
            lim += 1
            if lim >= limit { break }
        }
        
        //Log.error("report from people= \(bop.count) rows= \(therows.count) skip \(skip) limit \(limit)")
        let body:JSONDictionary = [   "rows":therows as AnyObject]
        return (therows.count,body,.aboutPeople)
    }
    
    
    
    ///
    // MARK:-  Most Popular Tags Occuring in Users Photos
    ///
    class func most_popular_tags_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        igp.figureTags()
        
        let tags = freqSortTags(igp.tagsFreqDict)
        return ReportMaker.report_from_bunchoftagsD(igp,sab:igp.tagsFreqDict ,keys:tags,skip:skip,limit:limit)
    }
    ///
    // MARK:-  Most Popular Tagged Users/Friends Occuring in Users Photos
    ///
    class func most_popular_taggedusers_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        
        igp.figureTags()
        
        let taggedUsers = freqSortTags(igp.taggedUsersFreqDict)
        return ReportMaker.report_from_bunchoftagsD(igp,sab:igp.taggedUsersFreqDict,keys:taggedUsers ,skip:skip,limit:limit)
    }
    ///
    // MARK:- Most Popular Filters Occuring in Users Photos
    ///
    class func most_popular_filters_report(_ igp:SocialDataProcessor,skip:Int=0,limit:Int=1000) -> ReportResult  {
        
        igp.figureTags()
        
        let taggedFilters = freqSortTags(igp.filtersFreqDict)
        
        return ReportMaker.report_from_bunchoftagsD(igp,sab:igp.filtersFreqDict,keys:taggedFilters ,skip:skip,limit:limit)
    }
    
}

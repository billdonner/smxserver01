///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  ReportMaker.swift
//  SMaxxServer
//
//  Created by william donner on 5/3/16.
//
//

import Kitura
import KituraNet
//import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation


///
// MARK:-  Reports Support
///


typealias ReportBody = JSONDictionary

enum ReportKind {
    case aboutPosts
    case aboutPeople
    case aboutFollowers
    case aboutTags
    case adHoc
    func description() -> String {
        switch self {
        case .aboutPosts: return "Posts"
        case .aboutPeople: return "People"
        case .aboutFollowers: return "Followers"
        case .aboutTags: return "Tags"
        case .adHoc: return "Adhoc"
        }
    }
}
typealias ReportResult = (Int,ReportBody,ReportKind)
typealias ReportingFunc = (_ igp:SocialDataProcessor,_ skip:Int,_ limit:Int) -> ReportResult

///
// MARK:- The PdCache is an implicit singleton
///
typealias PdCache = [String:PersonData]
var ThePdCache:PdCache = [:]


//http://stackoverflow.com/questions/29794281/how-to-get-memory-usage-in-swift
func report_memory() -> UInt{
//    var info = task_basic_info()
//    var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info))/4
//    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
//        task_info(mach_task_self_,
//                  task_flavor_t(TASK_BASIC_INFO),
//                  task_info_t($0),
//                  &count)
//    }
//    if kerr == KERN_SUCCESS {
//        return(info.resident_size)
//    }
//    else {
        return 0
  //  }
}

open class ReportMaker {

    /// get skip and limit options from the main URL
    class  func reportOptions(_ request:RouterRequest) -> (Int,Int) {
        var limit = 1000, skip = 0
        if  let lim  = request.queryParameters["limit"] {
            if let lim2  = Int( lim) {
                limit = lim2
            }
        }
        if  let ska  = request.queryParameters["skip"] {
            if let ska2  = Int( ska) {
                skip =  Int( ska2)
            }
        }
        return (limit,skip)
    }
    class   func reportsAvailable(_ response:RouterResponse) {
        do {
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            let item = ["status":200,   "data": reportsDict() ] as [String : Any]
            let r = response.status(HTTPStatusCode.OK)
            let _ =   try r.send(JSON(item).description).end()
        }
        catch {
            Log.error("Could not send")
        }
    }
  
class  func reportMakeForID(_ id:String, _ token:String,_ request:RouterRequest , _ response:RouterResponse) {
        do {
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            // ensure its a valid report anme
            guard let reportname = request.parameters["reportname"] else {
                let item = ["status":533]
                let r = response.status(HTTPStatusCode.badRequest)
                let _ =   try r.send(JSON(item).description).end()
                Log.error("No Report Name")
                return
            }
            //getMemberIDFromToken
            let memberid = try Membership.getMemberIDFromToken(token) //throws
       
            let (mtoken,smtoken) = Membership.getTokensFromID(id: memberid)
            // member must have access token for report generation 
            if let smtoken = smtoken,
                   smtoken == token {
            
            let (limit,skip) = reportOptions(request)
            
            var rqst : JSONDictionary = ["error":"inconsistency" as AnyObject]
            
            let data = ReportMaker.generate_and_send_report(id,token:mtoken!,reportname:reportname,limit:limit,skip:skip,bypasscache: true)
            
            // echo the request
            if let (gkind,_) =  ReportMaker.reportfuncs[reportname]{
                if gkind == .adHoc {
                      rqst = ["time":"\(Date())" as AnyObject,"url":request.urlURL as AnyObject] //"report":reportname,"id":id,
                } else {
                      rqst = ["limit":limit as AnyObject,"skip":skip as AnyObject,"time":"\(Date())" as AnyObject,"url":request.urlURL as AnyObject]
                }
            }
            
            let item = data.count == 0 ? ["status":541] : ["status":200,"request":rqst, "response": data ]
            let r = response.status(HTTPStatusCode.OK)
            let _ =   try r.send(JSON(item).description).end()
                  return
            } // has access token
            else {
                // no token
                let item =  ["status":545]
                let r = response.status(HTTPStatusCode.badRequest)
                let _ =   try r.send(JSON(item).description).end()
                return
            }
        }
        catch {
            Log.error("Cant find token for report")
        }
            //should never get here
    // no token
    let item =  ["status":546]
    let r = response.status(HTTPStatusCode.badRequest)
    let _ =   try! r.send(JSON(item).description).end()
    return
    }
    
   static let reportfuncs:[String : ( ReportKind,ReportingFunc)] =
        [
         "top-posts": ( ReportKind.aboutPosts, ReportMaker.top_posts_report),
         "top-comments": ( ReportKind.aboutPosts,  ReportMaker.top_comments_report),
         "when-posting": ( ReportKind.adHoc,  ReportMaker.when_posting_report),
         "when-topost": ( ReportKind.adHoc,  ReportMaker.when_topost_report),
         
         "all-followers": ( ReportKind.aboutFollowers,   ReportMaker.all_followers_report),
         "ghost-followers": ( ReportKind.aboutFollowers,   ReportMaker.ghost_followers_report),
         "unrequited-followers": ( ReportKind.aboutFollowers,  ReportMaker.unrequited_followers_report),
         "booster-followers": ( ReportKind.aboutFollowers,  ReportMaker.booster_followers_report),
         "secret-admirers": ( ReportKind.aboutFollowers,  ReportMaker.secret_admirer_followers_report),
         
         "most-popular-tags": ( ReportKind.aboutTags,  ReportMaker.most_popular_tags_report),
         "most-popular-taggedusers": ( ReportKind.aboutTags,  ReportMaker.most_popular_taggedusers_report),
         "most-popular-filters": ( ReportKind.aboutTags,  ReportMaker.most_popular_filters_report),
         
         
         "all-followings": ( ReportKind.aboutPeople,   ReportMaker.all_followings_report),
         "top-likers": ( ReportKind.aboutPeople,  ReportMaker.top_likers_report),
         "top-commenters": ( ReportKind.aboutPeople,  ReportMaker.top_commenters_report),
         "speechless-likers": ( ReportKind.aboutPeople,  ReportMaker.speechless_likers_report),
         "heartless-commenters": ( ReportKind.aboutPeople,  ReportMaker.heartless_commenters_report)
    ]
 fileprivate     class func reportsDict()->JSONDictionary {
    
        var newrows :[JSONDictionary] = []
        var row = 0
        for (key,thing) in reportfuncs {
            let(kind,_) = thing
            let type = kind.description()
            newrows.append(["row":row as AnyObject,"type":type as AnyObject,"report-name":key as AnyObject])
            row += 1
        }
        return ["reports":newrows as AnyObject]
    }
    
    // figure out what's available, for now its static
//    class func thereportsAvailable (limit:Int, skip:Int ) -> [String:AnyObject]  {
//        let newrep: [String:AnyObject] = ["under":"re-construction"]
//        return newrep
//    }
    
    
    // MARK:- Read context for id and dispatch to specific report builders
    fileprivate  class func generate_and_send_report (_ id:String,token:String, reportname:String,limit:Int, skip:Int, bypasscache:Bool = false ) -> JSONDictionary {
        let firstmem: UInt = report_memory()
        let start = Date()
        let path = ModelData.membershipPath() + id + ".smaxx"
        var pdx: PersonData!
        if bypasscache == true {
            if let pdxxx = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? PersonData {
                //Log.error(" Report:\(reportname) found user \(id) on disk with forced bypass ")
                ThePdCache[path] = pdxxx // add this to the cache
                pdx = pdxxx
            }
        } else {
        // try for cache lookup
        let fpdx = ThePdCache[path]
        if fpdx != nil {
            pdx = fpdx!
            //Log.error(" Report:\(reportname) found user \(id) in cache ")
        } else {
            if let pdxx = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? PersonData {
                //Log.error(" Report:\(reportname) found user \(id) on disk ")
                ThePdCache[path] = pdxx // add this to the cache
                pdx = pdxx
            }
        }
        } // forced bypass
        
        if pdx != nil {
            
            // setup context for report
       let sdp = SocialDataProcessor(id:id,token:token) // wtf?
            sdp.pd = pdx
        
            // first note loading time to return
            let loadtime  =   "\(Int(Date().timeIntervalSince(start)*1000.0))ms"
            if let ffff =  ReportMaker.reportfuncs[reportname]{
                let (gkind,f) = ffff
                // time how long it takes to produce this report
                let restart = Date()
                sdp.figureLikesAndComments() // compute intermediates!
                
               // print (sdp.pd.postsStatus())
                let (totalcount,body,_) = f(sdp,skip,limit)
               
                ///
                // MARK:- The Report Name and Kind is Reflected Back To The Mobile App
                ///
                let rm:UInt = report_memory()
                let delta:UInt =  rm - firstmem
                var reporthead = ["contextpath":path,
                                  "load-time":loadtime,
                                  "computed-time":"\(Int(Date().timeIntervalSince(restart)*1000.0))ms",
                                  "mem":rm,
                                  "delta":delta] as [String : Any]
                if gkind != .adHoc {
                    reporthead =  ["contextpath":path,
                                    "load-time":loadtime,
                                    "computed-time":"\(Int(Date().timeIntervalSince(restart)*1000.0))ms",
                                    "mem":rm,
                                    "delta":delta,
                                    "row-count":body["rows"]!.count,
                                    "item-count":totalcount]
                }
                
                let thereport:JSONDictionary = [
                                                 "report-status":200 as AnyObject,
                            "title":reportname as AnyObject,
                            "kind":gkind.description() as AnyObject,
                            "report-header" : reporthead as AnyObject,"report-body":body as AnyObject]
                return thereport
            }
        }
         Log.error("Report:\(reportname) awaiting user \(id) full setup")
        let thereport2:JSONDictionary = [
                                       "report-status":541 as AnyObject, // shud trigger a re-ask soon 
                                       "userid":id as AnyObject,
                                       "description":"user initialization not finished yet" as AnyObject]
        return thereport2 // no data will generat a 541 back
        
    }// func report
}
extension SMaxxRouter {
    class func setupRoutesForReports(_ router: Router ) {
        
        ///
        // MARK:-  Reports Available
        ///
        
        router.get("/reports" ) {
            _, response, next in
            ReportMaker.reportsAvailable(response)
            next()
        }
        
        ///
        // MARK:-  Specific Report For Particular User
        ///
        
        router.get("/reports/:id/:reportname") {
            request, response, next in
            guard let token = request.queryParameters["access_token"] else {
                RestSupport.missingID(response)
                return
            }
            
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response)  }
            ReportMaker.reportMakeForID(id,token,request,response)
            next()
        }
        
    }

}

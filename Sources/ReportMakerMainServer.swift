/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  ReportMakerMainServer.swift
//  SMaxxServer
//
//  Created by william donner on 5/3/16.
//
//

import Kitura
import KituraNet 
import LoggerAPI
import SwiftyJSON
import Foundation


///
// MARK:-  Reports Support
///

/// Reports routes:
///
/// get("/reports")
/// get("/reports/:id/:reportname") 


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

class ReportMakerMainServer : SeparateServer {
    
    typealias PdCache = [String:PersonData]
    fileprivate var ThePdCache:PdCache = [:]
    

    var port:Int16 = 0
    var smaxx:Smaxx 
    
    init(port:Int16,smaxx:Smaxx) {
        self.port = port
        self.smaxx = smaxx
    }
    
    
     func mainPort() -> Int16 {
        return self.port
    }
     func jsonStatus() -> JSONDictionary {
        return  ["router-for":"reports","port":port,"cached":ThePdCache.count] as [String : Any]
    }

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
            let item = ["status":SMaxxResponseCode.success ,   "data": reportsDict()] as JSONDictionary
            try AppResponses.sendgooresponse(response,item )
        }
        catch {
            Log.error("Could not send")
        }
    }
    
  private   class  func reportMakeForID(_ memberid:String, _ token:String,_ request:RouterRequest , _ response:RouterResponse) {
        do {
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            // ensure its a valid report anme
            guard let reportname = request.parameters["reportname"] else {
                let item = ["status":SMaxxResponseCode.badMemberID ] as JSONDictionary
                try? AppResponses.sendbadresponse(response,item)
                return
            }
            //getMemberIDFromToken
            //let memberid = MembersCache.getMemberIDFromTokenFromCache(token)
            guard   let (mtoken,smtoken) = MembersCache.getTokenFromIDFromCache(id: memberid) else {
                let item = ["status":SMaxxResponseCode.noToken ] as JSONDictionary
                    try? AppResponses.sendbadresponse(response,item)
                return
            } 
                guard token == tokenid else {
                    let item = ["status":SMaxxResponseCode.noToken ] as JSONDictionary
                    try? AppResponses.sendbadresponse(response,item)
                    return
                    
                }
                if let memid = memberid {
            
                    // member must have access token for report generation
                    if let smtoken = smtoken,
                        smtoken == token {
                        
                        let (limit,skip) = reportOptions(request)
                        
                        var rqst : JSONDictionary = ["error":"inconsistency" as AnyObject]
                        
                        let data = ReportMakerMainServer.generate_and_send_report(id,token:mtoken!,reportname:reportname,limit:limit,skip:skip,bypasscache: true)
                        
                        // echo the request
                        if let (gkind,_) =  ReportMakerMainServer.reportfuncs[reportname]{
                            if gkind == .adHoc {
                                rqst = ["time":"\(Date())" ,"url":request.urlURL ] //"report":reportname,"id":id,
                            } else {
                                rqst = ["limit":limit ,"skip":skip ,"time":"\(Date())" ,"url":request.urlURL ]
                            }
                        }
                        
                        let item = data.count == 0 ? ["status":SMaxxResponseCode.noData] : ["status":SMaxxResponseCode.success ,"request":rqst, "response": data ]
                        try AppResponses.sendgooresponse(response,item as JSONDictionary )
                        
                        return
                    } // has access token
                    else {
                        // no token
                        let item =  ["status":SMaxxResponseCode.noToken as AnyObject] as JSONDictionary
                        try? AppResponses.sendbadresponse(response, item)
                        return
                    }
                }
        } // do
  catch {
    Log.error("Cant find token for report")
    }
        
    // no token
    let item =  ["status":SMaxxResponseCode.noToken as AnyObject] as JSONDictionary
    try? AppResponses.sendbadresponse(response, item)
}

static let reportfuncs:[String : ( ReportKind,ReportingFunc)] =
    [
        "top-posts": ( ReportKind.aboutPosts, ReportMakerMainServer.top_posts_report),
        "top-comments": ( ReportKind.aboutPosts,  ReportMakerMainServer.top_comments_report),
        "when-posting": ( ReportKind.adHoc,  ReportMakerMainServer.when_posting_report),
        "when-topost": ( ReportKind.adHoc,  ReportMakerMainServer.when_topost_report),
        
        "all-followers": ( ReportKind.aboutFollowers,   ReportMakerMainServer.all_followers_report),
        "ghost-followers": ( ReportKind.aboutFollowers,   ReportMakerMainServer.ghost_followers_report),
        "unrequited-followers": ( ReportKind.aboutFollowers,  ReportMakerMainServer.unrequited_followers_report),
        "booster-followers": ( ReportKind.aboutFollowers,  ReportMakerMainServer.booster_followers_report),
        "secret-admirers": ( ReportKind.aboutFollowers,  ReportMakerMainServer.secret_admirer_followers_report),
        
        "most-popular-tags": ( ReportKind.aboutTags,  ReportMakerMainServer.most_popular_tags_report),
        "most-popular-taggedusers": ( ReportKind.aboutTags,  ReportMakerMainServer.most_popular_taggedusers_report),
        "most-popular-filters": ( ReportKind.aboutTags,  ReportMakerMainServer.most_popular_filters_report),
        
        "all-followings": ( ReportKind.aboutPeople,   ReportMakerMainServer.all_followings_report),
        "top-likers": ( ReportKind.aboutPeople,  ReportMakerMainServer.top_likers_report),
        "top-commenters": ( ReportKind.aboutPeople,  ReportMakerMainServer.top_commenters_report),
        "speechless-likers": ( ReportKind.aboutPeople,  ReportMakerMainServer.speechless_likers_report),
        "heartless-commenters": ( ReportKind.aboutPeople,  ReportMakerMainServer.heartless_commenters_report)
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



// MARK:- Read context for id and dispatch to specific report builders
fileprivate  class func generate_and_send_report (_ id:String,token:String, reportname:String,limit:Int, skip:Int, bypasscache:Bool = false ) -> JSONDictionary {
    let firstmem: UInt = report_memory()
    let start = Date()
    let path =  pathForMemberArchive(id)
    var pdx: PersonData!
    if bypasscache == true {
        if let pdxxx = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? PersonData {
            //Log.error(" Report:\(reportname) found user \(id) on disk with forced bypass ")
            reportMakerMainServer.ThePdCache[path] = pdxxx // add this to the cache
            pdx = pdxxx
        }
    } else {
        // try for cache lookup
        let fpdx = reportMakerMainServer.ThePdCache[path]
        if fpdx != nil {
            pdx = fpdx!
            //Log.error(" Report:\(reportname) found user \(id) in cache ")
        } else {
            if let pdxx = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? PersonData {
                //Log.error(" Report:\(reportname) found user \(id) on disk ")
                reportMakerMainServer.ThePdCache[path] = pdxx // add this to the cache
                pdx = pdxx ////
            }
        }
    } // forced bypass
    
    if pdx != nil {///
        
        // setup context for report
        let sdp = SocialDataProcessor(id:id,token:token) // wtf?
        sdp.pd = pdx
        
        // first note loading time to return
        let loadtime  =   "\(Int(Date().timeIntervalSince(start)*1000.0))ms"
        if let ffff =  ReportMakerMainServer.reportfuncs[reportname]{
            let (gkind,f) = ffff
            // time how long it takes to produce this report
            let restart = Date()
            sdp.figureLikesAndComments() // compute intermediates!
            
            /// where REPORT GETS GENERATED happens
            let (totalcount,body,_) = f(sdp,skip,limit)
            ///
            
            
            
            
            
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
                    "row-count":(body["rows"]! as AnyObject).count,
                    "item-count":totalcount]
            }
            
            let thereport:JSONDictionary = [
                "report-status":SMaxxResponseCode.success  as AnyObject,
                "title":reportname as AnyObject,
                "kind":gkind.description() as AnyObject,
                "report-header" : reporthead as AnyObject,"report-body":body as AnyObject]
            return thereport
        }
    }
    Log.error("Report:\(reportname) awaiting user \(id) full setup")
    let thereport2:JSONDictionary = [
        "report-status":SMaxxResponseCode.waiting , // shud trigger a re-ask soon
        "userid":id as AnyObject,
        "description":"user initialization not finished yet" ]
    return thereport2 // no data will generat a 541 back
    
}// func report
}
extension Router {
     func setupRoutesForReports(mainServer:ReportMakerMainServer, smaxx:Smaxx) {
            
            // must support MainServer protocol
            
       //     let port = mainServer.mainPort()
        
       // print("*** setting up Reports  on port \(port) ***")
        
        
        self.get("/status") {
            request, response, next in
            
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            do {
                try response.status(HTTPStatusCode.OK).send(JSON(mainServer.jsonStatus()).description).end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
            
            //next()
        }
        
        
        ///
        // MARK:-  Reports Available
        ///
        
        self.get("/reports" ) {
            _, response, next in
            ReportMakerMainServer.reportsAvailable(response)
            next()
        }
        
        ///
        // MARK:-  Specific Report For Particular User
        ///
        
        self.get("/reports/:id/:reportname") {
            request, response, next in
            guard let token = request.queryParameters["access_token"] else {
                AppResponses.missingID(response)
                return
            }
            
            guard let id = request.parameters["id"] else { return AppResponses.missingID(response)  }
            ReportMakerMainServer.reportMakeForID(id,token,request,response)
            next()
        }
        
    }
    
}

///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  Membership
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


//// all varieties of server include these functions to access a remote Membership server in a highly performant manner

open class MembersCache {
    class func isMemberFromCache(_ id:String)->Bool {
        return Members.m_isMember(id)  // DOES NOT PLACE REMOTE CALL, JUST RETURNS CACHED VALUE, IF ANY
        
    }
    class func getTokenFromIDFromCache(id:String)-> String? {
        let tok = Members.m_getTokenFromID(id: id) // DOES NOT PLACE REMOTE CALL, JUST RETURNS CACHED VALUE, IF ANY
        return( tok )
    }
    class func getTokensFromIDFromCache(id:String)->(String?,String?){
        let tok = Members.m_getTokensFromID(id: id)
        return (tok.0,tok.1)
    }
    class func getMemberIDFromTokenFromCache(_ token:String)->String?  {
        let id = Members.m_getMemberIDFromToken(token)
        return(id)
    }
    class func isMember(_ id:String,completion:@escaping (Bool)->()) {
       let b =  Members.m_isMember(id)
        completion( b )
    
    }
    class func getTokenFromID(id:String,completion: @escaping(String?)->()) {
        let tok = Members.m_getTokenFromID(id: id)
        completion( tok )
    }
    class func getTokensFromID(id:String, completion: @escaping ((String?,String?) ->())){
        let tok = Members.m_getTokensFromID(id: id)
        completion (tok.0,tok.1)
    }
    class func getMemberIDFromToken(_ token:String, completion:@escaping ((String?) -> ())) {
        completion(nil)
        let id = Members.m_getMemberIDFromToken(token)
        completion(id)
    }
}



/// This "MainServer" is started on its own port via the addHTTPServer Kitura api

class Members : MainServer {
    
  static var members :   [String:AnyObject] = [:] // not jsondictionary

//    class var shared: Membership {
//        struct Singleton {
//            static let sharedMembership = Membership()
//        }
//        return Singleton.sharedMembership
//    }
    
    class func m_isMember(_ id:String) -> Bool {
        
        //from all over
         if let _ =  members[id] {
            return true
        }
        return false 
    }
    //from all over
    class func m_getTokenFromID(id:String) -> String? {
        //from all over

    // member must have access token for instagram api access
        let mem =  members[id] as AnyObject
       if  let token = mem["access_token"] as? String {
        return token
    }
        return nil
    }
    class func m_getTokensFromID(id:String) -> (String?,String?) { // from reportmaker
        // member must have access token for instagram api access
        if    let mem =  members[id]{
            let token = mem["access_token"] as? String
            let stoken = mem["smaxx-token"] as? String
            return (token,stoken)
        }
        return( nil,nil)
    }
    //mem[  "smaxx-token"]
    class func m_getMemberIDFromToken(_ token:String) -> String? {// from reportmaker

        for (_,member) in members {
            if member["smaxx-token"] as! String  == token {
                return member["id"] as? String
            }
        }
        return nil
    }
    
    
    
    
    
    //// remote calls
    
    class    func addMembership(_ request:RouterRequest , _ response:RouterResponse) {
        
        //        guard let id = request.params["id"] else {
        //            response.status(HTTPStatusCode.badRequest)
        //            Log.error("id parameter not found in request")
        //            return
        //        }
        // Log.error ("post request has \(request.queryParams)")
        
        let title = request.queryParameters["title"] ?? "no title"
        let id = request.queryParameters["id"] ?? "no idr"
        do {
            if  members[id] != nil {
                // duplicate
                AppResponses.acceptgoodrequest(response,  SMaxxResponseCode.duplicate)
            } else {
                
                
                // adjust membership table and save it to disk
                 members[id] = ["id":id   ,"created":("\(Date())"    ),
                                                 "named":title    ]   as AnyObject?
 
                /// save entire pile
                
                try  save ( )
                //Log.info("saved membership state")
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":SMaxxResponseCode.success    ] as    JSONDictionary).description).end()
            }
        }
        catch  {
            Log.error("Could not send")
        }
    }
    
    class   func deleteMembershipForID (_ id:String, _ response:RouterResponse) {
        /// remove from memory and save entire pile
        do {
             members[id] = nil
            
            
            try   save ()
            
            let dict = ["status":SMaxxResponseCode.success    , "data":members  ] as JSONDictionary
            let jsonDict = JSON(dict )
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            try response.status(HTTPStatusCode.OK).send(jsonDict.description).end()
        }
        catch {
            response.status(HTTPStatusCode.badRequest)
        }
    }
    
    class    func membershipForID(_  id:String, _ response:RouterResponse) {
        do {
              response.headers["Content-Type"] = "application/json; charset=utf-8"
            if let x = members[id] {
                let item = ["status":SMaxxResponseCode.success    ,   "data": x ] as JSONDictionary
                try AppResponses.sendgooresponse(response,item )
            }  else
            {
                let item = ["status":  SMaxxResponseCode.badMemberID] 
                let r = response.status(HTTPStatusCode.badRequest)
                let _ =   try r.send(JSON(item).description).end()
               // Log.error("Request has bad member id")
            }
        }
        catch {
            Log.error("Could not send")
        }
    }
    
    class  func deleteMembership(_ request:RouterRequest,_ response:RouterResponse) {
        /// remove from memory and save entire pile
        do {
            members = [:]
            
         
            
            try   save ( )
            
            let dict = ["status":SMaxxResponseCode.success    , "data":[:]   ] as JSONDictionary
            let jsonDict = JSON(dict )
            
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            try response.status(HTTPStatusCode.OK).send(jsonDict.description).end()
        }
        catch {
            response.status(HTTPStatusCode.badRequest)
        }
    }
    class   func  membershipList(_ request:RouterRequest,_ response:RouterResponse) {
        
        let (limit,skip) = ReportMaker.reportOptions(request)
        
        /// filter membership as per skip and limit
        var mems :  JSONDictionary = [:]
        var idx = 0 , issued = 0
        for (key,val) in  members {
            if issued <  limit  {
                if idx >= skip {
                    mems[key] = val // include
                    issued += 1
                }
            }
            idx += 1
        }
        
        let item = ["status":SMaxxResponseCode.success    , "limit":limit   ,"skip":skip   ,"data":[mems]    ] as JSONDictionary
        do {
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            try response.status(HTTPStatusCode.OK).send(JSON(item).description).end()
        }
        catch {
            
            Log.error("Failed to send response \(error)")
        }
    }
    
    ///
    /// restore from keyed archive plist
    fileprivate class func restoreme(_ userID:String) throws ->   JSONDictionary {
        let spec = ModelData.membershipPath() +  "\(userID).smaxx"
        do {
            if let pdx = NSKeyedUnarchiver.unarchiveObject(withFile:spec)  as?    JSONDictionary {
                return pdx
            }
            throw SMaxxError.cantDecodeMembership(message : spec )
        }
        catch  {
            throw  SMaxxError.cantRestoreMembership(message: spec )
        }
    }
    /// Restore state of membership
    class func restoreMembership() {
        do {
            let d  = try  restoreme("_membership")
            if let mem  = d["data"] as? [String : AnyObject] {
                 members = mem
                //Log.info("membership restored to: \(membership)")
            }
            else { Log.info ("-----could not restore membership") }
        }
        catch {
            Log.info ("-----could not restore membership")
        }
    }
    /// save as keyed archive plist
   class func save ( ) throws {         let start = Date()
        let spec = ModelData.membershipPath() +  "_MembersCachesmaxx"
        if  !NSKeyedArchiver.archiveRootObject(["status":SMaxxResponseCode.success ,"data": members],
                                               toFile:spec ){
            throw SMaxxError.cantWriteMembership(message: spec )
        } else {
            let elapsed  =   "\(Int(Date().timeIntervalSince(start)*1000.0))ms"
             Log.info("****************Saved Instagram Data to \(spec)  in \(elapsed), ****************")
        }
    }

}

extension Router {
    
     func setupRoutesForMembership(port:Int16) {
        
        
        print("*** setting up Membership  on port \(port) ***")
        
        /// Create or restore the Membership DB
        ///
        Members.restoreMembership()
        
        self.get("/status") {
            request, response, next in
            
            let r = ["router-for":"workers","port":port] as [String : Any]
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            do {
                try response.status(HTTPStatusCode.OK).send(JSON(r).description).end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
            
            //next()
        }
        
       
        ///
        // MARK:- Membership tracks who has the app and has consented to our terms
        ///
        self.get("/membership/:id") {
            request, response, next -> () in
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response)  }
            Members.membershipForID(id,response)
            next()
        }
        ///
        // MARK:- Delete an individual membership item
        ///
        self.delete("/membership/:id") {
            request, response, next in
            
            Log.error("delete /membership/:id")
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response)  }
              Members.deleteMembershipForID(id,response)
            next()
        }
        ///
        // MARK:- Membership list
        ///
        self.get("/membership") {
            request, response, next in
              Members.membershipList(request, response)
            next()
        }
        
        ///
        // MARK:- Post Adds A membership
        ///
        self.post("/membership") {
            request, response, next in
              Members.addMembership(request,response)
            next()
        }
        
        ///
        // MARK:- Delete  all
        ///
        self.delete("/membership") {
            request, response, next in
              Members.deleteMembership(request,response)
            next()
        }

        self.get("/showlogin") { request, response, next in
            Sm.axx.ci.STEP_ONE(response) // will redirect to IG
            
            //next()
        }
        self.get("/authcallback") { request, response, next in
            // Log.error("/login/instagram will authenticate ")
            Sm.axx.ci.STEP_TWO (request, response: response ) { status in
                if status != 200 { Log.error("Back from STEP_TWO status \(status) ") }
            }
            
            //next()
        }
        self.get("/unwindor") { request, response, next in
            // just a means of unwinding after login , with data passed via queryparam
            Sm.axx.ci.STEP_THREE (request, response: response )
            do {
                
                let id = request.queryParameters["smaxx-id"] ?? "no id"
                let smtoken = request.queryParameters["smaxx-token"] ?? "no smtoken"
                let name = request.queryParameters["smaxx-name"] ?? "no smname"
                let pic = request.queryParameters["smaxx-pic"] ?? "no smpic"
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":SMaxxResponseCode.success    ,"smaxx-id":id   , "smaxx-pic":pic   ,"smaxx-token":smtoken   ,"smaxx-name":name   ] as    JSONDictionary).description).end()
            }
            catch {
                Log.error("Failed /authcallback redirect \(error)")
            }
            //next()
        }
        
    }
    

}
extension Members {
    
    class func processInstagramResponse(body:Data)->( String , String, String, String, String )  {
        var ret = ("","","","","")
        let jsonBody = JSON(data: body)
        if let token = jsonBody["access_token"].string,
            let userid = jsonBody["user"]["id"].string,
            let pic = jsonBody["user"]["profile_picture"].string,
            let title = jsonBody["user"]["username"].string {
            //   Log.info("STEP_TWO Instagram sent back \(token) and \(title)")
            /// stash these, creating new object if needed
            do {
                let smtoken = "\((userid + token).hashValue)"
                let nows = "\(NSDate())" // time now as string
                let mu =  Members.members[userid]
                if mu != nil {
                    // already there, just update last login time
                    if let created = mu!["created"] as? String {
                         Members.members[userid] = ["id":userid    ,
                                                             "created":created   ,
                                                             "last-login":nows   ,
                                                             "named":title   ,
                                                             "pic":pic    ,
                                                             "access_token":token    ,
                                                             "smaxx-token":smtoken    ] as AnyObject
                        // error
                        Log.error("Could not find created field in mu")
                    }
                } else {
                    // not there make new
                    Members.members[userid] = ["id":userid    ,
                                                         "created":nows    ,
                                                         "last-login":nows    ,
                                                         "named":title    ,
                                                         "pic":pic    ,
                                                         "access_token":token    ,
                                                         "smaxx-token":smtoken     ]  as AnyObject
                }
                
                ////////////// VERY INEFFICIENT , REWRITES ALL RECORDS ON ANY UPDATE ///////////////////
                /// adjust membership table and save it to disk
                /// save entire pile
                try  Members.save ( )
                //Log.info("saved membership state")
                ret = ( userid , token, smtoken, title, pic )
            }
            catch  {
                Log.error("Could not save membership")
            }
        }
        return ret
    }
}

///
// MARK:- Hack Login to Instagram
///
//        router.get("/login") { request, response, next in
//            response.headers["Content-Type"] = "text/html; charset=utf-8"
//            do {
//                try response.status(.OK).send(
//                    "<!DOCTYPE html><html><body>" +
//                        "<a href=/authcallback>Log In with Instagram</a><br>" +
//                    "</body></html>\n\n").end()
//            }
//            catch {}
//            next()
//        }

        

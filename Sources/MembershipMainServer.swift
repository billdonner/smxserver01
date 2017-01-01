///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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



/// This "MainServer" is started on its own port via the addHTTPServer Kitura api

class MembersMainServer : MainServer {
    
    var port:Int16 = 0
    
    init(port:Int16) {
        self.port = port
    }
    
  static var members :   [String:AnyObject] = [:] // not jsondictionary

    func mainPort() -> Int16 {
        return self.port
    }
    func jsonStatus() -> JSONDictionary {
        return [:]
    }
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
        
        let (limit,skip) = ReportMakerMainServer.reportOptions(request)
        
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
        let spec = HomePageMainServer.membershipPath() +  "\(userID).smaxx"
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
        let spec = HomePageMainServer.membershipPath() +  "_MembersCachesmaxx"
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
    
     func setupRoutesForMembership( mainServer:MainServer) {
            
            // must support MainServer protocol
            
            let port = mainServer.mainPort()
        
        print("*** setting up Membership  on port \(port) ***")
        
        /// Create or restore the Membership DB
        ///
        MembersMainServer.restoreMembership()
        
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
            guard let id = request.parameters["id"] else { return AppResponses.missingID(response)  }
            MembersMainServer.membershipForID(id,response)
            next()
        }
        ///
        // MARK:- Delete an individual membership item
        ///
        self.delete("/membership/:id") {
            request, response, next in
            
            Log.error("delete /membership/:id")
            guard let id = request.parameters["id"] else { return AppResponses.missingID(response)  }
              MembersMainServer.deleteMembershipForID(id,response)
            next()
        }
        ///
        // MARK:- Membership list
        ///
        self.get("/membership") {
            request, response, next in
              MembersMainServer.membershipList(request, response)
            next()
        }
        
        ///
        // MARK:- Post Adds A membership
        ///
        self.post("/membership") {
            request, response, next in
              MembersMainServer.addMembership(request,response)
            next()
        }
        
        ///
        // MARK:- Delete  all
        ///
        self.delete("/membership") {
            request, response, next in
              MembersMainServer.deleteMembership(request,response)
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
extension MembersMainServer {
    
    class func rewriteMemberInfo(_ ble:AnyObject) -> ( String , String, String, String, String )  {
        var ret = ("","","","","")
        if let userid = ble["id"] as? String {
            do {
                
                let mu =  MembersMainServer.members[userid]
                if mu != nil {
                    // already there, just update last login time
                    //                if let created = mu!["created"] as? String {
                    //                    mu!["created"] = ble["created"] as? String
                    //                    MembersMainServer.members[userid] = ble
                    //                    // error
                    //                    Log.error("Could not find created field in mu")
                    //                }
                } else {
                    // not there make new
                    MembersMainServer.members[userid] = ble
                }
                
                ////////////// VERY INEFFICIENT , REWRITES ALL RECORDS ON ANY UPDATE ///////////////////
                /// adjust membership table and save it to disk
                /// save entire pile
                try  MembersMainServer.save ( )
                //Log.info("saved membership state")
                ret = ( userid , "","","","")// token, smtoken, title, pic )
            }
            catch  {
                Log.error("Could not save membership")
            }
        }// has id
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

        

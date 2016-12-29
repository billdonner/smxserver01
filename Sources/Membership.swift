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

///
/// A Persistent Class via Plist
/// TODO: replace w Cloudant or similar

open class Membership {
    
    ///
    /// the members are directly accessible via igID,

    fileprivate var members : [String:AnyObject] = [:]
    
    class var shared: Membership {
        struct Singleton {
            static let sharedMembership = Membership()
        }
        return Singleton.sharedMembership
    }
    
    class func isMember(_ id:String) -> Bool {
         if let _ = Membership.shared.members[id] {
            return true
        }
        return false 
    }
    
    class func getTokenFromID(id:String) -> String? {
    // member must have access token for instagram api access
    if    let mem = Membership.shared.members[id],
        let token = mem["access_token"] as? String {
        return token
    }
        return nil
    }
    class func getTokensFromID(id:String) -> (String?,String?) {
        // member must have access token for instagram api access
        if    let mem = Membership.shared.members[id]{
            let token = mem["access_token"] as? String
            let stoken = mem["smaxx-token"] as? String
            return (token,stoken)
        }
        return( nil,nil)
    }
    //mem[  "smaxx-token"]
    class func getMemberIDFromToken(_ token:String) throws -> String {
        for (_,member) in Membership.shared.members {
            if member["smaxx-token"] as! String  == token {
                return member["id"] as! String
            }
        }
      throw SMaxxError.bad(arg: 577)
    }
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
            if Membership.shared.members[id] != nil {
                // duplicate
                let dict = ["status":539 as AnyObject]  as  [String:AnyObject]
                try response.status(HTTPStatusCode.OK).send(JSON(dict).description).end()
            } else {
                
                
                // adjust membership table and save it to disk
                Membership.shared.members[id] = ["id":id as AnyObject,"created":("\(Date())"  as AnyObject),
                                                 "named":title as AnyObject ]  as AnyObject

                
                let dict = ["status":200 as AnyObject, "data":Membership.shared.members as AnyObject] as  [String:AnyObject]
                
                /// save entire pile
                
                try  Membership.save ("_membership",dict:dict)
                //Log.info("saved membership state")
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":200 as AnyObject] as  [String:AnyObject]).description).end()
            }
        }
        catch  {
            Log.error("Could not send")
        }
    }
    
    class   func deleteMembershipForID (_ id:String, _ response:RouterResponse) {
        /// remove from memory and save entire pile
        do {
            Membership.shared.members[id] = nil
            
            let dict = ["status":200 as AnyObject, "data":Membership.shared.members as AnyObject] as  [String:AnyObject]
            let jsonDict = JSON(dict )
            
            try  Membership.save ("_membership",dict:dict)
            //Log.info("saved membership state")
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
            if let x = Membership.shared.members[id] {
                let item = ["status":200,   "data": x ] as [String : Any]
                let r = response.status(HTTPStatusCode.OK)
                let _ =   try r.send(JSON(item).description).end()
            }  else
            {
                
                let item = ["status":533]
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
            Membership.shared.members = [:]
            
            let dict = ["status":200 as AnyObject, "data":[:] as AnyObject] as  [String:AnyObject]
            let jsonDict = JSON(dict )
            
            try  Membership.save ("_membership",dict:dict)
            //Log.info("saved membership state")
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
        var mems :[String:AnyObject] = [:]
        var idx = 0 , issued = 0
        for (key,val) in Membership.shared.members {
            if issued <  limit  {
                if idx >= skip {
                    mems[key] = val // include
                    issued += 1
                }
            }
            idx += 1
        }
        
        let item = ["status":200 as AnyObject, "limit":limit as AnyObject,"skip":skip as AnyObject,"data":[mems]  as AnyObject] as [String : AnyObject]
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
    fileprivate class func restoreme(_ userID:String) throws -> [String:AnyObject] {
        let spec = ModelData.membershipPath() +  "\(userID).smaxx"
        do {
            if let pdx = NSKeyedUnarchiver.unarchiveObject(withFile:spec)  as?  [String:AnyObject] {
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
            let d  = try Membership.restoreme("_membership")
            if let mem  = d["data"] as? [String : AnyObject] {
                Membership.shared.members = mem
                //Log.info("membership restored to: \(membership)")
            }
            else { Log.info ("-----could not restore membership") }
        }
        catch {
            Log.info ("-----could not restore membership")
        }
    }
    /// save as keyed archive plist
   class func save (_ userID:String,dict:[String:AnyObject]) throws {
        let start = Date()
        let spec = ModelData.membershipPath() +  "\(userID).smaxx"
        if  !NSKeyedArchiver.archiveRootObject(dict, toFile:spec ){
            throw SMaxxError.cantWriteMembership(message: spec )
        } else {
            let elapsed  =   "\(Int(Date().timeIntervalSince(start)*1000.0))ms"
             Log.info("****************Saved Instagram Data to \(spec)  in \(elapsed), ****************")
        }
    }

}

extension SMaxxRouter {
    class func setupRoutesForMembership(_ router: Router ) {

        
        ///
        // MARK:- Membership tracks who has the app and has consented to our terms
        ///
        router.get("/membership/:id") {
            request, response, next in
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response)  }
            Membership.membershipForID(id,response)
            next()
        }
        ///
        // MARK:- Delete an individual membership item
        ///
        router.delete("/membership/:id") {
            request, response, next in
            
            Log.error("delete /membership/:id")
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response)  }
            Membership.deleteMembershipForID(id,response)
            next()
        }
        ///
        // MARK:- Membership list
        ///
        router.get("/membership") {
            request, response, next in
            Membership.membershipList(request, response)
            next()
        }
        
        ///
        // MARK:- Post Adds A membership
        ///
        router.post("/membership") {
            request, response, next in
            Membership.addMembership(request,response)
            next()
        }
        
        ///
        // MARK:- Delete  all
        ///
        router.delete("/membership") {
            request, response, next in
            Membership.deleteMembership(request,response)
            next()
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

        
        router.get("/showlogin") { request, response, next in
            Sm.axx.ci.STEP_ONE(response) // will redirect to IG
            
            //next()
        }
        router.get("/authcallback") { request, response, next in
            // Log.error("/login/instagram will authenticate ")
            Sm.axx.ci.STEP_TWO (request, response: response ) { status in
                if status != 200 { Log.error("Back from STEP_TWO status \(status) ") }
            }
            
            //next()
        }
        router.get("/unwindor") { request, response, next in
            // just a means of unwinding after login , with data passed via queryparam
            Sm.axx.ci.STEP_THREE (request, response: response )
            do {
                
                let id = request.queryParameters["smaxx-id"] ?? "no id"
                let smtoken = request.queryParameters["smaxx-token"] ?? "no smtoken"
                let name = request.queryParameters["smaxx-name"] ?? "no smname"
                let pic = request.queryParameters["smaxx-pic"] ?? "no smpic"
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":200 as AnyObject,"smaxx-id":id as AnyObject, "smaxx-pic":pic as AnyObject,"smaxx-token":smtoken as AnyObject,"smaxx-name":name as AnyObject] as  [String:AnyObject]).description).end()
            }
            catch {
                Log.error("Failed /authcallback redirect \(error)")
            }
            //next()
        }
        
    }
    

}
extension Membership {
    
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
                let mu = Membership.shared.members[userid]
                if mu != nil {
                    // already there, just update last login time
                    if let created = mu!["created"] as? String {
                        Membership.shared.members[userid] = ["id":userid  as AnyObject,
                                                             "created":created as AnyObject,
                                                             "last-login":nows as AnyObject,
                                                             "named":title as AnyObject,
                                                             "pic":pic  as AnyObject,
                                                             "access_token":token  as AnyObject,
                                                             "smaxx-token":smtoken  as AnyObject] as AnyObject
                        // error
                        Log.error("Could not find created field in mu")
                    }
                } else {
                    // not there make new
                    Membership.shared.members[userid] = ["id":userid  as AnyObject,
                                                         "created":nows  as AnyObject,
                                                         "last-login":nows  as AnyObject,
                                                         "named":title  as AnyObject,
                                                         "pic":pic  as AnyObject,
                                                         "access_token":token  as AnyObject,
                                                         "smaxx-token":smtoken   as AnyObject]  as AnyObject
                }
                
                ////////////// VERY INEFFICIENT , REWRITES ALL RECORDS ON ANY UPDATE ///////////////////
                /// adjust membership table and save it to disk
                let dict = ["status":200 as AnyObject, "data":Membership.shared.members as AnyObject] as  [String:AnyObject]
                /// save entire pile
                try  Membership.save ("_membership",dict:dict)
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

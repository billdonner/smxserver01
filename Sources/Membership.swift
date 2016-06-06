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
import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation

///
/// A Persistent Class via Plist
/// TODO: replace w Cloudant or similar

public class Membership {
    
    ///
    /// the members are directly accessible via igID,

    var members : [String:AnyObject] = [:]
    
    class var shared: Membership {
        struct Singleton {
            static let sharedMembership = Membership()
        }
        return Singleton.sharedMembership
    }
    
    class func isMember(id:String) -> Bool {
         if let _ = Membership.shared.members[id] {
            return true
        }
        return false 
    }
    class func getMemberIDFromToken(token:String) throws -> String {
        for (_,member) in Membership.shared.members {
            if member["smaxx-token"] as! String  == token {
                return member["id"] as! String
            }
        }
      throw SMaxxError.Bad(arg: 577)
    }
    class    func addMembership(_ request:RouterRequest , _ response:RouterResponse) {
        
        //        guard let id = request.params["id"] else {
        //            response.status(HTTPStatusCode.badRequest)
        //            Log.error("id parameter not found in request")
        //            return
        //        }
        // Log.error ("post request has \(request.queryParams)")
        
        let title = request.queryParams["title"] ?? "no title"
        let id = request.queryParams["id"] ?? "no idr"
        do {
            if Membership.shared.members[id] != nil {
                // duplicate
                let dict = ["status":539]  as  [String:AnyObject]
                try response.status(HTTPStatusCode.OK).send(JSON(dict).description).end()
            } else {
                
                
                // adjust membership table and save it to disk
                Membership.shared.members[id] = ["id":id,"created":"\(NSDate())","named":title ]
                
                let dict = ["status":200, "data":Membership.shared.members] as  [String:AnyObject]
                
                /// save entire pile
                
                try  Membership.save ("_membership",dict:dict)
                //Log.info("saved membership state")
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":200] as  [String:AnyObject]).description).end()
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
            
            let dict = ["status":200, "data":Membership.shared.members] as  [String:AnyObject]
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
                let item = ["status":200,   "data": x ]
                let r = response.status(HTTPStatusCode.OK)
                let _ =   try r.send(JSON(item).description).end()
            }  else
            {
                
                let item = ["status":533]
                let r = response.status(HTTPStatusCode.badRequest)
                let _ =   try r.send(JSON(item).description).end().end()
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
            
            let dict = ["status":200, "data":[:]] as  [String:AnyObject]
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
        let item = ["status":200, "limit":limit,"skip":skip,"data":[mems]]
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
    private class func restoreme(_ userID:String) throws -> [String:AnyObject] {
        let spec = ModelData.membershipPath() +  "\(userID).smaxx"
        do {
            if let pdx = NSKeyedUnarchiver.unarchiveObject(withFile:spec)  as?  [String:AnyObject] {
                return pdx
            }
            throw SMaxxError.CantDecodeMembership(message : spec )
        }
        catch  {
            throw  SMaxxError.CantRestoreMembership(message: spec )
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
        let start = NSDate()
        let spec = ModelData.membershipPath() +  "\(userID).smaxx"
        if  !NSKeyedArchiver.archiveRootObject(dict, toFile:spec ){
            throw SMaxxError.CantWriteMembership(message: spec )
        } else {
            let _  =   "\(Int(NSDate().timeIntervalSince(start)*1000.0))ms"
            // Log.info("****************Saved Instagram Data to \(spec)  in \(elapsed), ****************")
        }
    }

}

extension SMaxxRouter {
    class func setupRoutesForMembership(router: Router ) {

        
        ///
        // MARK:- Membership tracks who has the app and has consented to our terms
        ///
        router.get("/membership/:id") {
            request, response, next in
            guard let id = request.params["id"] else { return RestSupport.missingID(response)  }
            Membership.membershipForID(id,response)
            next()
        }
        ///
        // MARK:- Delete an individual membership item
        ///
        router.delete("/membership/:id") {
            request, response, next in
            
            Log.error("delete /membership/:id")
            guard let id = request.params["id"] else { return RestSupport.missingID(response)  }
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
            Sm.axx.ci.STEP_ONE(response:response) // will redirect to IG
            
            //next()
        }
        router.get("/authcallback") { request, response, next in
            // Log.error("/login/instagram will authenticate ")
            Sm.axx.ci.STEP_TWO (request: request, response: response ) { status in
                if status != 200 { Log.error("Back from STEP_TWO status \(status) ") }
            }
            
            //next()
        }
        router.get("/unwindor") { request, response, next in
            // just a means of unwinding after login , with data passed via queryparam
            Sm.axx.ci.STEP_THREE (request: request, response: response )
            do {
                
                let id = request.queryParams["smaxx-id"] ?? "no id"
                let smtoken = request.queryParams["smaxx-token"] ?? "no smtoken"
                let name = request.queryParams["smaxx-name"] ?? "no smname" 
                let pic = request.queryParams["smaxx-pic"] ?? "no smpic"
                response.headers["Content-Type"] = "application/json; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send(JSON(["status":200,"smaxx-id":id, "smaxx-pic":pic,"smaxx-token":smtoken,"smaxx-name":name] as  [String:AnyObject]).description).end()
            }
            catch {
                Log.error("Failed /authcallback redirect \(error)")
            }
            //next()
        }
        
    }
    

}
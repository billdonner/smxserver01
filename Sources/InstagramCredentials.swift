///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


//
//  InstagramCredentials.swift
//  t3
//
//  Created by william donner on 5/24/16.
//
//
import Kitura
import KituraNet
import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation

/// Instagram Authentication
///  inspired by Kitura Credentials and the google and facebook plugins
///  however, this is not a plugin and it uses NSURLSession to communicate with Instagram, not the Kitura HTTP library


public class InstagramCredentials {
    private var clientId : String
    private var clientSecret : String
    public var callbackUrl : String
    public var callbackBase : String
    public var name : String {
        return "Instagram"
    }
    
    public init (clientId: String, clientSecret : String, callbackBase : String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.callbackBase = callbackBase
        self.callbackUrl = self.callbackBase + "/authcallback?type=mobile"
    }
    
    
    /// redirect back from IG from the unwindor path
    public  func STEP_THREE (request: RouterRequest, response: RouterResponse) {
        
        //Log.error("STEP_THREE   \( request.queryParams)")
    }

    public func STEP_ONE(response: RouterResponse) {
        let cburl = self.callbackUrl + "&nonce=112332123"
        let loc = "https://api.instagram.com/oauth/authorize/?client_id=\(clientId)&redirect_uri=\(cburl)&response_type=code&scope=basic+likes+comments+relationships+follower_list"
        //Log.error("STEP_ONE redirecting to Instagram authorization \(loc)")
        // Log in
        do {
            try response.redirect( loc)
            //completion?(300)
        }
        catch {
            Log.error("Failed to redirect to Instagram login page")
        }
    }
    /// step two: receive request from instagram - has ?code paramater
    public func STEP_TWO (request: RouterRequest, response: RouterResponse,   completion:((Int) -> ())?) {

        
        func inner_two(code:String ) {
            
            let cburl = self.callbackUrl + "&nonce=112332123"
          //  Log.error("STEP_TWO starting with \(     code) just received from Instagram")
            IGOps.perform_post_request(url_to_request: "https://api.instagram.com/oauth/access_token",
                                       paramString: "client_id=\(clientId)&redirect_uri=\(cburl)&grant_type=authorization_code&client_secret=\(clientSecret)&code=\(code)",completion:
            { status, body  in
                                    if status == 200 {
                                        let jsonBody = JSON(data: body!)
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
                                                        Membership.shared.members[userid] = ["id":userid,"created":created,"last-login":nows, "named":title, "pic":pic,"access_token":token ,"smaxx-token":smtoken]
                                                    } else {
                                                        // error
                                                        Log.error("Could not find created field in mu")
                                                    }
                                                } else {
                                                    // not there make new
                                                    Membership.shared.members[userid] = ["id":userid,"created":nows,"last-login":nows, "named":title, "pic":pic,"access_token":token,"smaxx-token":smtoken ]
                                                }
                                                
                                                ////////////// VERY INEFFICIENT , REWRITES ALL RECORDS ON ANY UPDATE ///////////////////
                                                /// adjust membership table and save it to disk
                                                let dict = ["status":200, "data":Membership.shared.members] as  [String:AnyObject]
                                                /// save entire pile
                                                try  Membership.save ("_membership",dict:dict)
                                                //Log.info("saved membership state")
                                                let w = Sm.axx.workers
                                                w.make_worker_for(id:userid,token:token)
                                               // w.start(userid,request,response)
                                               // see if we can go somewhere interesting
                                                
                                                    let tk = "/unwindor?smaxx-id=\(userid)&smaxx-token=\(smtoken)&smaxx-name=\(title)&smaxx-pic=\(pic)"
                                                do {
                                              //  Log.info("STEP_TWO redirect back to client with \(tk)")
                                                try response.redirect(tk)
                                                }
                                                catch {
                                                     Log.error("Could not redirect to \(tk)")
                                                }
                                            }
                                            catch  {
                                                Log.error("Could not save membership")
                                            }
                                        }
                                        completion?(200)
                                        return
                                    } //==200
                                    else { Log.error("Bad Status From Instagram   \(status)")
                                        completion?(status)
                                        return
                                    }
            })//closure of perform_data_request
      
        }//inner_two
       
        /// authenticate starts here
        if let error = request.queryParams["error"] {
            let error_reason = request.queryParams["error_reason"]
            let error_description = request.queryParams["error_description"]
            
            Log.error("Instagram error \(error) and \(error_reason) - \(error_description)")
        } else
            if let code = request.queryParams["code"] {
                if let _ = request.queryParams["nonce"] {
               // print("got nonce \(nonce) ")
                }
                inner_two(code:code)
        }
            
    }// end of step two

}

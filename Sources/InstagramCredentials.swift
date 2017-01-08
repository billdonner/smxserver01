/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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
import LoggerAPI
import SwiftyJSON
import Foundation

/// Instagram Authentication
///  inspired by Kitura Credentials and the google and facebook plugins
///  however, this is not a plugin and it uses NSURLSession to communicate with Instagram, not the Kitura HTTP library



open class InstagramCredentials {
    fileprivate var clientId : String
    fileprivate var clientSecret : String
    open var callbackUrl : String
    open var callbackPostUrl : String
    open var callbackBase : String
    open var name : String {
        return "Instagram"
    }
    
    public init (clientId: String, clientSecret : String, callbackBase : String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.callbackBase = callbackBase
        self.callbackUrl = self.callbackBase + "/authcallback?type=mobile"
        self.callbackPostUrl = self.callbackBase + "/postcallback"
    }
    /// make subscription
    open func make_subscription (_ myVerifyToken:String) {
        //print("make_subscription for \(myVerifyToken) callback is \(self.callbackPostUrl) ")
        NetClientOps.perform_post_request (
            schema:"https", host:"spi.instagram.com", port: 443, path:"v1/subscriptions/",
            paramString: "client_id=\(clientId)&client_secret=\(clientSecret)" +
                                    "&object=user&aspect=media&verify_token=\(myVerifyToken)&callback_url=\(self.callbackPostUrl)",completion:
            { status, body  in
                guard status == 200 else {
                    Log.error ("INSTAGRAM SAYS subscription \(myVerifyToken) was unsuccessful \(status)")
                    return
                }
                let jsonBody = JSON(data: body!)
                let meta = jsonBody["meta"]["code"].intValue
                guard meta == 200 else {
                     Log.error ("INSTAGRAM SAYS subscription \(myVerifyToken) was unsuccessful meta \(meta)")
                    return
                }
                Log.info("* INSTAGRAM SAYS  subscription \(myVerifyToken) successful")
        })// closure
    }
    

    open func handle_post_callback (_ request: RouterRequest, response: RouterResponse) {
        /// parse out the callback we are getting back, its json
        var userid = "notfound"
        let t = "\(request.body)" // stringify this HORRIBLE
        let a = t.components(separatedBy:"\"object_id\" = ")
        if a.count > 1 {
            let b = a[1].components(separatedBy:";")
            if b.count  > 1 {
                userid = b[0]
            }
        }
        Log.info("---->>>>  post callback for user  \(userid)")
        // member must have access token for instagram api access
       MembersCache.getTokenFromID(id: userid) { token in
        self.rest_make_worker_for(id: userid, token: token!) {_ in 
            print("rest make worker for \(userid) \(token!) ")
        }
        }
    }
    
    /// the get is called in the middle of the post verification
    open func handle_get_callback (_ myVerifyToken:String ,request: RouterRequest, response: RouterResponse) {
        
        /// strip out the challenge parameter and return with this only
        let ps = request.originalURL.components(separatedBy: "?")
        // make dictionary
        var d: [String:String] = [:]
        if ps.count >= 2 {
            let pairs = ps[1].components(separatedBy: "&")
            for pair in pairs {
                let p = pair.components(separatedBy: "=")
                if p.count >= 2 {
                    d[p[0]] = p[1]
                }
            }
            if d["hub.mode"] ==  "subscribe" {
                if d["hub.verify_token"] == myVerifyToken {
                    if  let reply = d["hub.challenge"] {
                        let r = response.status(HTTPStatusCode.OK)
                        do {
                            let _ =   try r.send(reply).end()
                        }
                        catch {
                            Log.error("could not send verify response to Instagram")
                        }
                        Log.info("Post register GET callback supplies token \(reply)")
                        return
                    }
                }
            }
        }
    }// get  callbac
    
    /// OAuth2 steps with Instagram
    
    open func STEP_ONE(_ response: RouterResponse) {
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
    open func STEP_TWO (_ request: RouterRequest, response: RouterResponse,   completion:((Int) -> ())?) {
        func inner_two(_ code:String ) {
            let cburl = self.callbackUrl + "&nonce=112332123"
            //  Log.error("STEP_TWO starting with \(     code) just received from Instagram")
            NetClientOps.perform_post_request(schema:"https", host:"api.instagram.com", port: 443,path:"/oauth/access_token",
            paramString: "?client_id=\(clientId)&redirect_uri=\(cburl)&grant_type=authorization_code&client_secret=\(clientSecret)&code=\(code)")
            { status, body  in
                if status == 200 ,
                    let body = body {
                     self.processInstagramResponse (body: body) { xyz in
                  if  let userid = xyz?["id"] as? String,
                    let smtoken = xyz?["smaxx-token"] as? String,
                    let token = xyz?["access_token"] as? String,
                    let title = xyz?["named"] as? String,
                    let pic  = xyz?["pic"] as? String {
                    
                    // w.start(userid,request,response)
                    // see if we can go somewhere interesting
                    
                    let tk = "/unwindor?smaxx-id=\(userid)&smaxx-token=\(smtoken)&smaxx-name=\(title)&smaxx-pic=\(pic)"
                    do {
                        //  Log.info("STEP_TWO redirect back to client with \(tk)")
                        try response.redirect(tk)  }
                    catch {
                        Log.error("Could not redirect to \(tk)")
                    }
                        }
                    completion?(200)
                    }
                }//==200
                else {
                    Log.error("Bad Status From Instagram   \(status)")
                    completion?(status)
                    return
                }
            }//closure of perform_data_request
        }//inner_two
        
        /// authenticate starts here
        if let error = request.queryParameters["error"] {
            let error_reason = request.queryParameters["error_reason"]
            let error_description = request.queryParameters["error_description"]
            Log.error("Instagram error \(error) and \(error_reason) - \(error_description)")
        } else
            if let code = request.queryParameters["code"] {
                if let _ = request.queryParameters["nonce"] {
                    // print("got nonce \(nonce) ")
                }
                inner_two(code)
        }
    }// end of step two
    
    /// redirect back from IG from the unwindor path
    open  func STEP_THREE (_ request: RouterRequest, response: RouterResponse) {
        //Log.error("STEP_THREE   \( request.queryParams)")
    }
    
    private func rest_rewrite_member_info(ble:AnyObject,completion:@escaping (Int)->())  {
        NetClientOps.perform_post_request(schema:"https",
                                          host:"api.ipify.org",port:443,
                                          path:"?format=json",paramString: "")
        { status,body  in
            if status == 200 {
                let jsonBody = JSON(data: body!)
                if let _ = jsonBody["ip"].string {
                    completion(200 )
                }
                else {
                    fatalError("no ip address for this Kitura Server instance, status is \(status)")
                }
            }
        }
    }
    
   private func rest_make_worker_for(id: String, token: String,completion:@escaping (Int)->()) {
        //TODO: make this a REST call to other server
        //        workersMainServer?.make_worker_for(id:id,token:token)
        //        completion()
        
        NetClientOps.perform_post_request(schema:"https",
                                          host:"api.ipify.org",port:443,
                                          path:"?format=json",paramString: "")
        { status,body  in
            if status == 200 {
                let jsonBody = JSON(data: body!)
                if let ip = jsonBody["ip"].string {
                    completion(200 )
                }
                else {
                    fatalError("no ip address for this Kitura Server instance, status is \(status)")
                }
            }
            
        }
    }
    
    
   private  func processInstagramResponse(body:Data,completion:@escaping (AnyObject?)->())   {
    //var ret:AnyObject? = nil
        //var ret = ("","","","","")
        let jsonBody = JSON(data: body)
        if let token = jsonBody["access_token"].string,
            let userid = jsonBody["user"]["id"].string,
            let pic = jsonBody["user"]["profile_picture"].string,
            let title = jsonBody["user"]["username"].string {
            //   Log.info("STEP_TWO Instagram sent back \(token) and \(title)")
            /// stash these, creating new object if needed
       
                let smtoken = "\((userid + token).hashValue)"
                let nows = "\(NSDate())" // time now as string
            let   createds = nows
            
            IGOps.setToken(token, id: userid) // poke this in here
            
            
            let ble =  ["id":userid    ,  "created":createds   ,  "last-login":nows   ,
                                                                                "named":title   ,
                                                                                "pic":pic    ,
                                                                                "access_token":token    ,
                                                                                "smaxx-token":smtoken    ] as AnyObject
           
          rest_rewrite_member_info(ble: ble) { status in
                if status == 200 {
                    completion(ble)
                }
                
            }
        }
    }
}


/// general rest calls between servers
extension InstagramCredentials {


}

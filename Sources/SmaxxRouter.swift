///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


///
/// Instagram Authentication
///  inspired by Kitura Credentials and the google and facebook plugins
///  however, this is not a plugin and it uses NSURLSession to communicate with Instagram, not the Kitura HTTP library

import Kitura
import KituraNet
//import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation

#if os(Linux)
    public typealias OptionValue = Any
#else
    public typealias OptionValue = AnyObject
#endif

struct AppResponses {
/// log error and reply with bad status to user
static func rejectduetobadrequest(_ response:RouterResponse,status:Int,mess:String?=nil) {
    do {
        let rqst = (mess != nil) ?   " \(status) -- \(mess!)" : "\(status)"
        Log.error("badrequest \(rqst)")
        let item:JSONDictionary = mess != nil ? ["status":status as AnyObject,"description":mess! as AnyObject] as JSONDictionary :  ["status":status as AnyObject] as JSONDictionary
        try sendbadresponse(response, item)
        
    }
    catch {
        Log.error("Could not send rejectduetobadrequest ")
    }
}
static func acceptgoodrequest(_ response:RouterResponse, _ code: SMaxxResponseCode ) { // item:JSONDictionary) {
    do {
        let  item =   ["status":code as AnyObject]
        try sendgooresponse(response,item )
        
        //Log.error("Did send acceptgoodrequest")
        
    }
    catch {
        Log.error("Could not send acceptgoodrequest")
    }
}
static func sendgooresponse(_ response:RouterResponse, _ item:JSONDictionary  ) throws {
    // item:JSONDictionary) {
    do {
        
        let r = response.status(HTTPStatusCode.OK)
        let _ =   try r.send(JSON(item).description).end()
        //Log.error("Did send acceptgoodrequest")
    }
    catch {
        Log.error("Could not send acceptgoodrequest")
    }
}
static func sendbadresponse(_ response:RouterResponse, _ item:JSONDictionary  ) throws { // item:JSONDictionary) {
    do {
        
        let r = response.status(HTTPStatusCode.badRequest)
        let _ =   try r.send(JSON(item).description).end()
    }
    catch {
        Log.error("Could not send sendbadresponse")
    }
}

}

///
// MARK:- Custom middleware that allows Cross Origin HTTP requests
// This will allow 3rd party servers to communicate with this server
///

 class AllRemoteOriginMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        response.headers["Access-Control-Allow-Origin"] = "*"
        next()
    }
}

///
// MARK:-  RouterMiddleware can be used for intercepting requests and handling custom behavior
///

class BasicAuthMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        if let authString = request.headers["Authorization"] {
            Log.info("Authorization: \(authString)")
            
            // Check authorization string in database to approve the request if fail
            response.error = NSError(domain: "AuthFailure", code: 1, userInfo: [:])
        }
        
        next()
    }
}

///
/// MARK:-   Sets up all the routes according to flavor modes
///



open class SMaxxRouter {
    
          class func setupRoutesPlain(_ router: Router) {
        //
        // the server can run in several different flavours as determined by the routes that are setup
        //  the flavors are passed in from the original kitura startup command line
        
            
            print("*** setting up Plain Pages and IG Callbacks ***")
        
        router.all(middleware: BasicAuthMiddleware())
        router.all("/*", middleware: BodyParser())
        router.all("/*", middleware: AllRemoteOriginMiddleware())
            let staticFileServer = StaticFileServer(path:  ModelData.staticPath())
            //, options: [:], customResponseHeadersSetter: nil)
            
            //StaticFileServer(path: ModelData.staticPath(), options: nil)
        router.all("/_/", middleware: staticFileServer)
        
        ///
        // MARK:-  Handler Options
        ///
        router.options("/*") {
            _, response, next in
            response.headers["Access-Control-Allow-Headers"] =  "accept, content-type"
            response.headers["Access-Control-Allow-Methods"] = "GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH"
            response.status(HTTPStatusCode.OK)
            next()
        }

            
//            router.get("/authcallback") { request, response, next in
//                response.headers["Content-Type"] = "text/html; charset=utf-8"
//                
//                // Log.error("STEP_ONE /login/instagram/callback will authenticate ")
//                // there should be a code here l so this will redirect as per step one
//                Sm.axx.ci.authenticate (request: request, response: response) { status in
//                    guard status == 200  else { Log.error("Back from callback authenticate bad status \(status) "); return }
//                    do {
//                        try response.redirect("/")
//                    }
//                    catch {
//                        Log.error("Failed /authcallback redirect \(error)")
//                    }
//                }
//                next()
//                
//            }

            ///
            // MARK:- Show Status
            ///
            router.get("/status") {
                request, response, next in
                HomePage.buildStatus(request,response)
                next()
            }
            router.get("/log") {
                request, response, next in
                let qp = request.queryParameters
                Log.info("LOGLINE \(qp)")
                   response.status(HTTPStatusCode.OK)
                next()
            }
             ///
            // MARK: Callback GETs and POSTs from IG come here
             ///
            router.post("/postcallback") {
                request, response, next in
                Sm.axx.ci.handle_post_callback(request,response: response)
                next()
            }
            router.get("/postcallback") {
                request, response, next in
                 Sm.axx.ci.handle_get_callback(Sm.axx.verificationToken(),request: request,response: response)
                next()
            }
            
        ///
        // MARK:- Show a FrontPage
        ///
        router.get("/fp") {
            request, response, next in
            HomePage.buildFrontPage(request,response)
            next()
        }
        
        ///
        // MARK:- Show HomePage
        ///
        
        
        router.get("/") {
            request, response, next in
            HomePage.buildHomePage(request,response)
            next()
        }
        
        
        ///
        // MARK:- Handles any errors that get set
        ///
        router.error { request, response, next in
            response.headers["Content-Type"] = "text/plain; charset=utf-8"
            do {
                let errorDescription: String
                if let error = response.error {
                    errorDescription = "\(error)"
                } else {
                    errorDescription = "Unknown error"
                }
                try response.send("Caught the error: \(errorDescription)").end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
            next()
        }
        
        ///
        // MARK:- A custom Not found handler
        ///
        // A custom Not found handler
        router.all { request, response, next in
            if  response.statusCode == .notFound  {
                // Remove this wrapping if statement, if you want to handle requests to / as well
                //if  request.originalUrl != "/"  &&  request.originalUrl != ""  {
                
                do {
                    try response.send("Route \( request.originalURL) not found in Smaxx Router \(Sm.axx.ci.callbackBase)").end()
                }
                catch {
                    Log.error("Failed to send response \(error)")
                }
                //}
            }
            next()
        }
        
        
    }// end of setupRoutes
    
} // end of SmaxxRouter



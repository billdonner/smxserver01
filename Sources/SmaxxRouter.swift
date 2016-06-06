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
import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation

#if os(Linux)
    public typealias OptionValue = Any
#else
    public typealias OptionValue = AnyObject
#endif

///
// MARK:- Custom middleware that allows Cross Origin HTTP requests
// This will allow 3rd party servers to communicate with this server
///

class AllRemoteOriginMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        response.headers["Access-Control-Allow-Origin"] = "*"
        next()
    }
}

///
// MARK:-  RouterMiddleware can be used for intercepting requests and handling custom behavior
///
class BasicAuthMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
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



public class SMaxxRouter {
          class func setupRoutes(router: Router) {
        //
        // the server can run in several different flavours as determined by the routes that are setup
        //  the flavors are passed in from the original kitura startup command line
        
        let flavors = Sm.axx.modes
        
        router.all(middleware: BasicAuthMiddleware())
        router.all("/*", middleware: BodyParser())
        router.all("/*", middleware: AllRemoteOriginMiddleware())
        let staticFileServer = StaticFileServer(path: ModelData.staticPath(), options: nil)
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
        
        if flavors.contains("reports") {
            SMaxxRouter.setupRoutesForReports(router: router )
        }
        if flavors.contains("membership") {
            SMaxxRouter.setupRoutesForMembership(router: router )
        }
        if flavors.contains("workers") {
            SMaxxRouter.setupRoutesForWorkers(router: router )
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
                    try response.send("Route \( request.originalUrl) not found in Smaxx Router \(Sm.axx.ci.callbackBase)").end()
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


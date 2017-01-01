///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
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

class HomePageMainServer:MainServer {
   func jsonStatus() -> JSONDictionary {
        return [:]
    }

    var port:Int16 = 0
    
    init(port:Int16) {
        self.port = port
    }
    
    
    func mainPort() -> Int16 {
        return self.port
    }
    static func staticPath()->String {
        return documentsPath() + "/_smaxx-static/"  + Sm.axx.servertag
    }
    static func membershipPath()->String {
        return documentsPath() + "/_membership/"
    }
    fileprivate static func documentsPath()->String {
        
        
        let docurl =  FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
        let docDir = docurl.path
        return docDir
    }
    // all the action is in the router extension
    
} // end of HomePageMainServer

extension Router {
    
    func setupRoutesPlain(mainServer:MainServer) {

        // must support MainServer protocol
        
        let port = mainServer.mainPort()
        print("*** setting up Plain Pages and IG Callbacks  on port \(port) ***")
        
        self.all(middleware: BasicAuthMiddleware())
        self.all("/*", middleware: BodyParser())
        self.all("/*", middleware: AllRemoteOriginMiddleware())
        let staticFileServer = StaticFileServer(path:  HomePageMainServer.staticPath())
        //, options: [:], customResponseHeadersSetter: nil)
        
        //StaticFileServer(path: ModelData.staticPath(), options: nil)
        self.all("/_/", middleware: staticFileServer)
        
        ///
        // MARK:-  Handler Options
        ///
        self.options("/*") {
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
        self.get("/status") {
            request, response, next in
            HomePageMainServer.buildStatus(request,response)
            next()
        }
        self.get("/log") {
            request, response, next in
            let qp = request.queryParameters
            Log.info("LOGLINE \(qp)")
            response.status(HTTPStatusCode.OK)
            next()
        }
        ///
        // MARK: Callback GETs and POSTs from IG come here
        ///
        self.post("/postcallback") {
            request, response, next in
            Sm.axx.ci.handle_post_callback(request,response: response)
            next()
        }
        self.get("/postcallback") {
            request, response, next in
            Sm.axx.ci.handle_get_callback(Sm.axx.verificationToken(),request: request,response: response)
            next()
        }
        
        ///
        // MARK:- Show a FrontPage
        ///
        self.get("/fp") {
            request, response, next in
            HomePageMainServer.buildFrontPage(request,response)
            next()
        }
        
        ///
        // MARK:- Show HomePage
        ///
        
        
        self.get("/") {
            request, response, next in
            HomePageMainServer.buildHomePage(request,response)
            next()
        }
        
        
        ///
        // MARK:- Handles any errors that get set
        ///
        self.error { request, response, next in
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
        self.all { request, response, next in
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

}

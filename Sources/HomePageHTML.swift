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
        
        defer { next() }
        response.headers["Access-Control-Allow-Origin"] = "*"
    
    }
}

///
// MARK:-  RouterMiddleware can be used for intercepting requests and handling custom behavior
///

class BasicAuthMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        
        defer { next() }
        if let authString = request.headers["Authorization"] {
            Log.info("Authorization: \(authString)")
            
            // Check authorization string in database to approve the request if fail
            response.error = NSError(domain: "AuthFailure", code: 1, userInfo: [:])
        }
    }
}



///
/// MARK:-   Sets up all the routes according to flavor modes
///
var homePageMainServer:HomePageMainServer!

class HomePageMainServer:MainServer {
    
    override func jsonStatus() -> JSONDictionary {
        return [:]
    }
    var servertag:String = ""
    var port:Int16 = 0
    var smaxx:Smaxx
    init(port:Int16,servertag:String,smaxx:Smaxx) {
        self.port = port
        self.servertag = servertag
        self.smaxx = smaxx
    }
    override func mainPort() -> Int16 {
        return self.port
    }
    
} // end of HomePageMainServer

extension Router {
    
    func setupRoutesPlain(mainServer:HomePageMainServer,smaxx:Smaxx) {
        
        // must support MainServer protocol
        
        let port = mainServer.mainPort()
        print("*** setting up Plain Pages and IG Callbacks  on port \(port) ***")
        
        self.all(middleware: BasicAuthMiddleware())
        self.all("/*", middleware: BodyParser())
        self.all("/*", middleware: AllRemoteOriginMiddleware())
        let staticFileServer = StaticFileServer(path:  membersMainServer.store.staticPath())
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
        
        
        ///
        // MARK:- Show Status
        ///
        self.get("/status") {
            request, response, next in
            homePageMainServer.buildStatus(request,response)
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
            instagramCredentials.handle_post_callback(request,response: response)
            next()
        }
        self.get("/postcallback") {
            request, response, next in
            instagramCredentials.handle_get_callback(smaxx.verificationToken,request: request,response: response)
            next()
        }
        
        ///
        // MARK:- Show a FrontPage
        ///
        self.get("/fp") {
            request, response, next in
              homePageMainServer.buildFrontPage(request,response)
            next()
        }
        
        ///
        // MARK:- Show HomePage
        ///
        
        
        self.get("/") {
            request, response, next in
             homePageMainServer.buildHomePage(request,response)
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
                    try response.send("Route \( request.originalURL) not found in Smaxx Router \(instagramCredentials.callbackBase)").end()
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
// MARK:-  The homepage is shown in response to / or /?id=12345
///
extension HomePageMainServer{
    
    fileprivate  func standard_footer()->String {
        let s = smaxx.modes.joined(separator: "+")
        return    "<footer><caption>\(smaxx.ip):\(smaxx.portno)-\(smaxx.servertag)-\(s) \(smaxx.packagename) version:-\(smaxx.version) </caption>" +
            "<p>built on <a href = 'https://swift.org'>Swift 3</a>, <a href = 'https://github.com/IBM-Swift/Kitura'>Kitura Web Server</a>, <a href = 'http://www.noip.com'>no-IP.com</a>, <a href = 'https://runstatus.com'>runstatus.com</a>, <a href = 'https://centralops.net'>centralops.net</a></caption> and <a href = 'https://centralops.net'>OS X 10.11 El Capitan</a></caption>" + "<br/><caption>this page produced at \(Date()) <a href='/fp'>Front Panel</a> <a href = '/status'>status</a></caption></footer></body> </html>"
    }
    
    fileprivate   func standard_header()->String {
        return  "<!DOCTYPE html><head>" +
            " <meta charset='UTF-8' />" +
            " <title>\(smaxx.title) App Service </title>" +
            " <meta name='HandheldFriendly' content='True' />" +
            " <meta name='MobileOptimized' content='320' />" +
            " <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0' />" +
            " <style> body {font-family: ‘Lucida Console’, Monaco, monospace;} " +
            "a {text-decoration:none; color:gray} a:visited {color:gray}" +
        "footer {font-size:.6em} </style></head><body>"
    }
    
     func frontpanel1(_ idstr:String,serverip:String)->String {
        return standard_header() +
            " <h1>\(smaxx.title) Reports for \(idstr)</h1>" +
            "<p><a href = '/fp'>back to front panel</a></p>" +
            "<h3>reports testbed</h3>" +
            "<p><a href = '/reports/\(idstr)/top-posts'>top-posts</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/top-comments'>top-comments</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/when-posting'>when-posting</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/when-topost'>when-topost</a> - json report </p>" +
            
            "<p><a href = '/reports/\(idstr)/ghost-followers'>ghost-followers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/unrequited-followers'>unrequited-followers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/booster-followers'>booster-followers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/secret-admirers'>secret-admirers</a> - json report </p>" +
            
            "<p><a href = '/reports/\(idstr)/most-popular-tags'>most-popular-tags</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/most-popular-taggedusers'>most-popular-taggedusers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/most-popular-filters'>most-popular-filters</a> - json report </p>"
            +
            
            "<p><a href = '/reports/\(idstr)/top-likers'>top-likers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/top-commenters'>top-commenters</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/speechless-likers'>speechless-likers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/heartless-commenters'>heartless-commenters</a> - json report </p>" +
            
            "<p><a href = '/reports/\(idstr)/all-followers'>all-followers</a> - json report </p>" +
            "<p><a href = '/reports/\(idstr)/all-followings'>all-followings</a> - json report </p>" +
            
            standard_footer()
        
    }
     func frontpanel2(_ serverip:String )->String {
        return standard_header() +
            " <h1>\(smaxx.title) Membership Administration</h1>" +
            
            "<p><a href = '/fp'>back to front panel</a></p>" +
            "<h3>membership testbed</h3>" +
            "<p><a href = '/membership'>membership</a> - list </p>" +
            
            "<p><a href = '/membership/1601909741'>is bill a good id?</a> </p>" +
            "<p><a href = '/membership/275404302'>is james a good id?</a> </p>" +
            "<p><a href = '/membership/273260628'>is anon a good id?</a> </p>" +
            
            "<p><form action='/membership?id=1601909741&title=bill' method='post' >Add Member bill<input type='submit' value='post' /> - potential duplicate</form></p>" +
            
            "<p><form action='/membership?id=275404302&title=james' method='post' >Add Member james<input type='submit' value='post' /> - potential duplicate</form></p>" +
            
            "<p><form action='/membership?id=273260628&title=anon)' method='post' >Add Member anon <input type='submit' value='post' /> - potential duplicate</form></p>" +
            
            standard_footer()
    }
     func frontpanel (_ serverip:String )->String {
        
        let flavors = smaxx.modes
        let reps =   ""
        let mems = flavors.contains("membership") ?
            
            "<h3>membership testbed</h3>" +
                "<caption>the max number of users in an Instagram beta trial appears to be nine(9)!</caption>" +
                
                "<p><a href = '/membership'>membership</a> - list </p>" +
            "<p><a href = '/?admin=1'>administration</a> - experimental</p>" : ""
        
        
        let wks = flavors.contains("workers") ?
            "<h3>workers testbed</h3>" +
                "<caption>this is completely ala carte</caption>" +
                "<p><a href = '/workers/start/1601909741'>start worker bill</a> - in background </p>" +
                "<p><a href = '/workers/stop/1601909741'>stop worker bill</a> - cold</p>" +
                
                "<p><a href = '/workers/start/275404302'>start worker james</a> - in background </p>" +
                "<p><a href = '/workers/stop/275404302'>stop worker james</a> - cold</p>" +
                
                "<p><a href = '/workers/start/273260628'>start worker anon</a> - in background </p>" +
            "<p><a href = '/workers/stop/273260628'>stop worker anon</a> - cold</p>"  :"(no workers on this server)"
        
        
        let headline = "<h1>\(smaxx.title) Front Panel<h1><h2>App Service \(smaxx.version)</h1>"
        
        let monitor =
            "<h3>monitor live networks</h3>" +
                "<caption>you can copy these links to bookmarks or elsewhere to check status when this page is unavailable</caption>" +
                "<p><a href = '/status'>root</a> - json </p>" +
                "<p><a href = 'https://socialmaxxstats.runstat.us'>operations</a> - status </p>" +
        "<p><a href = 'https://centralops.net/co/Ping.aspx?addr=\(instagramCredentials.callbackBase)&count=5&timeout=1000&size=32&ttl=255&ip-version=auto'>ping</a> - status </p>"
        
        
        return standard_header() + headline + mems + wks + reps + monitor +  standard_footer()
        
    }
     func homepage(_ serverip:String )->String {
        var s:String
        let url = membersMainServer.store.staticPath() + "/body.html"
        do {
            s = try String(contentsOfFile:  url )
        }
        catch {
            s = "?no body found in \(url)?"
        }
        return standard_header() +
            "<h1>\(smaxx.title)</h1>" + s  +
            standard_footer()
    }
    
    
        func buildStatus(_ request:RouterRequest,_ response:RouterResponse) {
        
        let r = smaxx.status()
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        do {
            try response.status(HTTPStatusCode.OK).send(JSON(r).description).end()
        }
        catch {
            Log.error("Failed to send response \(error)")
        }
    }
    
    /// show homepage
       func buildFrontPage(_ request:RouterRequest,_ response:RouterResponse) {
        var buf = ""
        let serverip = smaxx.ip
        if  let id  = request.queryParameters["id"] {
            buf = self.frontpanel1(id,serverip:serverip)
        }
        else      if  let _  = request.queryParameters["admin"] {
            buf = self.frontpanel2(serverip)
        }
        else {
            buf = self.frontpanel(serverip)
        }
        response.headers["Content-Type"] =  "text/html; charset=utf-8"
        do {
            try response.status(HTTPStatusCode.OK).send(buf).end()
        }
        catch {
            Log.error("Failed to send response \(error)")
        }
    }
    
        func buildHomePage(_ request:RouterRequest,_ response:RouterResponse) {
        
        let serverip = smaxx.ip
        let buf = self.homepage(serverip)
        response.headers["Content-Type"] =  "text/html; charset=utf-8"
        do {
            try response.status(HTTPStatusCode.OK).send(buf).end()
        }
        catch {
            Log.error("Failed to send response \(error)")
        }
    }
}



//            router.get("/authcallback") { request, response, next in
//                response.headers["Content-Type"] = "text/html; charset=utf-8"
//
//                // Log.error("STEP_ONE /login/instagram/callback will authenticate ")
//                // there should be a code here l so this will redirect as per step one
//                smaxx.ci.authenticate (request: request, response: response) { status in
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

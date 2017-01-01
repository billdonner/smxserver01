///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

/** hacked by wld
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
import Kitura
import KituraNet
//import KituraSys
import HeliumLogger
import SwiftyJSON
import LoggerAPI
import Foundation
//import CFEnvironment
/**
 Because bridging is not complete in Linux, we must use Any objects for dictionaries
 instead of AnyObject. The main branch SwiftyJSON takes as input AnyObject, however
 our patched version for Linux accepts Any.
 */
//#if os(OSX)
//    typealias JSONDictionary = [String: AnyObject]
//#else
    typealias JSONDictionary = [String: Any]
//#endif

protocol MainServer {
    func mainPort() -> Int16
    func jsonStatus() -> JSONDictionary
    
}
func ciFor(_ tag:String) -> InstagramCredentials {
    
    switch tag {
        
    case "PROD":        return InstagramCredentials(
        clientId: "09bff63ecf0f4e4c866041a455c7ff35",
        clientSecret: "ce190ab2737f46628a33f3484c4f3a17",
        callbackBase: "http://socialmaxx.net") // +/membership /instagram/callback
        
    // same credentials for both dev and local tags
    case "DEV":    return InstagramCredentials(
        clientId: "d7020b2caaf34e13a1ca4bdf1504e4dc",
        clientSecret: "0c320f295a3c45af9ff35c00bb341088",
        callbackBase: "http://socialmaxx.sytes.net")// +/membership /instagram/callback
        
    // same credentials for both dev and local tags
    default:    return InstagramCredentials(
        clientId: "XXXd7020b2caaf34e13a1ca4bdf1504e4dc",
        clientSecret: "0c320f295a3c45af9ff35c00bb341088",
        callbackBase: "http://XXXsocialmaxx.sytes.net")// +/membership /instagram/callback
        
    }
}


struct AppResponses {
    
    static  func missingID(_ response:RouterResponse) {
        response.status(HTTPStatusCode.badRequest)
        Log.error("Request does not contain ID")
        return
    }
    
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
class Sm {
    
    class var axx: Sm {
        struct Axx { static let smg = Sm() }
        return Axx.smg
    }
    let started = "\(Date())"
    let baseURLString = "https://api.instagram.com"
    var packagename = "t5"
    var servertag = "-unassigned-"
    var ci : InstagramCredentials!
    var workers : WorkersMainServer!
    var portno:Int16  = 8090
    var version = "v0.465"
    var modes = ["reports","membership","workers"]
    var title = "SocialMaxx@UnspecifiedSite"
    var ip = "127.0.0.1"
    var igApiCallCount = 0
    var operationQueue: OperationQueue! // just one queue for now
    var session: URLSession = URLSession(configuration: URLSessionConfiguration.default) // just one session
    
    func verificationToken () -> String {
        let x = ip.components(separatedBy: ".").joined(separator: "") // strip dots
        return "\(servertag)\(portno)\(x)"
    }
    
    func status () -> JSONDictionary  {
        
        let a : JSONDictionary  = [ "router-for":"webpages+auth"  ,
                                    "software-verision":version   ,
                                    "instagram-api-url":baseURLString   ,
                                    "smaxx-server-ip":ip   ,
                                    "packagename":packagename   ,
                                    "servertag":servertag   ,
                                    "portno":portno   ,
                                    // "modes":modes,
            "title":title   ,
            "apicalls":igApiCallCount   ,
            "started":started   ,
            
            ]
        return a
    }
    
    init () {
        operationQueue =  OperationQueue()
        operationQueue.name = "InstagramOperationsQueue"   /// does not work with .main()
        operationQueue.maxConcurrentOperationCount = 3
        
    }
    
    func setServer(_ servertag:String  ) {
    }
}
func startup_banner() {
    
    
    /// get plist variables, server tag must be known
    

    //let apiurl = "https://api.ipify.org?format=json"
    //NetClientOps.perform_get_request(apiurl)
    
    NetClientOps.perform_get_request(schema:"https",
                                     host:"api.ipify.org",port:443,
                                     path:"?format=json")
    { status,body  in
        if status == 200 {
            let jsonBody = JSON(data: body!)
            let ip = jsonBody["ip"].string
            Sm.axx.ip = ip!
            
            /// once we have an ip address we can
            /// setup subscription
            
            Sm.axx.ci.make_subscription(Sm.axx.verificationToken())
            
            // let t =  dict?["version"] //?? "vv??"
            
            Log.info("*****************  \(Sm.axx.title)(\(Sm.axx.servertag)) \(Sm.axx.version)  **********************")
            Log.info("** \(NSDate()) on \(Sm.axx.packagename) \(Sm.axx.ip):\( Sm.axx.portno) serving \( Sm.axx.modes.joined(separator: ","))")
            Log.info("*****************  \(Sm.axx.title)(\(Sm.axx.servertag)) \(Sm.axx.version) **********************")
        }
        else {
            fatalError("no ip address for this Kitura Server instance, status is \(status)")
        }
    }
}





//    //let apiurl = "https://api.ipify.org?format=json"
//    NetClientOps.perform_get_request(schema:"https",host:"api.ipify.org",port:443,path:"?format=json")


/// command line arguments are xxx portno modes servertag title

let arguments = ProcessInfo.processInfo.arguments
guard arguments.count >= 5  else {
    
    // no args, use some reasonable defaults
    print("  -- usage for all SocialMaxx Servers\n        .build/debug/\(Sm.axx.packagename) servertag portno modes title")
    print("          servertag = one of prod or dev ; selects IG App Credentials")
    print("          portno = choose any for this Kitura Server instance")
    print("          modes = one or more of reports,membership,workers")
    print("          title = a banner for Front Panel pages")
    
    print("\n  -- eg \n")
    print("       .build/debug/\(Sm.axx.packagename)  DEV 8090 reports,membership,workers socialmaxx.sytes.net \n")
    print("       .build/debug/\(Sm.axx.packagename)  PROD 8094 reports,membership,workers socialmaxx.net  \n")
    exit(0)
    
}

Sm.axx.servertag =  arguments[1]
Sm.axx.ci = ciFor(arguments[1])
Sm.axx.portno  =  Int16(arguments[2]) ?? 8090
Sm.axx.modes =  arguments[3].components(separatedBy: ",")
Sm.axx.title =  arguments[4]


///
/// Set up a simple Logger
///

Log.logger = HeliumLogger()


/// start 1-4 servers based on the flavor modes passed on the startup command line
///   - at this time the servers are started on sequential ports

///
/// The Kitura router
///

///
/// Setup routes - according to global modes setup from command line
///

let flavors = Sm.axx.modes
var httpServerPort = Sm.axx.portno+1 // leave one for main server

if flavors.contains("reports") {
    let rserver = ReportMakerMainServer(port:httpServerPort)
    let rrouter = Router()
    rrouter.setupRoutesForReports(mainServer:rserver)
    let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: rrouter)
    
    print("reports \(rrouter) starting on port \(httpServerPort)")
    
    srv.started { [unowned rrouter] in
    }
    
    httpServerPort += 1
}
if flavors.contains("membership") {
    //
    
    let rserver = MembersMainServer(port:httpServerPort)
    let mrouter = Router()
    mrouter.setupRoutesForMembership(mainServer:rserver)
    let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: mrouter)
    
    print("membership \(mrouter) starting on port \(httpServerPort)")
    
    srv.started { [unowned mrouter] in
    }
    
    httpServerPort += 1
}
if flavors.contains("workers") {
    //let workers = Sm.axx.workers
    
   let  workers = WorkersMainServer(port:httpServerPort)
    let wrouter = Router()
    wrouter.setupRoutesForWorkers(mainServer:workers)
    let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: wrouter)
    
    print("workers \(wrouter) starting on port \(httpServerPort)")
    
    srv.started { [unowned wrouter] in
    }
    
    httpServerPort += 1
}
/// this gets started unconditionally


let rserver = HomePageMainServer(port:httpServerPort)
let mainplainrouter = Router()
mainplainrouter.setupRoutesPlain(mainServer:rserver) 

let srv = Kitura.addHTTPServer(onPort: Int(Sm.axx.portno), with: mainplainrouter)

print("main \(mainplainrouter) starting on port \(Sm.axx.portno)")

srv.started { [unowned mainplainrouter] in
    /// put an informative banner right into the log
    startup_banner()
}

/// this gets Kitura to start processing requests, and the started callbacks above get called
Kitura.run()

/// deliberately but strangely, this runs off the bottom

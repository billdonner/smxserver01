///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
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
import KituraSys
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
#if os(OSX)
    typealias JSONDictionary = [String: AnyObject]
#else
    typealias JSONDictionary = [String: Any]
#endif

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
class Sm {
    class var axx: Sm {
        struct Axx { static let smg = Sm() }
        return Axx.smg
    }
    let started = "\(NSDate())"
    let baseURLString = "https://api.instagram.com"
    var packagename = "t5"
    var servertag = "-unassigned-"
    var ci : InstagramCredentials!
    var workers = Workers()
    var portno = 8090
    var version = "v1"
    var modes = ["reports","membership","workers"]
    var title = "SocialMaxx@UnspecifiedSite"
    var ip = "127.0.0.1"
    var igApiCallCount = 0
    var operationQueue: NSOperationQueue! // just one queue for now
    var session: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.default()) // just one session
    
    func verificationToken () -> String {
        let x = ip.components(separatedBy: ".").joined(separator: "") // strip dots
      return "\(servertag)\(portno)\(x)"
    }
    
    func status () -> JSONDictionary  {
        
        let a : JSONDictionary  = [ "software-verision":version,
                  "instagram-api-url":baseURLString,
                  "smaxx-server-ip":ip,
                                 "packagename":packagename,
                                 "servertag":servertag,
                                 "portno":portno,
                                // "modes":modes,
                                 "title":title,
                                 "apicalls":igApiCallCount,
                                 "started":started,
                                
                                 ]
        return a
    }
    
    init () {
        operationQueue =  NSOperationQueue()
        operationQueue.name = "InstagramOperationsQueue"   /// does not work with .main()
        operationQueue.maxConcurrentOperationCount = 3
    
    }
    
    func setServer(servertag:String  ) {
        Sm.axx.servertag =  servertag
        Sm.axx.ci = ciFor(servertag) 
    }
}
func startup_banner() {
    
    
    /// get plist variables, server tag must be known
    
    let dict = NSDictionary(contentsOfFile:  ModelData.staticPath() + "/Info.plist")

    
    let apiurl = "https://api.ipify.org?format=json"
    IGOps.perform_get_request(url_to_request: apiurl) { status,body  in
        if status == 200 {
            let jsonBody = JSON(data: body!)
            let ip = jsonBody["ip"].string
            Sm.axx.ip = ip!
            
            /// once we have an ip address we can
            /// setup subscription
            
            Sm.axx.ci.make_subscription(myVerifyToken:Sm.axx.verificationToken())
            
            let t =  dict?["version"] ?? "vv??"
            
            Log.info("*****************  \(Sm.axx.title)(\(Sm.axx.servertag)) \(Sm.axx.version) \(t!) **********************")
            Log.info("** \(NSDate()) on \(Sm.axx.packagename) \(Sm.axx.ip):\( Sm.axx.portno) serving \( Sm.axx.modes.joined(separator: ","))")
            Log.info("*****************  \(Sm.axx.title)(\(Sm.axx.servertag)) \(Sm.axx.version) **********************")
        }
        else {
            fatalError("no ip address for this Kitura Server instance, status is \(status)")
        }
    }
}



/// command line arguments are xxx portno modes servertag title

let arguments = NSProcessInfo.processInfo().arguments
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

Sm.axx.portno  =  Int(arguments[2]) ?? 8090
Sm.axx.modes =  arguments[3].components(separatedBy: ",")
Sm.axx.setServer(servertag: arguments[1])
Sm.axx.title =  arguments[4]


///
/// Set up a simple Logger
///

Log.logger = HeliumLogger()

/// put an informative banner right into the log
startup_banner()

///
/// Create or restore the Membership DB
///
Membership.restoreMembership()



///
/// The Kitura router
///

let router = Router()
///
/// Setup routes - according to global modes setup from command line
///
SMaxxRouter.setupRoutes( router: router)


let server = HTTPServer.listen(port: Sm.axx.portno, delegate:router)

Server.run()

/// strangely, this runs off the bottom

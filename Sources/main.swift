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
import HeliumLogger
import SwiftyJSON
import LoggerAPI
import Foundation


let baseURLString = "https://api.instagram.com"

public typealias JSONDictionary = [String: Any]

// unclear why
//public protocol MainServer {
//    func mainPort() -> Int16
//    func jsonStatus() -> JSONDictionary
//}

open class  MainServer : NSObject {
    func mainPort() -> Int16 {
        fatalError()
    }
    func jsonStatus() -> JSONDictionary {
        fatalError()
    }
}
func ciFor(_ tag:String) -> InstagramCredentials {
    
    switch tag {
        
    case "PROD":        return InstagramCredentials(
        clientId: "09bff63ecf0f4e4c866041a455c7ff35",
        clientSecret: "ce190ab2737f46628a33f3484c4f3a17",
        callbackBase: "http://socialmaxx.net") // +/membership/instagram/callback
        
    // same credentials for both dev and local tags
    case "DEV":    return InstagramCredentials(
        clientId: "d7020b2caaf34e13a1ca4bdf1504e4dc",
        clientSecret: "0c320f295a3c45af9ff35c00bb341088",
        callbackBase: "http://socialmaxx.sytes.net")// +/membership/instagram/callback
        
    // same credentials for both dev and local tags
    default:    return InstagramCredentials(
        clientId: "XXXd7020b2caaf34e13a1ca4bdf1504e4dc",
        clientSecret: "0c320f295a3c45af9ff35c00bb341088",
        callbackBase: "http://XXXsocialmaxx.sytes.net")// +/membership/instagram/callback
        
    }
}


//open class Sm {
struct Smaxx {
    
    let started = "\(Date())"
    var packagename = "t5"
    var servertag = "-unassigned-"
    var portno:Int16  = 8090
    var version = "v0.465"
    var modes = ["reports","membership","workers"]
    var title = "SocialMaxx@UnspecifiedSite"
    var ip = "127.0.0.1"
    var verificationToken = ""
    
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
            "apicalls":IGOps.apiCount   ,
            "started":started   ,
            
            ]
        return a
    }
}




//    //let apiurl = "https://api.ipify.org?format=json"
//    NetClientOps.perform_get_request(schema:"https",host:"api.ipify.org",port:443,path:"?format=json")



/// start 1-4 servers based on the flavor modes passed on the startup command line
///   - at this time the servers are started on sequential ports


/// command line arguments are xxx portno modes servertag title




///
/// Setup routes - according to global modes setup from command line
///

func setupRoutersAndServers(_ smaxx:Smaxx) {
    let flavors = smaxx.modes
    var httpServerPort = smaxx.portno+1 // leave one for main server
    
    if flavors.contains("reports") {
        let rserver = ReportMakerMainServer(port:httpServerPort,smaxx:smaxx)
        let rrouter = Router()
        rrouter.setupRoutesForReports(mainServer:rserver , smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: rrouter)
        srv.started { [unowned rrouter] in
            reportMakerMainServer = rserver
            print("reports \(rrouter) starting on port \(rserver.mainPort())")
        }
        httpServerPort += 1
    }
    if flavors.contains("membership") {
        //
        
        let members = MembersMainServer(port:httpServerPort,tag:smaxx.servertag,  smaxx:smaxx )
        let mrouter = Router()
        mrouter.setupRoutesForMembership(mainServer:members , smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: mrouter)
        srv.started { [unowned members] in
            membersMainServer = members
            print("membership \(members) starting on port \(members.mainPort())")
        }
        httpServerPort += 1
    }
    if flavors.contains("workers") {
        //let workers = smaxx.workers
        let  workers = WorkersMainServer(port:httpServerPort, smaxx:smaxx)
        let wrouter = Router()
        wrouter.setupRoutesForWorkers(mainServer:workers, smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: wrouter)
        srv.started { [unowned wrouter] in
            workersMainServer = workers
            print("workers \(wrouter) starting on port \(workersMainServer.mainPort())")
        }
        httpServerPort += 1
    }
    /// this gets started unconditionally
    let rserver = HomePageMainServer(port:httpServerPort,servertag:smaxx.servertag,smaxx:smaxx)
    let mainplainrouter = Router()
    mainplainrouter.setupRoutesPlain(mainServer:rserver , smaxx:smaxx)
    let srv = Kitura.addHTTPServer(onPort: Int(smaxx.portno), with: mainplainrouter)
    srv.started { [unowned mainplainrouter] in
        /// put an informative banner right into the log
        print("main \(mainplainrouter) starting on port \(rserver.mainPort())")
        
    }
}

/// this gets Kitura to start processing requests, and the started callbacks above get called
///
/// Set up a simple Logger
///


Log.logger = HeliumLogger()

/// get our IP address, dont bother if we cant
IGOps.discoverIpAddress() { ip in
    
    
    var smaxx = Smaxx()
    
    /// make token from ip address
    
    smaxx.ip = ip
    
    let x =  ip.components(separatedBy: ".").joined(separator: "") // strip dots
    let verificationToken = "\(smaxx.servertag)\(smaxx.portno)\(x)"
    
    smaxx.verificationToken = verificationToken
    /// once we have an ip address we can
    /// setup subscription subscription from instagram
    
    
    instagramCredentials.make_subscription(verificationToken)
    
    
    
    // log what's going on
    
    Log.info("*****************  \(smaxx.title)(\(smaxx.servertag)) \(smaxx.version)  **********************")
    Log.info("** \(NSDate()) on \(smaxx.packagename) \(smaxx.ip):\( smaxx.portno) serving \( smaxx.modes.joined(separator: ","))")
    Log.info("*****************  \(smaxx.title)(\(smaxx.servertag)) \(smaxx.version) **********************")
    
    let arguments = ProcessInfo.processInfo.arguments
    guard arguments.count >= 5  else {
        
        // no args, use some reasonable defaults
        print("  -- usage for all SocialMaxx Servers\n        .build/debug/\(smaxx.packagename) servertag portno modes title")
        print("          servertag = one of prod or dev ; selects IG App Credentials")
        print("          portno = choose any for this Kitura Server instance")
        print("          modes = one or more of reports,membership,workers")
        print("          title = a banner for Front Panel pages")
        
        print("\n  -- eg \n")
        print("       .build/debug/\(smaxx.packagename)  DEV 8090 reports,membership,workers socialmaxx.sytes.net \n")
        print("       .build/debug/\(smaxx.packagename)  PROD 8094 reports,membership,workers socialmaxx.net  \n")
        exit(0)
        
    }
    
    
    smaxx.servertag =  arguments[1]
    instagramCredentials = ciFor(arguments[1])
    smaxx.portno  =  Int16(arguments[2]) ?? 8090
    smaxx.modes =  arguments[3].components(separatedBy: ",")
    smaxx.title =  arguments[4]
    
    /// finally, after absorbing the environment, set up kitura
    setupRoutersAndServers(smaxx )
    
    ///
    /// The Kitura router
    ///
    
    Kitura.run()
    
}

/// deliberately but strangely, this runs off the bottom

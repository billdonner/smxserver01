/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

/** hacked by wld
 
 Having a lot of difficulty defining global structures in main.swift and having compiler recognize them
 So,DONT add any more in here,
 
 **/
import Kitura
import KituraNet
import HeliumLogger
import SwiftyJSON
import LoggerAPI
import Foundation

//MARK:- PUT STRUCTURE AND CLASS DEFINITIONS ELSEWHERE

/// Having a lot of difficulty defining types  in main.swift and having compiler recognize them
/// So,DONT add any more in here,

//MARK:- ALL GLOBAL VARIABLES GO HERE
/// globals re: separate Kitura HTTP servers on separate ports
var membersMainServer : MembersMainServer!

var workersMainServer : WorkersMainServer!

var reportMakerMainServer : ReportMakerMainServer!

var homePageMainServer : HomePageMainServer!

var allServers:[SeparateServer] = []



/// globals re: remote communications with instagram
let DataTaskGet = false  // set only on MAC OSX to use urlsessions
let DataTaskPut = false  // set only on MAC OSX to use urlsessions

var instagramCredentials : InstagramCredentials!

let instagramBaseURLString = "https://api.instagram.com"


/// there are NO other globals in any other modules - put them above this line



//TODO: immediately -  implement internal rest calls between differnt servers

fileprivate func ciFor(_ tag:String) -> InstagramCredentials {
    
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


///
/// Setup routes - according to global modes setup from command line
///

fileprivate func setupRoutersAndServers(_ smaxx:Smaxx) {
    
    let start = Date() // figure out how long kitura takes to get servers listening
    
    let flavors = smaxx.modes
    var httpServerPort = smaxx.portno  // leave one for main server
    if flavors.contains("membership") {
        //
        
        let members = MembersMainServer(port:httpServerPort,tag:smaxx.servertag,  smaxx:smaxx )
        
        membersMainServer = members
        
        let mrouter = Router()
        mrouter.setupRoutesForMembership(mainServer:members , smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: mrouter)
        srv.started {
            let end = Date()
            let ms = String(format:"@%.2fms",end.timeIntervalSince(start)*1000.0)
               Log.info("membership \(membersMainServer!) started on port \(members.mainPort())  elapsed \(ms)")
            allServers.append(membersMainServer)
        }
        httpServerPort += 1
    }
    if flavors.contains("home") {
        
        //TODO: must be started after membership now
        let rserver = HomePageMainServer(port:httpServerPort,servertag:smaxx.servertag,smaxx:smaxx)
        
        homePageMainServer = rserver
        
        let mainplainrouter = Router()
        mainplainrouter.setupRoutesPlain(mainServer:rserver , smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: mainplainrouter)
        srv.started {
            /// put an informative banner right into the log
            
            let end = Date()
            let ms = String(format:"@%.2fms",end.timeIntervalSince(start)*1000.0)
               Log.info("homepage \(homePageMainServer!) started on port \(rserver.mainPort())  elapsed \(ms)")
            allServers.append(homePageMainServer)
            
        }
        httpServerPort += 1
    }
    if flavors.contains("reports") {
        let rserver = ReportMakerMainServer(port:httpServerPort,smaxx:smaxx)
        
        reportMakerMainServer = rserver
        
        let rrouter = Router()
        rrouter.setupRoutesForReports(mainServer:rserver , smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: rrouter)
        srv.started {
            
            let end = Date()
            let ms = String(format:"@%.2fms",end.timeIntervalSince(start)*1000.0)
         
               Log.info("reports \(reportMakerMainServer!) started on port \(rserver.mainPort())  elapsed \(ms)")
            allServers.append(reportMakerMainServer)
        }
        httpServerPort += 1
    }

    if flavors.contains("workers") {
        //let workers = smaxx.workers
        let  workers = WorkersMainServer(port:httpServerPort, smaxx:smaxx)
        
        workersMainServer = workers
        
        let wrouter = Router()
        wrouter.setupRoutesForWorkers(mainServer:workers, smaxx:smaxx)
        let srv = Kitura.addHTTPServer(onPort: Int(httpServerPort), with: wrouter)
        srv.started {  
            let end = Date()
            let ms = String(format:"@%.2fms",end.timeIntervalSince(start)*1000.0)
               Log.info("workers \(workersMainServer!) started on port \(workersMainServer.mainPort())  elapsed \(ms)")
            allServers.append(workersMainServer)
        }
        httpServerPort += 1
    }
    
}


//    //let apiurl = "https://api.ipify.org?format=json"
//    NetClientOps.perform_get_request(schema:"https",host:"api.ipify.org",port:443,path:"?format=json")



/// start 1-4 servers based on the flavor modes passed on the startup command line
///   - at this time the servers are started on sequential ports


/// command line arguments are xxx portno modes servertag title




//MARK:- MAIN SERVER STARTS HERE

/// this gets Kitura to start processing requests, and the started callbacks above get called
///
/// Set up a simple Logger
///


let hl =  HeliumLogger(.info)
hl.colored = false
Log.logger = hl
/// get our IP address, dont bother booting if we cant
let start = Date()
IGOps.discoverIpAddress() { ip in
    
    let ms = String(format:"@%.2fms",Date().timeIntervalSince(start)*1000.0)
    var smaxx = Smaxx()
    
    /// make token from ip address
    
    smaxx.ip = ip
    
    let x =  ip.components(separatedBy: ".").joined(separator: "") // strip dots
    let verificationToken = "\(smaxx.servertag)\(smaxx.portno)\(x)"
    
    smaxx.verificationToken = verificationToken
    
    
    // log what's going on
    
    Log.info("***************** \(smaxx.title)(\(smaxx.servertag)) \(smaxx.version) \(ms) **********************")
    Log.info("***************** \(NSDate()) on \(smaxx.packagename) \(smaxx.ip):\( smaxx.portno) serving \( smaxx.modes.joined(separator: ","))")
    Log.info("***************** \(smaxx.title)(\(smaxx.servertag)) \(smaxx.version) **********************")
    
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
    
    /// once we have an ip address we can
    /// setup subscription subscription from instagram
    
    
  //  instagramCredentials.make_subscription(verificationToken)
    
    
    
    ///
    /// The Kitura router
    ///
    
    Kitura.run()
    
}

/// deliberately but strangely, this runs off the bottom

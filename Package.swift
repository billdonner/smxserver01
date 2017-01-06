//- provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017 
///
// 28 May - new  t4 project to resolve xcode issues

import PackageDescription

let package = Package(
    name: "t5",
    dependencies: [
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1)
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", majorVersion: 1)
    
     ]
)
/*
 
 Routes and Servers
 ==========
 
 There are 4 Logical Servers, each running on a different tcp/ip port. 
 There is no shared memory between any of them, so they can run in separate processes, and even on separate processors.
 
 # HomePage Routes
 
- get("/fp") -- front panel html homepage
- get("/") -- a plain homepage
 
- get("/log")
 
- all("/_/", middleware: staticFileServer)
 
- post("/postcallback") -- to and from ig
- get("/postcallback")  -- to and from ig


# Reports routes:
 
- get("/reports")
- get("/reports/:id/:reportname")



 # Members routes:
 
- get("/membership") -- full list
- delete("/membership") - delete all
- get("/membership/:id")
- delete("/membership/:id")
- post("/membership")
- get("/showlogin") - step one in instagram credentials
- get("/authcallback") - from ig
- get("/unwindor") - when done




 # Workers routes:

-  get("/workers/start/:id")
-  get("/workers/stop/:id")
*/

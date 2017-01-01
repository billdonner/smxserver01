///  provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017 
///
// 28 May - new  t4 project to resolve xcode issues

import PackageDescription

let package = Package(
    name: "t5",
    dependencies: [
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),//15 is failing on 26 May
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
    .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", majorVersion: 1)
    
     ]
)

///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016 
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

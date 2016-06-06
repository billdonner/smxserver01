///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  ModelData.swift
//  SMaxxServer
//
//  Created by william donner on 5/3/16.
//
//

import LoggerAPI
import Foundation

public struct ModelData {
    //_smaxx-static
    static func staticPath()->String {
        return documentsPath() + "/_smaxx-static/"  + Sm.axx.servertag
    }
    static func membershipPath()->String {
        return documentsPath() + "/_membership/"
    }
    private static func documentsPath()->String {
        let docurl =  NSFileManager.default().urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)[0]
        let docDir = docurl.path ?? "no Documents Dicrectory"
        return docDir 
    }
   
}
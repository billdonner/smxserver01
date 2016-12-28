///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///


//
//  IGJson.swift
//  IGExplorer
//
//  Created by bill donner on 2/5/16.
//  Copyright © 2016 Bill Donner. All rights reserved.
//

// All JSON dependencies are isolated in this module
// eventually SwiftyJSON can be eliminated in favor of our own code now that swift2.2 is here

import Foundation

import SwiftyJSON


struct IGJSON {
    
    static func parseIgJSONIgPeople(_ jsonObject:AnyObject,f1:ParseIgJSONIgPeopleFunc ) {
        let json = JSON(jsonObject)
        if (json["meta"]["code"].intValue  == 200) {
            let url = json["pagination"]["next_url"].URL
            if let resData = json["data"].arrayObject as? BunchOfIGPeople {
                f1(url as URL?,resData)
            }
        }
    }
    
    
    static func parseIgJSONIgMedia(_ jsonObject:AnyObject,f1:ParseIgJSONIgMediaFunc ) {
        let json = JSON(jsonObject)
        if (json["meta"]["code"].intValue  == 200) {
            let url = json["pagination"]["next_url"].URL
            if let resData = json["data"].arrayObject as? BunchOfIGMedia {
                f1(url as URL?,resData)
            }
        }
    }
    static func parseIgJSONOAuth(_ jsonObject:AnyObject,f1:ParseIgJSONOAuthFunc ) {
        let json = JSON(jsonObject)
        
        if let accessToken = json["access_token"].string,
            let userID = json["user"]["id"].string {
            f1(accessToken,userID)
        }
        
    }
    
    
    static func parseIgJSONDict(_ jsonObject:AnyObject,f1:ParseIgJSONDictFunc ) {
        let json = JSON(jsonObject)
        let cd =  json["meta"]["code"].intValue
        
        if let data = json["data"].dictionaryObject {
            f1(cd,data as BasicDict)
        }
    }
}

///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  IGOps.swift
//  SocialMaxx
//
//  Created by bill donner on 1/18/16.
//  Copyright © 2016 SocialMax. All rights reserved.
//
import LoggerAPI
import Foundation

/// Upper level interface to Instagram API Operations

struct IGOps {
    /// this is good for a one shot get to anywhere
    static func perform_get_request(url_to_request: String,  completion:(Int,NSData?)->())
    {
        let session = NSURLSession.shared() // doesnt work with Sm.axx.session ??
        let url:NSURL = NSURL(string: url_to_request)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequestCachePolicy.reloadIgnoringCacheData
        
        let task = session.dataTask(with:request) {
            ( data,   response,  error) in
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                Log.error("perform_get_request completing with error \(error)")
                completion(error!.code,nil)
                return
            }
            completion(200,data)
            return
        }
        task.resume()
    }
    /// this is good for a one shot post to anywhere
    static func perform_post_request(url_to_request: String, paramString: String, completion:(Int,NSData?)->())
    {
        let session = NSURLSession.shared() // doesnt work with Sm.axx.session ??
        let url:NSURL = NSURL(string: url_to_request)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequestCachePolicy.reloadIgnoringCacheData
        request.httpBody = paramString.data(using: NSUTF8StringEncoding)
        
        let task = session.dataTask(with:request) {
            ( data,   response,  error) in
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                
                Log.error("perform_post_request completing with error \(error)")
                completion(error!.code,nil)
                return
            }
           // Log.error("Good post response \(response)")
            completion(200,data)
            return
        }
        task.resume()
    }
    static func get_token_for_member(targetID:String) throws -> String  {
        
        ///
        /// TODO: migrate to remote procedure call to Membership server
        ///
        if    let mem = Membership.shared.members[targetID],
            let token = mem["access_token"] as? String {
            return token
        }
        throw  SMaxxError.NoAccessTokenForUser(id: targetID)
    }
    static func getUserstuff (_ targetID:String,
                              completion:IntPlusOptDictCompletionFunc)
        throws -> IGOps.Router  {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID: targetID)
            let request = IGOps.Router.UserInfo(targetID,token)
            try IGOps.plainCall(url:request.URLRequest.url!,
                                completion: completion)
            return request
            
    }
    static func getRelationshipstuff (_ targetID:String,
                                      completion:IntPlusOptDictCompletionFunc)
        throws -> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID: targetID)
            let request = IGOps.Router.Relationship(targetID,token)
            try IGOps.plainCall(url:request.URLRequest.url!,
                                completion: completion)
            return request
            
    }
    
    static func getmediaPosts(_ targetID:String,
                              minid:String,
                              each:BOMCompletionFunc,
                              completion:IntCompletionFunc)
        throws  -> IGOps.Router {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID: targetID)
            let request = minid == "" ?
                IGOps.Router.MediaRecent (targetID,token) :
                IGOps.Router.MediaRecentInRange(targetID,token,minid)
            print ("getting posts via --- \((request.URLRequest.url!))")
            try IGOps.paginatedCall(url:request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
            return request
            
    }
    
    static func getAllFollowers(_ targetID:String,
                                each:BOPCompletionFunc,
                                completion:IntCompletionFunc)
        throws -> IGOps.Router  {
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID: targetID)
            let request = IGOps.Router.FollowedBy(targetID,token)
            try IGOps.paginatedCall(url:request.URLRequest.url!,
                                    each: each,
                                    completion: completion)
            return request
            
    }
    static func getAllFollowing(_ targetID:String,
                                each:BOPCompletionFunc,
                                completion:IntCompletionFunc)
        throws -> IGOps.Router  {
            // member must have access token for instagram api access
            
            let token = try get_token_for_member(targetID: targetID)
            let request = IGOps.Router.Following(targetID,token)
            try IGOps.paginatedCall(url:request.URLRequest.url!,each: each,completion: completion)
            return request
    }
    static func getLikersForMedia(_ targetID:String,
                                  _ mediablock:IGMediaBlock,
                                  each:BOMCompletionFunc,
                                  completion:IntCompletionFunc)
        throws  -> IGOps.Router {
            // member must have access token for instagram api access
            
            let token = try get_token_for_member(targetID: targetID)
            let id = mediablock["id"] as? String
            let request = IGOps.Router.MediaLikes(id!,token)
            try IGOps.paginatedCall(url:request.URLRequest.url!,each: each,completion: completion)
            return request
    }
    
    static func getCommentersForMedia(_ targetID:String,
                                      _ mediablock:IGMediaBlock,
                                      each:BOMCompletionFunc,
                                      completion:IntCompletionFunc)
        throws -> IGOps.Router {
            let id = mediablock["id"] as? String
            
            // member must have access token for instagram api access
            let token = try get_token_for_member(targetID: targetID)
            
            let request = IGOps.Router.MediaComments(id!,token)
            try IGOps.paginatedCall(url:request.URLRequest.url!,each: each,completion: completion)
            return request
    }
    
    
    private static func plainCall(url:NSURL,
                                  completion:IntPlusOptDictCompletionFunc)
        throws {
            try RemoteNetOps.nwGetJSON(nsurl:url) { status, jsonObject in
                Sm.axx.igApiCallCount += 1
                defer {
                }
                if status != 200 {
                    completion(status,[:])
                    return // DONT PARSE IF STATUS ISNT RIGHT
                    
                }
                IGJSON.parseIgJSONDict(jsonObject:jsonObject!) { code,dict in
                    completion(code,dict)
                }
            }
    }
    
    private static   func paginatedCall(url:NSURL,
                                        each:BOMCompletionFunc,
                                        completion:IntCompletionFunc) throws {
        
        try  RemoteNetOps.nwGetJSON(nsurl:url) { status, jsonObject in
            Sm.axx.igApiCallCount += 1
            defer {
            }
            if status == 200 {
                // DONT PARSE IF STATUS IS NOT RIGHT
                IGJSON.parseIgJSONIgMedia(jsonObject:jsonObject!) {
                    url, resData in
                    for every in resData {
                        each(every)
                    }
                    if url != nil  {
                        let  nextURL = url! // Request = NSURLRequest(URL: url!)
                        do {
                            try paginatedCall(url:nextURL,each:each,completion:completion)
                        }
                        catch {
                            print ("error in recursive paginatedCall")
                        }
                    } else {
                        // no more so run completion
                        completion(200)
                    }
                }
            }// status == 200
            else {
                completion(status) // signal up
            }
        }
    }
    
} // end of IGOps

extension IGOps { // functions that remap instagram data blocks
    
    static func convertRelationshipFrom(relationship:IGAnyBlock) ->  RelationshipData {
        let ob =  RelationshipData()
        ob.incoming = relationship["incoming_status"] as! String
        ob.outgoing = relationship["outgoing_status"] as! String
        ob.privacy  = relationship["target_user_is_private"] as! Bool
        return ob
    }
    static   func convertPersonFrom(person:IGUserBlock) ->  UserData {
        let ob  =  UserData()
        if let id  = person ["id"] as? String {ob.id = id }
        if let fn = person ["full_name"] as? String {ob.fullname = fn}
        if let un = person ["username"] as? String {ob.username = un}
        if let un = person ["profile_picture"] as? String {ob.pic = un}
        if let un = person ["bio"] as? String {ob.bio = un}
        if let un = person ["website"] as? String {ob.website = un}
        if let p = person ["counts"] as? IGMediaBlock {
            if  let m = p["media"] as? Int {
                if let f = p["follows"] as? Int {
                    if let fb = p["followed_by"] as? Int {
                        ob.igCounts =   [m,f,fb]
                    }
                }
            }
        }
        return ob
    }
    static    func convertCommentFrom(comments:IGAnyBlock) -> CommentData {
        let ob  =  CommentData()
        if let id = comments ["id"] as? String {
            ob.commentID = id
            ob.timestamp = comments["created_time"] as! String
            //ob.comment = comments["text"] as! String
            if let igPerson = comments["from"] as? IGUserBlock {
                ob.commenter = convertPersonFrom(person:igPerson)
            }
        }
        return ob
    }
    
    static    func convertCommentsFrom(comments:[IGAnyBlock]) ->  BunchOfComments {
        var bunch:  BunchOfComments = []
        for comment in comments {
            if let id = comment ["id"] as? String {
                let ob  =  CommentData()
                ob.commentID = id
                ob.timestamp = comment["created_time"] as! String
                //ob.comment = comment["text"] as! String
                if let igPerson = comment["from"] as? IGUserBlock {
                    ob.commenter = convertPersonFrom(person:igPerson)
                    bunch.append(ob)
                }
            }
        }
        return bunch
    }
    static    func convertPeopleFrom(people:BunchOfIGPeople) ->  BunchOfPeople {
        return people.map { convertPersonFrom(person:$0) }
    }
    static func convertPostFrom(media:IGMediaBlock, likers: BunchOfPeople, comments:  BunchOfComments) ->  MediaData{
        
        func convLikers (likers: BunchOfPeople) ->  PeopleDict {
            var pd =  PeopleDict()
            for liker in likers {
                pd[liker.id] = liker
            }
            return pd
        }
        
        func convComments (comments: BunchOfComments) ->  CommentsDict {
            var pd =  CommentsDict()
            for comment in comments {
                pd[comment.commentID] = comment
                
            }
            return pd
        }
        // this hugely shrinks the footprint of the app by not storing these large chunks
        let ob =  MediaData()
        if let id = media  ["id"] as? String {
            ob.id = id
            ob.likers = convLikers(likers:likers)
            ob.comments = convComments(comments: comments )
            ob.createdTime = media ["created_time"] as? String ?? ""
            if let cap = media["caption"] as? IGAnyBlock,
                let text = cap["text"] as? String {
                ob.caption = text
            }
            if let g = media["images"] ,
                let ii = g["thumbnail"] as? IGAnyBlock,
                let s = ii["url"] as? String {
                ob.thumbPic = s
            }
        }
        if let g = media["images"] ,
            let ii = g["standard_resolution"] as? IGAnyBlock,
            let s = ii["url"] as? String {
            ob.standardPic = s
        }
        if let tg = media["tags"] as? [String] {
            ob.tags = tg
        }
        if let tg = media["user_has_liked"] as?  Bool {
            ob.userHasLiked = tg
        }
        if let tg = media["likes"] as? IGMediaBlock{
            if let lc = tg["count"] as? Int {
                ob.igLikeCount = lc
            }
        }
        // docs may be incorrect here
        // perhaps we could say users_in_photo.username
        ob.taggedUsers = []
        if let users_in_photo = media["users_in_photo"] as? [AnyObject]{
            for tg in users_in_photo  {
                if let ttg = tg["user"] as? [String:AnyObject]{
                    if let og = ttg ["username"] as? String {
                        ob.taggedUsers.append(og)
                    }
                }
            }
        }
        if let tg = media["filter"] as? String {  ob.filters = [tg] }
        return ob
    }
}// end of class

extension IGOps { // networking
    
    
    enum Router {
        
        
        case MediaLikes(String,String)
        case MediaComments(String,String)
        case UserInfo(String,String)
        case Relationship(String,String)
        case MediaRecent(String,String)
        
        case MediaRecentInRange(String,String,String)//token,min_id
        
        case SelfMediaLiked(String,String)
        case SelfFollowing(String,String)
        case SelfFollowedBy(String,String)
        case Following(String,String) // deprecated by instagram ...soon
        case FollowedBy(String,String) // deprecated by instagram ...
        
        
        // MARK: apart from IG Oauth all the various IG api calls are vectored thru here
        
        var URLRequest: NSMutableURLRequest {
            let result: (path: String, parameters: URLParamsToEncode ) = {
                switch self {
                    
                    
                case .Relationship (let userID, let accessToken):
                    let pathString = "/v1/users/" + userID + "/relationship"
                    return (pathString, ["access_token": accessToken ])
                    
                case .UserInfo (let userID, let accessToken):
                    let pathString = "/v1/users/" + userID
                    return (pathString, ["access_token": accessToken ])
                    
                case .MediaLikes (let mediaID, let accessToken):
                    let pathString = "/v1/media/" + mediaID + "/likes"
                    return (pathString, ["access_token": accessToken ])
                    
                case .MediaComments (let mediaID, let accessToken):
                    let pathString = "/v1/media/" + mediaID + "/comments"
                    return (pathString, ["access_token": accessToken ])
                    
                case .MediaRecent (let userID, let accessToken ):
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken ])
                    
                case .MediaRecentInRange (let userID, let accessToken, let minID ):
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken,"min_id:":minID ])
                    
                case .SelfMediaLiked (  _, let accessToken):
                    let pathString = "/v1/users/self/media/liked"
                    return (pathString, ["access_token": accessToken ])
                    
                case .Following (let userID , let accessToken):
                    let pathString = "/v1/users/" + userID + "/follows"
                    return (pathString, ["access_token": accessToken ])
                    
                case .FollowedBy (let userID, let accessToken ):
                    let pathString = "/v1/users/" + userID + "/followed-by"
                    return (pathString, ["access_token": accessToken ])
                    
                case .SelfFollowing ( _, let accessToken):
                    let pathString = "/v1/users/" + "self" + "/follows"
                    return (pathString, ["access_token": accessToken ])
                    
                case .SelfFollowedBy (  _, let accessToken):
                    let pathString = "/v1/users/" + "self" + "/followed-by"
                    return (pathString, ["access_token": accessToken ])
                    
                    
                    // default: break
                }
            }()
            
            let baseurl = NSURL(string: Sm.axx.baseURLString)!
            let fullurl = baseurl.appendingPathComponent(result.path)
            let encodedrequest = RemoteNetOps.encodedRequest(fullurl:fullurl, params: result.parameters)
            return encodedrequest
        }
    }
}
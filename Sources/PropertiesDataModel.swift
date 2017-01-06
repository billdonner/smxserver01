/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  PropertiesDataModel.swift
//  t3
//
//  Created by william donner on 5/25/16.
//
//

import Foundation

///
//MARK:- Persistent Comment Data
///
// @objc(CommentData)

class CommentData :NSObject ,NSCoding{
    // var comment: String = ""
    var timestamp : String = ""
    var commentID: String  = ""
    var commenter: UserData?
    
    override init() {}
    
    required init?(coder aDecoder:NSCoder) {
        super.init()
        //comment = aDecoder.decodeObject(forKey: "comment") as? String ?? ""
        commentID = aDecoder.decodeObject(forKey: "commentID") as? String ?? ""
        timestamp = aDecoder.decodeObject(forKey: "timestamp") as? String ?? ""
        commenter = aDecoder.decodeObject(forKey: "commenter") as? UserData
    }
    func encode(with aCoder: NSCoder) {
        // aCoder.encode(comment, forKey: "comment")
        aCoder.encode(commentID, forKey: "commentID")
        aCoder.encode(timestamp, forKey: "timestamp")
        aCoder.encode(commenter, forKey: "commenter")
    }
}

///
//MARK:- Persistent Relationship Data
///
// @objc(RelationshipData)

class RelationshipData :NSObject ,NSCoding{
    var incoming: String = ""
    var outgoing : String = ""
    var privacy: Bool = true
    var hasNoRelationship: Bool {
        return incoming=="none" && outgoing=="none"
    }
    
    override init() {}
    
    required init?(coder aDecoder:NSCoder) {
        super.init()
        incoming = aDecoder.decodeObject(forKey: "incoming") as? String ?? ""
        outgoing = aDecoder.decodeObject(forKey: "outgoing") as? String ?? ""
        privacy = aDecoder.decodeObject(forKey: "isprivate") as? Bool ?? false
    }
    func encode(with aCoder: NSCoder) {
        aCoder.encode(incoming, forKey: "incoming")
        aCoder.encode(outgoing, forKey: "outgoing")
        aCoder.encode(privacy, forKey: "isprivate")
    }
}

///
//MARK:- Persistent User Data
///
// @objc(UserData)

class UserData :NSObject ,NSCoding{
    
    // from instagram
    var id : String = ""
    var fullname : String = ""
    var username : String = ""
    var pic : String = ""
    var bio : String = ""
    var website: String = "" // of the URL
    var igCounts: [Int] = [0,0,0]
    
    override init() {}
    
    required init?(coder aDecoder:NSCoder) {
        super.init()
        id = aDecoder.decodeObject(forKey: "id") as? String ?? ""
        fullname = aDecoder.decodeObject(forKey: "fullname") as? String ?? ""
        username = aDecoder.decodeObject(forKey: "username") as? String ?? ""
        pic = aDecoder.decodeObject(forKey: "pic") as? String ?? ""
        bio = aDecoder.decodeObject(forKey: "bio") as? String ?? ""
        website = aDecoder.decodeObject(forKey: "website") as? String ?? ""
        igCounts  = aDecoder.decodeObject(forKey: "igcounts") as? [Int] ?? [0,0,0]
    }
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(fullname, forKey: "fullname")
        aCoder.encode(username, forKey: "username")
        aCoder.encode(pic, forKey: "pic")
        aCoder.encode(bio, forKey: "bio")
        aCoder.encode(website, forKey: "website")
        aCoder.encode(igCounts, forKey: "igcounts")
    }
}

///
//MARK:- Persistent Media Data
///
//@objc(MediaData)

class MediaData:NSObject,NSCoding  { // keep the likers attached to the media they like
    var id : String = ""
    var createdTime: String = "" // per IG Specs
    var caption: String = "<no caption>"
    var thumbPic: String = "no pic??"
    var standardPic: String = "no pic??"
    var userHasLiked: Bool = false
    var igLikeCount: Int = -1
    var likers: PeopleDict = [:]
    var comments: CommentsDict = [:]
    var tags: BunchOfTags = []
    var filters: BunchOfFilters = []
    var taggedUsers: BunchOfTaggedUsers = []
    
    override init() {}
    
    required init?(coder aDecoder:NSCoder) {
        super.init()
        id = aDecoder.decodeObject(forKey: "id") as? String ?? ""
        createdTime = aDecoder.decodeObject(forKey: "createdTime") as? String ?? ""
        caption = aDecoder.decodeObject(forKey: "caption") as? String ?? ""
        thumbPic = aDecoder.decodeObject(forKey: "thumbPic") as? String ?? ""
        standardPic = aDecoder.decodeObject(forKey: "standardPic") as? String ?? ""
        userHasLiked = aDecoder.decodeObject(forKey: "userHasLiked") as? Bool ?? false
        igLikeCount = aDecoder.decodeObject(forKey: "igLikeCount") as? Int ?? 0
        likers = aDecoder.decodeObject(forKey: "likers") as! PeopleDict
        comments = aDecoder.decodeObject(forKey: "comments") as! CommentsDict
        tags = aDecoder.decodeObject(forKey: "tags") as! BunchOfTags
        filters = aDecoder.decodeObject(forKey: "filters") as! BunchOfFilters
        taggedUsers = aDecoder.decodeObject(forKey: "taggedUsers") as! BunchOfTaggedUsers
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(createdTime, forKey: "createdTime")
        aCoder.encode(caption, forKey: "caption")
        aCoder.encode(thumbPic, forKey: "thumbPic")
        aCoder.encode(standardPic, forKey: "standardPic")
        aCoder.encode(likers, forKey: "likers")
        aCoder.encode(comments, forKey: "comments")
        aCoder.encode(tags, forKey: "tags")
        aCoder.encode(filters, forKey: "filters")
        aCoder.encode(taggedUsers, forKey: "taggedUsers")
        aCoder.encode(userHasLiked, forKey: "userHasLiked")
        aCoder.encode(igLikeCount, forKey: "igLikeCount")
    }
}

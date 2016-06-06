///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  OUData.swift
//  moved to Kitura on 5/4/16
//  moved non-IG stuff from Instagram.swift on 5/11
//
//  Created by bill donner on 1/19/16.
//  Copyright © 2016 Bill Donner. All rights reserved.
//

import Foundation

///
//MARK: - Universal TypeDefs that work with SocialMaxx base data regardless of particular social networks
///

typealias Intfunc = (Int->())
typealias OptIntFunc = Intfunc?
typealias BasicDict = [String : AnyObject]
typealias OptDict = BasicDict?
typealias URLParamsToEncode = OptDict
typealias FilterFunc = (key:String,val:AnyObject)->Bool
typealias OptFilterFunc = FilterFunc?
typealias NetCompletionFunc = (status: Int, object: AnyObject?) -> ()

typealias IntCompletionFunc = (Int)->()
typealias IntPlusOptDictCompletionFunc = (Int,OptDict)->()
typealias PullIntCompletionFunc  = (SocialDataProcessor -> ())

typealias BunchOfComments = [CommentData]
typealias BunchOfMedia = [MediaData]
typealias BunchOfPeople = [UserData]

typealias BunchOfTags = [String]
typealias BunchOfFilters = [String]
typealias BunchOfTaggedUsers = [String]

typealias CommentsDict = [String:CommentData]
typealias MediaDict = [String:MediaData]
typealias PeopleDict = [String:UserData]

typealias TagsDict = [String:String]
typealias FiltersDict = [String:String]
typealias TaggedUsersDict = [String:String]

struct AvLikerContext { var count:Int, postsBeforeFirst:Int,postsBeforeLast:Int,user: UserData }
struct StringLikerContext { var count:Int,likerTotal:Int,postsBeforeFirst:Int,postsBeforeLast:Int,val:String }
typealias AnalysisBlock = [String:AvLikerContext]
typealias StringAnalysisBlock = [String:StringLikerContext]

struct FreqCount {
    let idx:Int
    var frequency:Int
}

///
//MARK: - SocialDataProcessor ties together a SocialPerson with her persistent representation on disk and a processing pipeline that periodically updates the SocialPerson with regards to her social network(s)

///
class  SocialDataProcessor {
    
    var targetID: String // represents the  userID for this SocialDataProcessor
    var targetAccessToken: String // the Instagram Access Token gets copied into here
    var pipeLineStatus = 200 //passes status from background up
    var pipelineStart = NSDate()
    
    ///
    //MARK: - scratch storage that is not stored to persistent data Model
    ///
    
    var likersDict :  AnalysisBlock = [:]
    var commentersDict : AnalysisBlock = [:]
    var tagsFreqDict : StringAnalysisBlock = [:]
    var taggedUsersFreqDict : StringAnalysisBlock = [:]
    var filtersFreqDict : StringAnalysisBlock = [:]
    
    var rawPosts: [IGMediaBlock] = []
    var rawFollowers: [IGUserBlock] = []
    var rawFollowing: [IGUserBlock] = []
    var rawPostIndex = -1
    
    var rawCommentsDict : [String: BunchOfComments] = [:]
    var rawLikesDict : [String: BunchOfPeople] = [:]
    
    ///
    //MARK: - persistent data model for this target id
    ///
    
    var pd: PersonData // let this get changed
    
    init(id:String,token:String) {
        pd = PersonData()
        self.targetID = id
        self.targetAccessToken = token
    }
 
    func figureLikesAndComments () { // used by many reports
        likersDict = Instagram.dictOfAvLikersArossBunchOfMedia(posts: pd.ouMediaPosts)
        commentersDict = Instagram.dictOfAvCommenteursArossBunchOfMedia(posts: pd.ouMediaPosts)
        
    }
    func figureTags() { // used by tags based reports
        tagsFreqDict = Instagram.dictOfTagsByLikersArossBunchOfMedia(pd.ouMediaPosts)
        taggedUsersFreqDict = Instagram.dictOfTaggedUsersByLikersArossBunchOfMedia (pd.ouMediaPosts)
        filtersFreqDict = Instagram.dictOfFiltersByLikersArossBunchOfMedia (pd.ouMediaPosts)
    }
}// OU ends here now




//  Moved to Kitura on 5/4/16
//  Instagram.swift
import Foundation



struct Instagram {
    
    
    struct Frqi {
        var key:Int
        var counter = 0
    }
    struct Frqs {
        var key:String = ""
        var counter = 0
    }
    struct Frqtd {
        var key:String = ""
        var ratio:Double = 0
    }
    struct Frqc {
        var key:String
        var counter = 0
        var user: UserData?
    }

   static  func inNotIn(_ a:AnalysisBlock,_ b:AnalysisBlock) -> AnalysisBlock {
        var ret : AnalysisBlock = [:]
        for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
        return ret
    }
    
    
    // open Instagram app in various ways
    
    static func grandTotalLikes(_ ig:SocialDataProcessor ) -> Int {
        var total = 0
        for (_,val) in ig.likersDict {
            total += val.count
        }
        return total
    }
    static func countsAndAveragesFromPosts(_ ig:SocialDataProcessor ,igPerson: UserData) -> (Int,String,Int,String) {
        var counter = 0
        var avg = 0.0
        if  let a = ig.likersDict [igPerson.id] {
            counter = a.count
            avg = Double(a.count) /
                Double(ig.pd.ouMediaPosts.count - a.postsBeforeFirst)
        }
        let average = String(format:"%.2f",avg)
        var counter2 = 0
        var avg2 = 0.0
        if  let a = ig.commentersDict[igPerson.id] {
            counter2 = a.count
            avg2 = Double(a.count) /
                Double(ig.pd.ouMediaPosts.count - a.postsBeforeFirst)
        }
        let average2 = String(format:"%.2f",avg2)
        return (counter,average,counter2,average2)
    }
    
    
    // return tuples that can be divided to get avg :)
    static func dictOfAvLikersArossBunchOfMedia(_ posts: BunchOfMedia) ->  AnalysisBlock {
        var ret :  AnalysisBlock = [:]
        var postcount = 0
        for onepost in posts {
            if   onepost.likers.count != 0   {
                // each like in each post
                for (_,likerUser) in onepost.likers  {
                    // if first time this User/Liker is seen then record postcount before
                    let likerUserID = likerUser.id
                    if ret[likerUserID] == nil {  //first Like
                        ret[likerUserID] = AvLikerContext(count:1,
                                                          postsBeforeFirst:postcount,
                                                          postsBeforeLast: postcount,
                                                          user:likerUser) }
                    else { let analysisBlock = ret[likerUserID] // otherwise just bump the likes count
                        ret[likerUserID]! =  AvLikerContext(
                            count:analysisBlock!.count + 1 ,
                            postsBeforeFirst:analysisBlock!.postsBeforeFirst,
                            postsBeforeLast: postcount,
                            user:likerUser) }
                }
            }
            postcount += 1
        }
        return ret
    }
    static func dictOfTaggedUsersForUser(_ aUserID:String, posts: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        
        var postcount = 0
        for onepost in posts {
            let likersCount = onepost.likers.count 
            if let _ = onepost.likers[aUserID] {// are we a liker?
                
                // each tag in each post liked by this user
                for atag in onepost.taggedUsers {
                    if ret[atag] == nil {
                        ret[atag] = StringLikerContext (count:1, likerTotal:likersCount, postsBeforeFirst: postcount,
                                                        postsBeforeLast: postcount, val:atag) }
                    else { let zz = ret[atag] // otherwise just bump the likes count
                        ret[atag]! =  StringLikerContext(count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount, postsBeforeFirst:zz!.postsBeforeFirst,
                                                         postsBeforeLast: postcount ,val:atag)
                    }
                } // end for loop over tagged
            }// we are a liker
            
            postcount += 1
            
        }// for posts
        return ret
    }
    static func dictOfFiltersForUser(_ aUserID:String, posts: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        
        var postcount = 0
        for onepost in posts {
            let likersCount = onepost.likers.count 
            if let _ = onepost.likers[aUserID] {// are we a liker?
                
                // each tag in each post liked by this user
                for atag in onepost.filters {
                    if ret[atag] == nil {
                        ret[atag] = StringLikerContext (count:1, likerTotal:likersCount, postsBeforeFirst: postcount,
                                                        postsBeforeLast: postcount, val:atag) }
                    else { let zz = ret[atag] // otherwise just bump the likes count
                        ret[atag]! =  StringLikerContext(count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount, postsBeforeFirst:zz!.postsBeforeFirst,
                                                         postsBeforeLast: postcount ,val:atag) }
                }
            }
            postcount += 1
        }
        return ret
    }
    
    static func dictOfTagsForUser(_ aUserID:String, posts: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        
        var postcount = 0
        for onepost in posts {
            let likersCount = onepost.likers.count 
            if let _ = onepost.likers[aUserID] {// are we a liker?
                // each tag in each post liked by this user
                for atag in onepost.tags {
                    if ret[atag] == nil {
                        ret[atag] = StringLikerContext (count:1, likerTotal:likersCount, postsBeforeFirst: postcount,
                                                        postsBeforeLast: postcount, val:atag) }
                    else { let zz = ret[atag] // otherwise just bump the likes count
                        ret[atag]! =  StringLikerContext(count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount, postsBeforeFirst:zz!.postsBeforeFirst,
                                                         postsBeforeLast: postcount ,val:atag) }
                }
            }
            postcount += 1
        }
        return ret
    }
    
    static func dictOfTagsByLikersArossBunchOfMedia(_ x: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        var postcount = 0
        for onepost in x {
            let likersCount = onepost.likers.count 
            
            // each tag in each post
            for atag in onepost.tags {
                if ret[atag] == nil {
                    ret[atag] = StringLikerContext(count:1, likerTotal:likersCount,postsBeforeFirst:postcount ,
                                                   postsBeforeLast: postcount , val:atag) }
                else { let zz = ret[atag] // otherwise just bump the likes count
                    ret[atag]! =  StringLikerContext(count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount,postsBeforeFirst:zz!.postsBeforeFirst,
                                                     postsBeforeLast: postcount ,val:atag) }
            }
            postcount += 1
        }
        return ret
    }
    
    static func dictOfTaggedUsersByLikersArossBunchOfMedia(_ x: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        var postcount = 0
        let _ = x.map { onepost in
            let likersCount = onepost.likers.count 
            let l = onepost.taggedUsers
            // each user tagged  in each post
            let _ =  l.map { taggeduser in
                if ret[taggeduser] == nil {
                    ret[taggeduser] = StringLikerContext(count:1, likerTotal:likersCount,postsBeforeFirst:postcount ,
                                                         postsBeforeLast: postcount , val:taggeduser) }
                else { let zz = ret[taggeduser] // otherwise just bump the likes count
                    ret[taggeduser]! =  StringLikerContext(count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount,postsBeforeFirst:zz!.postsBeforeFirst,
                                                           postsBeforeLast: postcount ,val:taggeduser) }
            }
            postcount += 1
        }
        return ret
    }
    
    static func dictOfFiltersByLikersArossBunchOfMedia(_ x: BunchOfMedia) -> StringAnalysisBlock {
        var ret : StringAnalysisBlock = [:]
        var postcount   = 0
        for onepost in x {
            // get count of likers for this post
            let likersCount = onepost.likers.count 
            
            // each filter  in each post
            for afilter in onepost.filters {
                if ret[afilter] == nil {
                    ret[afilter] = StringLikerContext(count:1, likerTotal:likersCount,postsBeforeFirst:postcount,
                                                      postsBeforeLast: postcount, val:afilter) }
                else { let zz = ret[afilter] // otherwise just bump the likes count
                    ret[afilter]! = StringLikerContext (count:zz!.count + 1 , likerTotal: zz!.likerTotal + likersCount,postsBeforeFirst:zz!.postsBeforeFirst,
                                                        postsBeforeLast: postcount,val:afilter) }
            }
            postcount += 1
        }
        return ret
    }
    
    static func dictOfAvCommenteursArossBunchOfMedia( _ posts: BunchOfMedia) -> AnalysisBlock {
        var ret : AnalysisBlock = [:]
        var postcountBeforeFirstComment  = 0
        for onepost in posts {
            //if let l = onepost.comments {
            // each comment in each post
            for (_,onecomment) in onepost.comments {
                let user = onecomment.commenter!
                let userid = user.id
                if ret[userid] == nil {
                    ret[userid] = AvLikerContext(count:1, postsBeforeFirst :postcountBeforeFirstComment,postsBeforeLast :postcountBeforeFirstComment,user:user) }
                    // otherwise just bump the likes count
                else { let zz = ret[userid]
                    ret[userid]! =  AvLikerContext(count:zz!.count + 1
                        ,postsBeforeFirst :zz!.postsBeforeFirst,postsBeforeLast : // check this arg
                        postcountBeforeFirstComment,user:user) }
            }
            postcountBeforeFirstComment += 1
        }
        return ret
    }
    
    //    static func computeMutualFollowers(igp:SocialDataProcessor ) ->  BunchOfPeople { // not used on server
    //      //  guard let base = Globals.shared.igLoggedOnPersonData else {
    //            fatalError("Cant get base person data in computeMutualFollowers")
    //      //  }
    //       // return    intersect(igp.pd.ouAllFollowers, base.pd.ouAllFollowers)
    //        return []
    //    }
    static func computeFreqCountForLikers(_ igp:SocialDataProcessor ,filter:OptFilterFunc) ->([Frqc],Int,Int) {
        let likers = igp.likersDict
        var countlikes = 0
        var countlikers = 0
        
        var slikers : [Frqc] = []
        for (key,val) in likers {
            let b = (filter != nil) ? filter!(key,val.user) : true
            
            if b == true {
                countlikers += 1
                countlikes += val.count
                slikers.append(Frqc(key:key,counter:val.count,user:val.user))
            }
        }
        slikers.sort { $0.counter > $1.counter }// descending by frequency
        return (slikers,countlikes,countlikers)
    }
    
    // MARK:- Speechless Likers - who have never commented
    
    static func computeFreqCountForSpeechlessLikers(_ igp:SocialDataProcessor ) ->([Frqc],Int,Int) {
        let likersWhoDontComment = inNotIn(igp.likersDict ,igp.commentersDict)
        let   x = computeFreqCountForLikers(igp,filter: { key, val in
            if let user = val as?  UserData {
                let found = likersWhoDontComment[user.id]
                if found == nil {
                    return false }
                else {
                    return true }
            }
            return false
        })
        return x
    }
    // MARK:- Top Commenters
    
    static func computeFreqCountForCommenters(_ igp:SocialDataProcessor ,filter:OptFilterFunc) ->([Frqc],Int,Int) {
        var countcomments = 0
        var countcommenters = 0
        var slikers : [Frqc] = []
        for (key,val) in igp.commentersDict {
            let b = (filter != nil) ? filter!(key,val.user) : true
            
            if b == true {
                countcommenters += 1
                countcomments += val.count
                slikers.append(Frqc(key:key,counter:val.count,user:val.user))
            }
        }
        slikers.sort { $0.counter > $1.counter }// descending by frequency
        return (slikers,countcomments,countcommenters)
    }
    
    
    // MARK:- Heartless Commenters - who dont like anything but post anyways
    
    static func computeFreqCountForHeartlessCommenters(_ igp:SocialDataProcessor ) ->([Frqc],Int,Int) {
        let commentersWhoDontLike = inNotIn(igp.commentersDict,igp.likersDict )
        
        let x =  computeFreqCountForCommenters(igp,filter:{ (key, val) -> Bool in
            
            if let user = val as?  UserData {
                let found = commentersWhoDontLike[user.id]
                if found == nil {
                    return false }
                else {
                    return true }
            }
            return false
        })
        return x
    }
    
    // MARK: - Top Posts By Comments
    
    static func computeFreqCountOfCommentersForPosts(_ posts: BunchOfMedia) ->([Frqi],Int) {
        
        var slikers : [Frqi] = []
        var totlikes = 0
        var idx = 0
        let _ = posts.map { post in
            let counter = post.comments.count
            slikers.append(Frqi(key: idx ,counter: counter))
            totlikes += counter
            idx += 1
            // now we have a dictionary of liker ids and their frequencieser
        }//posts.map
        slikers.sort{ $0.counter > $1.counter }// descending by frequency
        return (slikers,totlikes)
    }
    
    // MARK: - Top Posts By Likes
    
    static func computeFreqCountOfLikesForPosts(_ posts: BunchOfMedia) ->([Frqi],Int) {
        
        var slikers : [Frqi] = []
        var totlikes = 0
        var idx = 0
        let _ = posts.map { post in
            
            let counter = post.likers.count
            slikers.append(Frqi(key: idx ,counter: counter))
            totlikes += counter
            idx += 1
            
        }//posts.map
        slikers.sort { $0.counter > $1.counter }// descending by frequency
        return (slikers,totlikes)
    }
    
    // MARK: - Top Posts By  FollowersLikes
    
    static func computeFreqCountOfFollowersLikesForPosts(_ igp:SocialDataProcessor ) ->([Frqi],Int) {
        func dictById(_ x: BunchOfPeople) -> [String:Int] {
            var ret : [String:Int] = [:]
            let _ = x.map {
                let z = $0.id
                if (ret[z] != nil) {
                    let cur = ret[z]
                    ret[z] = cur! + 1
                } else { ret[z] = 1 }
            }
            return ret
        }
        
        let f = igp.pd.ouAllFollowers
        let p = igp.pd.ouMediaPosts
        let fd = dictById(f)
        var likersWhoAreFollowers : [String:Int] = [:]
        // go thru all the posts, filter all the likers into dict
        let _ = p.map { pp in
            for (_, l) in  pp.likers {
                if let _ = fd[l.id] {
                    likersWhoAreFollowers[l.id] = 0 // This liker should be included
                } else {
                    if let cur = likersWhoAreFollowers[l.id] {
                        likersWhoAreFollowers[l.id] = cur + 1
                    }
                    else {
                        assert(true, "likerswhoarefollowers")
                    }
                }
            }}
        // now consider only likers who are followers as we count thru
        var slikers : [Frqi] = []
        var totlikes = 0
        var idx = 0
        
        let _ = p.map { post in
            var counter = 0
            for (_,l) in post.likers {
                if let _ = likersWhoAreFollowers[l.id] {
                    counter += 1
                }
            }
            if counter > 0 { // only add
                slikers.append(Frqi(key: idx ,counter: counter))
                totlikes += counter
                idx += 1
            }
            // now we have a dictionary of liker ids and their frequencieser
            
        }//posts.map
        slikers.sort { $0.counter > $1.counter }// descending by frequency
        return (slikers,totlikes)
    }
    
    
    
    // MARK: - When Do I Post?
    
    static  func calculateMediaPostHisto24x7(_ posts: BunchOfMedia)-> MI {
        var postsPerBucket = Matrix(rows:7, columns: 24) // filled with zeroes
        let dateFormatter = DateFormatter() // expensive
        var totallikerd = 0
        let _ = posts.map  {post in
            
            let z =  post.likers.count
            let (hourOfDay,dayOfWeek) = IGDateSupport.computeTimeBucketFromIGTimeStamp(post.createdTime,dateFormatter:dateFormatter)
            postsPerBucket[dayOfWeek,hourOfDay] = postsPerBucket[dayOfWeek,hourOfDay]+1
            totallikerd += z
            //}
        }
        return MI(m:postsPerBucket,i:totallikerd)
    }
    
    // MARK: - When Should I Post ?
    static func calculateMediaLikesHisto24x7(_ posts: BunchOfMedia)->MI {
        let dateFormatter = DateFormatter() // expensive
        var postsPerBucket = Matrix(rows:7, columns: 24) // filled with zeroes
        var likesPerBucket = Matrix(rows:7, columns: 24) // filled with zeroes
        var likeRatioBuckets = Matrix(rows:7, columns: 24) // filled with zeroes
        var totallikers = 0
        let _ = posts.map { post in
            let z =  post.likers.count
            let (hourOfDay,dayOfWeek) = IGDateSupport.computeTimeBucketFromIGTimeStamp(post.createdTime,dateFormatter:dateFormatter)
            postsPerBucket[dayOfWeek,hourOfDay] = postsPerBucket[dayOfWeek,hourOfDay]+1
            likesPerBucket[dayOfWeek,hourOfDay] = likesPerBucket[dayOfWeek,hourOfDay] + Double(z)
            totallikers += z
        }
        for hourOfDay in 0..<likeRatioBuckets.columns {
            for dayOfWeek  in 0..<likeRatioBuckets.rows {
                likeRatioBuckets[dayOfWeek,hourOfDay] =  postsPerBucket[dayOfWeek,hourOfDay] == 0 ? 0 : likesPerBucket[dayOfWeek,hourOfDay] / postsPerBucket[dayOfWeek,hourOfDay]
            }
        }
        
        return MI(m:likeRatioBuckets,i:totallikers)
    }
    // MARK: Calculated To Fail - Dummy
    static func calculateFail()->Matrix {
        let fail = Matrix(rows: 0, columns: 0)
        return fail
    }
}







//func inAndIn(_ a:AnalysisBlock,_ b:AnalysisBlock) -> AnalysisBlock {
//    var ret : AnalysisBlock = [:]
//    for (key,val) in a {  if (b[key] == nil) { } else { ret[key] = val }}
//    return ret
//}

// MARK: Support funcs
// func removeDuplicates(_ array:BunchOfIGPeople) -> BunchOfIGPeople {
//    var encountered = Set<String>()
//    var result: BunchOfIGPeople = []
//    for value in array {
//        if let id = value["id"] as? String {
//            if !encountered.contains(id) {
//                // Do not add a duplicate element.
//                // Add id to the set.
//                encountered.insert(id)
//                // ... Append the value.
//                result.append(value)
//            }
//        }
//    }
//    return result
//}
//
// func reverseFrequencyOrder (_ aa: BunchOfPeople,
//                                   by: BunchOfPeople) ->  BunchOfPeople {
//    // reorders the users in aa
//    // according to the frequency of references in block by
//    // both are assumed to be in sort order, aa must be unique
//    var aaidx = 0
//    var byidx = 0
//    var result: BunchOfPeople = []
//    var frequencies :[FreqCount] = []
//    let aacount = aa.count
//    let bycount = by.count
//    for idx in 0..<aacount {
//        frequencies.append(FreqCount(idx: idx,frequency: 0))
//    }
//    while aaidx < aacount && byidx < bycount {
//        // depends on short circuit evaluation by &&
//        while aaidx < aacount  && (aa[aaidx].id) < (by[byidx].id){
//            aaidx = aaidx + 1
//        }
//
//        while aaidx < aacount  && byidx < bycount && (aa[aaidx].id) >=  (by[byidx].id) {
//            if (aa[aaidx].id) ==  (by[byidx].id) {
//
//                frequencies[aaidx].frequency = frequencies[aaidx].frequency + 1
//            }
//            byidx = byidx + 1
//        }
//    }
//    // rearrange results
//    frequencies.sort  { $0.frequency>$1.frequency }
//    for freq in frequencies {
//        result.append(aa[freq.idx])
//    }
//    return result
//}
// func intersect(_ array1:  BunchOfPeople,
//                      _ array2: BunchOfPeople) ->  BunchOfPeople {
//    var encountered = Set<String>()
//    var result:  BunchOfPeople = []
//    for value in array1 {
//        if !encountered.contains(value.id ) {
//            // Do not add a duplicate element.
//            // Add value to the set.
//            encountered.insert(value.id )
//        }
//    }
//    for value in array2 {
//        if encountered.contains(value.id) {
//            // Its in both
//
//            // ... Append the value.
//            result.append(value)
//        }
//    }
//    return result
//}


//static func xinNotIn(_ a:StringAnalysisBlock,_ b:AnalysisBlock) -> StringAnalysisBlock {
//    var ret : StringAnalysisBlock = [:]
//    for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
//    return ret
//}
//static  func xinNotIn(_ a:AnalysisBlock,_ b:StringAnalysisBlock) -> AnalysisBlock {
//    var ret : AnalysisBlock = [:]
//    for (key,val) in a {  if (b[key] != nil) { } else { ret[key] = val }}
//    return ret
//}


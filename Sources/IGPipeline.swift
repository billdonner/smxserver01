/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  nsops.swift
//  xig
//
//  Created by bill donner on 3/18/16.
//  Copyright © 2016 billdonner. All rights reserved.
//
import LoggerAPI
import Foundation


// MARK:- Root of All Background NSOperations



open class NsOp: Operation {
    
    var opname: String = ""
    weak  var igp:SocialDataProcessor!
    var finalWrapUpOp: FinalWrapUpOp!
    var delegate:IGDataEngineDelegate?
    
    
    fileprivate var subq: OperationQueue!
    
    
    static func aprint(_ s:String) {
        // dispatch_async(dispatch_get_main_queue()) {
        print(s)
        // }
    }
    func handleMediaPostMinMax(_ post:IGMediaBlock) {
        if let postid = post["id"] as? String  {
            
            // instagram has variable size ids
            
            let pcc = postid.characters.count
            let mincc = self.igp.pd.ouMinMediaPostID.characters.count
            let maxcc = self.igp.pd.ouMaxMediaPostID.characters.count
            
            // first the min
            if pcc > mincc {
            } else
            if pcc < mincc {
               // let prev = self.igp.pd.ouMinMediaPostID
                self.igp.pd.ouMinMediaPostID = postid
               // print("ccmin was \(prev) set to \(postid)")
                
            } else
                if  postid < self.igp.pd.ouMinMediaPostID {
                    //let prev = self.igp.pd.ouMinMediaPostID
                    self.igp.pd.ouMinMediaPostID = postid
                   // print("min was \(prev) set to \(postid)")
            }
            
            // now figure max
             if pcc < maxcc {
            } else
            if pcc > maxcc {
                //let prev = self.igp.pd.ouMaxMediaPostID
                self.igp.pd.ouMaxMediaPostID = postid
               // print("ccmax was \(prev) set to \(postid)")
            } else
            {
                if postid > self.igp.pd.ouMaxMediaPostID {
                    
                    //let prev = self.igp.pd.ouMaxMediaPostID
                    self.igp.pd.ouMaxMediaPostID = postid
                    //print("max was \(prev) set to \(postid)")
                }
            }
        }
    }
    //1265366362394672963_275404302
    //995772699961933304_275404302
    func codeWithApiRequestsInBackground() throws  {
        fatalError("must override code() for all NsOps")
        //return nil
    }
    func onward(_ nextOp:NsOp?) {
        if let nsop = nextOp {
            nsop.igp = self.igp
            nsop.subq = self.subq
            nsop.finalWrapUpOp = self.finalWrapUpOp
            nsop.delegate = self.delegate
            //Log.info ("OP moving onward to \(nsop)")
            //MARK: was changed to use subordinate queue
            self.subq.addOperation(nsop)
        } else {
            fatalError("no nextOp")
        }
    }
    func bail (_ errcode:Int, _ s:String) {
        
        finalWrapUpOp!.pipeLineStatus = errcode
        print( "bailing forward ",s)
        return self.onward(finalWrapUpOp!)
    }
    
    internal func  codex( )  {
        // BackOp.aprint("running \(self) code func  here in the background")
        do {
            try
                self.codeWithApiRequestsInBackground()
        }
        catch {
            NsOp.aprint("error \(self) api call here in the background")
        }
    }
    override open func main() -> () {
        // Log.info ("OP now running in  \(self)")
        if self.isCancelled { return }
        //   DO SOMETHING LENGTHY
        self.codex( )
    }
    override init ( ) {
        super.init()
        self.queuePriority = .low
        self.qualityOfService = .userInitiated
    }
}

// MARK:- Handler Type NSOperations Have Optional Delegate
internal class NsHandlerOp: NsOp{
    
    func codeHandlingApiResponses() {
        fatalError("must codeHandlingApiResponses code() for all NsOps")
        //return nil
    }
    override func main() -> () {
        // Log.info ("OP now running handler in  \(self)")
        if self.isCancelled { return }
        //   DO SOMETHING LENGHTHY
        self.codeHandlingApiResponses( )
    }
}



//MARK:- NSOperation Subclasses for Instagram in Order of Request
// all data is passed between different operations thru the igp context


// MARK: - StartingPipelineOp clears pipleline variables and kicks off first operation

class StartingPipelineOp: NsOp {
    
    override func main() -> () {
        
        // make a private subordinate nsoperation q for use by onward
        
        self.finalWrapUpOp = FinalWrapUpOp()
        let t = OperationQueue()
        t.name =   "Queue-\(self.igp.targetID)"
        self.subq = t
        self.igp.pipelineStart = Date()
        // run different first op based on opname
        switch self.opname  {
            
        case "mainpipe" :
            self.igp.rawPosts = [] // reclaim scratch space
            self.igp.rawLikesDict = [:] // reclaim
            self.igp.rawCommentsDict = [:]
            self.igp.pd.ouMediaPosts = []
            self.igp.pd.ouAllFollowers = []
            return self.onward(RelationshipStatusOp( ))
        case "diskpipe" :
            // return self.onward(DiskStartupOp( ))
            // case "updatepipe":
            // intended for use after running the diskpipe
            self.igp.rawPosts = [] // reclaim scratch space
            self.igp.rawLikesDict = [:] // reclaim
            self.igp.rawCommentsDict = [:]
            return self.onward(UpdatePipelineStartupOp( ))
        default:
            fatalError("bad pipeline start name")
        }// switch
    }
}
// MARK: - very final step passes notification to initial calling object at main level
open class FinalWrapUpOp: NsOp   { // no igp hence not NsOp
    
    var pipeLineStatus = 200 // normally fine unless overrwitten by caller in error situation
    var needsSaving =  false // properly needs full write if set by caller
    var notificationNamed : String?
    
    
    override open func main() -> () {
        DispatchQueue.main.async {
            print(" OP FinalWrapUpOp ",self.igp.targetID)
            
        }
        
        // go thru all the posts and build final data structures
        
        self.igp.pipeLineStatus = self.pipeLineStatus
        if self.pipeLineStatus == 200 {
            // reclaim the scratch areas
            self.delegate?.didFinalize(self.igp) // only if still
            
            /// seems unnecessary here, as it is recomputed for each report
            //self.igp.figureLikesAndComments() // would like to optimize??
            do {
               // NsOp.aprint(self.igp.pd.postsStatus())
                try self.igp.pd.savePd(self.igp.pd.ouUserInfo.id)
            }
            catch {
                NsOp.aprint("utterly failed to save context for user \(self.igp.pd.ouUserInfo.id)")
                self.pipeLineStatus = 527 //cant save
            }
        }
        else { print(">>>>>>pipeline failure status \(self.igp.pipeLineStatus)")
        }
        self.igp.rawPostIndex  = -1
        self.igp.rawPosts = [] // reclaim scratch space
        self.igp.rawLikesDict = [:] // reclaim
        self.igp.rawCommentsDict = [:]
        
        //1271171285481298395_1601909741
        //1271173008333609527_1601909741
        // whether a good pipeline status of now
        // now notify completion of the pipeline
        // this is where we pass our igp variable back into the calling view controller
        if let notificationNamed = self.notificationNamed {
            let noti = Notification(name: Notification.Name(rawValue: notificationNamed))
            NotificationCenter.default.post(noti)
        }
        
        self.subq = nil // release this operationq
    } //main
}

/* - update Pipeline Starts Here
 
 use the current context
 
 get new posts - using current maxid
 
 for each post:
 get comments for post
 get likes for post
 
 Do as much of this as possible:
 
 for old posts -
 get comments for post and merge
 get likes for post and merge
 
 user info
 get followers
 get following
 
 */
class UpdatePipelineStartupOp: NsOp {
    // presumably we've already go it in self.igp so just run all the UI callbacks here
    override func codeWithApiRequestsInBackground() throws {
        let nextOp =  OldMediaPostsOp() // AllMediaPostsOp() NewMediaPostsOp()//NewMediaPostsOp()//
        return self.onward(nextOp)
    }
}

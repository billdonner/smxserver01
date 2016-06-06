///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
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
class QForID :NSOperationQueue {
    
  init(_ id:String) {
        super.init()
        self.name = "Queue-\(id)"
    }
}

internal class BackOp: NSOperation {
    
    static func aprint(_ s:String) {
        // dispatch_async(dispatch_get_main_queue()) {
        print(s)
        // }
    }
    func funcThatThrows () throws -> () {
        
        //BackOp.aprint ("running main in \(opname)")
    }
    override func main() -> () {
        if self.isCancelled { return }
        do {
            try funcThatThrows()
        }
        catch {
            print ("BackOp failed in main")
        }
    }
    
    override init ( ) {
        super.init()
        self.queuePriority = .high
        self.qualityOfService = .userInitiated
    }
}
internal class NsOp: BackOp {
    weak  var igp:SocialDataProcessor!
    weak   var finalWrapUpOp: FinalWrapUpOp?
    var delegate:IGDataEngineDelegate?
    var subq: QForID!
    var opname: String = ""
    
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
            BackOp.aprint("error \(self) api call here in the background")
        }
    }
    override func main() -> () {
         // Log.info ("OP now running in  \(self)")
        if self.isCancelled { return }
        //   DO SOMETHING LENGTHY
        self.codex( )
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
        
  // make a subordinate q for use by onward
        
        self.subq = QForID(self.igp.targetID)
        
        self.igp.pipelineStart = NSDate()
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
            
            return self.onward(DiskStartupOp( ))
        default:
            fatalError("bad pipeline start name")
        }// switch
    }
    
}

// MARK: - StartingUpdatePipelineOp  adds additional content

class StartingUpdatePipelineOp: NsOp {
    
    override func main() -> () {
        
        self.subq = QForID(self.igp.targetID)
        
        //dispatch_async(dispatch_get_main_queue()) {
            Log.info(" OP StartingUpdatePipelineOp \(self.igp.targetID)")
       // }
        
        self.igp.rawPosts = [] // reclaim scratch space
        self.igp.rawLikesDict = [:] // reclaim
        self.igp.rawCommentsDict = [:]
        return self.onward(UpdatePipelineStartupOp( ))
    }
    
}
// MARK: - very final step passes notification to initial calling object at main level
class FinalWrapUpOp: NsOp   { // no igp hence not NsOp
    
    var pipeLineStatus = 200 // normally fine unless overrwitten by caller in error situation
    var needsSaving =  false // properly needs full write if set by caller
    var notificationNamed : String?
    
    
    override func main() -> () {
        dispatch_async(dispatch_get_main_queue()) {
            print(" OP FinalWrapUpOp ",self.igp.targetID)
        }
        
        // go thru all the posts and build final data structures
        
        self.igp.pipeLineStatus = self.pipeLineStatus
        if self.pipeLineStatus == 200 {
            // reclaim the scratch areas
            self.delegate?.didFinalize(self.igp) // only if still
            self.igp.figureLikesAndComments() // would like to optimize??
            do {
                try self.igp.pd.savePd(userID:self.igp.pd.ouUserInfo.id)
            }
            catch {
                BackOp.aprint("utterly failed to save context for user \(self.igp.pd.ouUserInfo.id)")
                self.pipeLineStatus = 527 //cant save
            }
        }
        else { print(">>>>>>pipeline failure status \(self.igp.pipeLineStatus)")
        }
        self.igp.rawPostIndex  = -1
        self.igp.rawPosts = [] // reclaim scratch space
        self.igp.rawLikesDict = [:] // reclaim
        self.igp.rawCommentsDict = [:]
        
        // whether a good pipeline status of now
        // now notify completion of the pipeline
        // this is where we pass our igp variable back into the calling view controller
        if let notificationNamed = self.notificationNamed {
            NSNotificationCenter.default().post(name: notificationNamed, object: self)
        }
        
        self.subq = nil // release this operationq
    } //main
}



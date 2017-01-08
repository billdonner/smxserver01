/// provenance - SocialMaxx Server
/// builds on XCode 8.2 standard release on OSX 10.12
/// as of 2 Jan 2017
///

//
//  workersMainServer.swift
//  t3
//
//  Created by william donner on 5/24/16.
//
//


import Kitura
import KituraNet 
import LoggerAPI
import SwiftyJSON
import Foundation

///
// MARK:-  Workers Support
///


/// Workers routes:
///
///  get("/workers/start/:id")
///  get("/workers/stop/:id")

/// This "SeparateServer" is started on its own port via the addHTTPServer Kitura api

class  WorkersMainServer:SeparateServer {

fileprivate var activeWorkers: [String:String] = [:]


    var port:Int16 = 0
    
    init(port:Int16,smaxx:Smaxx) {
        self.port = port
    }
    
    
     func mainPort() -> Int16 {
        return self.port
    }
     func jsonStatus() -> JSONDictionary {
        return ["router-for":"workers","port":port,"active-workers":activeWorkers.count] as [String : Any]
        
        
    }
    
    let pipelineKey = "WorkersrIgPipeline"
    
    var igDataEngine: IGDataEngine!
    
    var apiCallCountInitially = 0
    
    fileprivate func igpipelineStart(_ igp:SocialDataProcessor, targetID:String, targetToken:String) {
        self.igDataEngine = IGDataEngine(forLoggedOnUser:  targetID, targetToken:targetToken, delegate: nil ) // the big IG Machine Structure with UI callbacks
        // this is triky cause the pipeline last op must be the object for the addoserver even though the pipeline isnt even started
        let (firstop,lastop) = self.igDataEngine.setupPipeline (pipelineKey,igp:igp) // returns (future) last op
        NotificationCenter.default.addObserver(self, selector: #selector(WorkersMainServer.igpipelineFinished), name: NSNotification.Name(rawValue: pipelineKey), object: lastop)
        
        self.igDataEngine.startPipeline(firstop)
    }
    
    private  func igpipelineUpdateStart(igp:SocialDataProcessor, targetID:String, targetToken:String ) {
        self.igDataEngine = IGDataEngine(forLoggedOnUser:  targetID, targetToken:targetToken,  delegate: nil ) // the big IG Machine Structure with UI callbacks
        // this is triky cause the pipeline last op must be the object for the addoserver even though the pipeline isnt even started
        let (firstop,lastop) = self.igDataEngine.setupUpdatePipeline (pipelineKey,igp:igp) // returns (future) last op
        //TODO needs to pass argument
        NotificationCenter.default.addObserver(self, selector: #selector(WorkersMainServer.igpipelineFinished), name: NSNotification.Name(rawValue: pipelineKey), object: lastop)
        self.igDataEngine.startPipeline(firstop)
    }
    
    /// comes here when pipeline final notification fires
    
    @objc func igpipelineFinished(not:NSNotification) {
        
        if let op = not.object as? FinalWrapUpOp {  // op.igp is not same as what we started with
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: self.pipelineKey), object: op)
            
            // pick final status out of the igp
            let errcode = op.igp.pipeLineStatus
            
            Log.info ("************ Worker \(op.igp.targetID) igpipelineFinished \(errcode) **************")
            //self.removeProgressIndicator()
            if errcode == 200 {
                op.igp.pd.ouTotalApiCalls +=  (IGOps.apiCount -
                    self.apiCallCountInitially)
                
                //self.runningNicely = true // now prohibit destruction o our saved context
                // show we are done at UI
                print(op.igp.pd.summarize())
                
            } else
                if errcode == 429 {
                    Log.error("Exhausted Instagram API Quota error:\(errcode) - can retry in 1 hr")
                }
                else   {
                    Log.error("Instagram API Pipeline error:\(errcode)")
            }
            ///when finished in every circumstance make the worker idle again
            stopcold(id: op.igp.targetID)
        }// pipelinestatu
    }
    
    func make_worker_for(id:String,token:String) {
        let igp =  SocialDataProcessor(id:id,token:token) // get fresh space from outside
        igpipelineStart(igp, targetID:id, targetToken:token)
        
        activeWorkers[id] = id //keep trak - could fill with anything
    }
    
    func start(_ id: String , _ request:RouterRequest , _ response:RouterResponse) {
        MembersCache.isMember(id) { ismemb in
            
            guard ismemb else {
                AppResponses.rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Bad id \(id) passed into SocialDataProcessor stop")
                return
            }        // ensure not active
        if let _ =  self.activeWorkers[id]  {
            AppResponses.rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Worker id \(id) is already active")
            return
        }
        // member must have access token for instagram api access
       MembersCache.getTokenFromID(id: id) { token in
        guard let token = token   else {
                AppResponses.rejectduetobadrequest(response,status:SMaxxResponseCode.noToken.rawValue,mess:"Worker id \(id) has no access token")
            return
            }
        self.make_worker_for(id: id, token: token)
            //rejectduetobadrequest(response,status:200,mess:"Worker id \(id) was started")
            let item : JSONDictionary = ["status":SMaxxResponseCode.success ,"workid":id as AnyObject,"workerid":"001" , "newstate": "started" ]
           try? AppResponses.sendgooresponse(response,item )
        }
      
        }
    }
    private func stopcold(id:String) {
        
        activeWorkers.removeValue(forKey: id)
    }
    func stop(_ id: String, _ request:RouterRequest , _ response:RouterResponse) {
    
        
        MembersCache.isMember(id) { ismemb in
            
            guard ismemb else {
                AppResponses.rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Bad id \(id) passed into SocialDataProcessor stop")
                return
            }
        // ensure  active
        guard let _ =  self.activeWorkers[id] else {
            AppResponses.rejectduetobadrequest(response,status:SMaxxResponseCode.workerNotActive.rawValue,mess:"Worker id \(id) not  active")
            return
        }
        
        //send a good response and remove from table
        
        //TODO: really kill the task
        
        let item :JSONDictionary = ["status":SMaxxResponseCode.success  , "workid":id  ,"workerid":"001"  , "newstate": "idle"  ]
        
        try? AppResponses.sendgooresponse(response,item )
        self.stopcold(id: id)
        
    }
    }
}

extension Router{
    
    func setupRoutesForWorkers( mainServer:WorkersMainServer,smaxx:Smaxx) {
        
        // must support MainServer protocol
        
        //let port = mainServer.mainPort()
       // print("*** setting up Workers on port \(port) ***")
        self.get("/status") {
            request, response, next in
            
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            do {
                try response.status(HTTPStatusCode.OK).send(JSON(mainServer.jsonStatus()).description).end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
            //next()
        }
        
        
        
        ///
        // MARK:- Workers list
        ///
        ///
        //TODO:self.post("/workers/:parameter-fields") {
        
        self.get("/workers/start/:id") {
            request, response, next in
            guard let id = request.parameters["id"]
                else {  response.status(HTTPStatusCode.badRequest)
                    
                    Log.error("Request does not contain ID")
                    return
            }
           workersMainServer.start(id,request, response)
            //next()
        }
        
        
        self.get("/workers/stop/:id") {
            request, response, next in
            guard let id = request.parameters["id"] else { response.status(HTTPStatusCode.badRequest)
                
                Log.error("Request does not contain ID")
                
                return
         
        }
      workersMainServer.stop(id,request, response)
        //next()
    }
}
}
protocol IGDataEngineDelegate {
    func didProcessRelationshipStatus(_ igp: SocialDataProcessor,loggedInUser:Bool)
    func didProcessAllFollowers(_ igp:SocialDataProcessor)
    func didProcessAllPosts(_ igp:SocialDataProcessor)
    func didProcessUserInfo (_ igp :SocialDataProcessor)
    func didFinalize (_ igp :SocialDataProcessor)
    func tellUserAboutError(_ errcode:Int,msg:String,prompt:String,title:String)
}
extension IGDataEngineDelegate {
    func didProcessRelationshipStatus(_ igp: SocialDataProcessor,loggedInUser:Bool) {}
    func didProcessAllFollowers(_ igp:SocialDataProcessor) {}
    func didProcessAllPosts(_ igp:SocialDataProcessor) {}
    func didProcessUserInfo (_ igp :SocialDataProcessor) {}
    func didFinalize (_ igp :SocialDataProcessor) {}
    func tellUserAboutError(_ errcode:Int,msg:String,prompt:String,title:String) {}
}

// MARK: - The Pipeline is a Long Running Sequence of Specialty NSOperations
private class IGBackgroundLoadingPipeline {
    fileprivate var callingVC: IGDataEngineDelegate?
    fileprivate var notifKey: String?
    fileprivate var finalWrapUpOp : FinalWrapUpOp?
    
    
}

fileprivate struct  IGDataEngine {
    // MARK: - Components that are UI free
    fileprivate var targetUserID: String
    fileprivate var targetToken: String
    fileprivate var igData:SocialDataProcessor
    fileprivate var delegate: IGDataEngineDelegate?
    fileprivate var notifKey  : String?
    
    fileprivate var igBackgroundLoadingPipeline : IGBackgroundLoadingPipeline
    
    fileprivate var startTime : Date?
    
    
    fileprivate var operationQueue: OperationQueue! // just one queue for now
    
    
    
    init(forLoggedOnUser:String, targetToken:String, delegate:IGDataEngineDelegate?) {
        self.targetUserID = forLoggedOnUser
        self.targetToken = targetToken
        self.igData = SocialDataProcessor(id:forLoggedOnUser,token:targetToken) // placeholder, better be overwritten in setuppipeline
        self.igBackgroundLoadingPipeline = IGBackgroundLoadingPipeline()
        
        operationQueue =  OperationQueue()
        operationQueue.name = "InstagramOperationsQueue"   /// does not work with .main()
        operationQueue.maxConcurrentOperationCount = 3
        
        self.delegate = delegate
    }
    
    func checkapierr(_ errcode:Int) {
        guard errcode == 200  else {
            // removed from server version -= FS.removeUserData(self.targetUserID)
            // do something
            if errcode == 400 || errcode == 403 {
                //in this case we can live to fight another day
                print ("-setupPipeline  error \(errcode) from fullStartup")
                self.delegate?.tellUserAboutError(
                    errcode, msg: "Privacy error in full startup",
                    prompt:"Can not get personal info from Instagram for this user errcode = \(errcode)",
                    title:"You have no access to this user")
                return
            }
            fatalError("-- YIKES error \(errcode) from fullStartup, please contact your vendor")
        }
    }
    fileprivate       func  loadupForBackgroundOperation( _ pipelineNamed:String , notifKey:String? , igp:SocialDataProcessor, delegate: IGDataEngineDelegate? ) -> (NsOp,FinalWrapUpOp) {
        
        func startLoadingPipeline(pipelineNamed named:String , notifKey:String? ,igp: SocialDataProcessor) -> (StartingPipelineOp?,FinalWrapUpOp? ){
            // no concurrency for now, each pipeline is a single threaded sequence of api calls
            //self.notifKey = notifKey
            // make this now and return it to caller
            let finalWrapUpOp = FinalWrapUpOp( )
            finalWrapUpOp.notificationNamed  = notifKey // setup name of NSNotification
            
            // this should kick off the pipeline
            let o1 = StartingPipelineOp( )
            o1.opname = pipelineNamed
            o1.igp = igp //amen
            o1.finalWrapUpOp = finalWrapUpOp
            o1.delegate = delegate
            return (o1, finalWrapUpOp)
            
        }
        NsOp.aprint ("* starting background api pipeline for \(pipelineNamed)")
        //self.callingVC = delegate
        let (start,final) = startLoadingPipeline(pipelineNamed: pipelineNamed, notifKey: notifKey, igp: igp)
        guard start != nil && final != nil else {
            fatalError("bad pipeline start and finish")
        }
        if let first = start {
            first.opname = pipelineNamed
        }
        return (start!,final!) // and return the ultimate final block
    }
    
    func startPipeline(_ firstOp:Operation) {
        //print("* starting Pipeline with  \(firstOp) added to operation Q")
        self.operationQueue.addOperation(firstOp) // this kicks it off
    }
    mutating public func setupPipeline (_ notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = Date()
        let l : (NsOp,FinalWrapUpOp)
        do {
            
            print("* will restore from disk for  user \(self.targetUserID) data...")
            let pd = try  MembershipDB.restoreme(self.targetUserID)
            // if restore fails we go down to the catch
            self.igData.pd = pd
            self.targetUserID = self.igData.targetID            // start pipeline after good restore from disk
            print("* pulling from disk for user \(self.targetUserID) schema version is \(igp.pd.ouVersion!) ... ")
            l  = loadupForBackgroundOperation("diskpipe",notifKey: notifKey,  igp: igp, delegate: self.delegate)
            
            
        }
        catch (_)  {
            // start pipeline to interact with Instagram
            print("* could not restore from disk - contacting Instagram for new user \(self.targetUserID) data...")
            l  =  loadupForBackgroundOperation("mainpipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
            
        }// end of catch
        
        //
        return l
    }//pull sR
    mutating public func setupUpdatePipeline (_ notifKey: String,igp:SocialDataProcessor ) -> (NsOp,FinalWrapUpOp) {
        // load user data
        self.igData = igp
        self.startTime = Date()
        let l : (NsOp,FinalWrapUpOp)
        print("*** setupUpdatePipeline periodic update")
        // start pipeline to interact with Instagram
        l  =  loadupForBackgroundOperation("updatepipe", notifKey: notifKey, igp: igp, delegate: self.delegate)
        return l
    }//pull sR
}

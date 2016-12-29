///  provenance - SocialMaxx Server
///  builds on DEVELOPMENT-SNAPSHOT-2016-05-03-a on OS X 10.11.4  Xcode Version 7.3.1 (7D1014)
///  26 May 2016
///

//
//  Workers.swift
//  t3
//
//  Created by william donner on 5/24/16.
//
//


import Kitura
import KituraNet
//import KituraSys
import LoggerAPI
import SwiftyJSON
import Foundation


open class Workers:NSObject {
/// log error and reply with bad status to user
func rejectduetobadrequest(_ response:RouterResponse,status:Int,mess:String?=nil) {
    do {
        let rqst = (mess != nil) ?   " \(status) -- \(mess!)" : "\(status)"
        Log.error("badrequest \(rqst)")
        let item:JSONDictionary = mess != nil ? ["status":status as AnyObject,"description":mess! as AnyObject] as JSONDictionary :  ["status":status as AnyObject] as JSONDictionary
        let r = response.status(HTTPStatusCode.badRequest)
        let _ =   try r.send(JSON(item).description).end()
        
    }
    catch {
        Log.error("Could not send rejectduetobadrequest ")
    }
}
func acceptgoodrequest(_ response:RouterResponse,item:JSONDictionary) {
    do {
        
        //let nitem:[String:AnyObject] = item // mess != nil ? item + (["description":mess!] as [String:AnyObject]) :  item
        let r = response.status(HTTPStatusCode.OK)
        let _ =   try r.send(JSON(item).description ).end()
        //Log.error("Did send acceptgoodrequest")
        
    }
    catch {
        Log.error("Could not send acceptgoodrequest")
    }
}
    
    let pipelineKey = "WorkersrIgPipeline"
    
    var activeWorkers: [String:String] = [:]
    
    var igDataEngine: IGDataEngine!
    
    var apiCallCountInitially = 0
    
    fileprivate func igpipelineStart(_ igp:SocialDataProcessor, targetID:String, targetToken:String) {
        self.igDataEngine = IGDataEngine(forLoggedOnUser:  targetID, targetToken:targetToken, delegate: nil ) // the big IG Machine Structure with UI callbacks
        // this is triky cause the pipeline last op must be the object for the addoserver even though the pipeline isnt even started
        let (firstop,lastop) = self.igDataEngine.setupPipeline (pipelineKey,igp:igp) // returns (future) last op
        NotificationCenter.default.addObserver(self, selector: #selector(Workers.igpipelineFinished), name: NSNotification.Name(rawValue: pipelineKey), object: lastop)
 
        self.igDataEngine.startPipeline(firstop)
    }
    
    private  func igpipelineUpdateStart(igp:SocialDataProcessor, targetID:String, targetToken:String ) {
        self.igDataEngine = IGDataEngine(forLoggedOnUser:  targetID, targetToken:targetToken,  delegate: nil ) // the big IG Machine Structure with UI callbacks
        // this is triky cause the pipeline last op must be the object for the addoserver even though the pipeline isnt even started
        let (firstop,lastop) = self.igDataEngine.setupUpdatePipeline (pipelineKey,igp:igp) // returns (future) last op
        //TODO needs to pass argument
        NotificationCenter.default.addObserver(self, selector: #selector(Workers.igpipelineFinished), name: NSNotification.Name(rawValue: pipelineKey), object: lastop)
        self.igDataEngine.startPipeline(firstop)
    }
    
    /// comes here when pipeline final notification fires
    
    func igpipelineFinished(not:NSNotification) {
        
        if let op = not.object as? FinalWrapUpOp {  // op.igp is not same as what we started with
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: self.pipelineKey), object: op)
                
                // pick final status out of the igp
                let errcode = op.igp.pipeLineStatus
                
                Log.info ("************ Worker \(op.igp.targetID) igpipelineFinished \(errcode) **************")
                //self.removeProgressIndicator()
                if errcode == 200 {
                    op.igp.pd.ouTotalApiCount +=  (Sm.axx.igApiCallCount -
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
        guard true == Membership.isMember(id) else {
            rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Bad id \(id) passed into SocialDataProcessor start")
            return
        }
        // ensure not active
        if let _ =  activeWorkers[id]  {
            rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Worker id \(id) is already active")
            return
        }
        // member must have access token for instagram api access
        if    let token = Membership.getTokenFromID(id: id) {
            make_worker_for(id: id, token: token)
            //rejectduetobadrequest(response,status:200,mess:"Worker id \(id) was started")
            let item : JSONDictionary = ["status":SMaxxResponseCode.success  as AnyObject,"workid":id as AnyObject,"workerid":"001" as AnyObject, "newstate": "started" as AnyObject ]
            acceptgoodrequest(response,item:item )
        }
        else {
            rejectduetobadrequest(response,status:SMaxxResponseCode.noToken.rawValue,mess:"Worker id \(id) has no access token")
        }
        
    }
    func stopcold(id:String) {
        
        activeWorkers.removeValue(forKey: id)
    }
    func stop(_ id: String, _ request:RouterRequest , _ response:RouterResponse) {
        guard true == Membership.isMember(id) else {
            rejectduetobadrequest(response,status:SMaxxResponseCode.badMemberID.rawValue,mess:"Bad id \(id) passed into SocialDataProcessor stop")
            return
        }
        // ensure  active
        guard let _ =  activeWorkers[id] else {
            rejectduetobadrequest(response,status:SMaxxResponseCode.workerNotActive.rawValue,mess:"Worker id \(id) not  active")
            return
        }
        
        //send a good response and remove from table
        
        //TODO: really kill the task
        
        let item :JSONDictionary = ["status":SMaxxResponseCode.success as AnyObject, "workid":id as AnyObject,"workerid":"001" as AnyObject, "newstate": "idle" as AnyObject  ]
        
        acceptgoodrequest(response,item:item )
        stopcold(id: id)
        
    }
}

extension SMaxxRouter{

    class func setupRoutesForWorkers(router: Router ) {
        
        ///
        // MARK:- Workers list
        ///
        router.get("/workers/start/:id") {
            request, response, next in
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response) }
            Sm.axx.workers.start(id,request, response)
            //next()
        }
        router.get("/workers/stop/:id") {
            request, response, next in
            guard let id = request.parameters["id"] else { return RestSupport.missingID(response) }
            Sm.axx.workers.stop(id,request, response)
            //next()
        }
}
}

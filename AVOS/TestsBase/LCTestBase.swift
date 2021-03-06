//
//  LCTestBase.swift
//  AVOS
//
//  Created by ZapCannon87 on 11/12/2017.
//  Copyright © 2017 LeanCloud Inc. All rights reserved.
//

import XCTest

class LCTestBase: XCTestCase {
    
    enum TestApp {
        case CN_North
        case CN_East
        case US
        var appInfo: (id: String, key: String) {
            switch self {
            case .CN_North: return (id: "S5vDI3IeCk1NLLiM1aFg3262-gzGzoHsz", key: "7g5pPsI55piz2PRLPWK5MPz0")
            case .CN_East: return (id: "uwWkfssEBRtrxVpQWEnFtqfr-9Nh9j0Va", key: "9OaLpoW21lIQtRYzJya4WHUR")
            case .US: return (id: "eX7urCufwLd6X5mHxt7V12nL-MdYXbMMI", key: "PrmzHPnRXjXezS54KryuHMG6")
            }
        }
    }
    
    static var shared: Int = {
        
        LCRouter.sharedInstance().cleanCache(forKey: "LCAppRouterCacheKey")
        LCRouter.sharedInstance().cleanCache(forKey: "LCRTMRouterCacheKey")
        
        let env: LCTestEnvironment = LCTestEnvironment.sharedInstance()
        
        /// set region
        if let region: String = env.app_REGION {
            switch region {
            case "us": AVOSCloud.setServiceRegion(.US)
            case "cn": AVOSCloud.setServiceRegion(.CN)
            default: AVOSCloud.setServiceRegion(.CN)
            }
        } else {
            AVOSCloud.setServiceRegion(.CN)
        }
        
        /// set url for API & RTM
        if let URL_API: String = env.url_API {
            AVOSCloud.setServerURLString(URL_API, for: .API)
        }
        if let URL_RTM: String = env.url_RTM {
            AVOSCloud.setServerURLString(URL_RTM, for: .RTM)
        }
        
        /// set app id & key
        if let appId: String = env.app_ID, let appKey: String = env.app_KEY {
            AVOSCloud.setApplicationId(appId, clientKey: appKey)
        } else {
            let testRegion: TestApp = .CN_North
            AVOSCloud.setApplicationId(testRegion.appInfo.id, clientKey: testRegion.appInfo.key)
        }
        
        AVOSCloud.setAllLogsEnabled(true)
        
        return 0
    }()
    
    override class func setUp() {
        super.setUp()
        let _ = LCTestBase.shared
    }
    
}

class RunLoopSemaphore {
    
    private var lock: NSLock = NSLock()
    var semaphoreValue: Int = 0
    
    func increment(_ number: Int = 1) {
        assert(number > 0)
        self.lock.lock()
        self.semaphoreValue += number
        self.lock.unlock()
    }
    
    func decrement(_ number: Int = 1) {
        assert(number > 0)
        self.lock.lock()
        self.semaphoreValue -= number
        self.lock.unlock()
    }
    
    private func running() -> Bool {
        return (self.semaphoreValue > 0) ? true : false
    }
    
    static func wait(timeout: TimeInterval = 30, async: (RunLoopSemaphore) -> Void, failure: (() -> Void)? = nil) {
        XCTAssertTrue(timeout > 0)
        defer {
            XCTAssertTrue(RunLoop.current.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 1.0)))
        }
        let semaphore: RunLoopSemaphore = RunLoopSemaphore()
        async(semaphore)
        let startTimestamp: TimeInterval = Date().timeIntervalSince1970
        while semaphore.running() {
            let date: Date = Date(timeIntervalSinceNow: 1.0)
            XCTAssertTrue(RunLoop.current.run(mode: .defaultRunLoopMode, before: date))
            if date.timeIntervalSince1970 - startTimestamp > timeout {
                failure?()
                return
            }
        }
    }
    
}

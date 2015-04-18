//
//  HEAnalyticsPlatformFlurry.swift
//
//  Created by hsoi on 4/4/15.
//
//  HEAnalytics - Copyright (c) 2015, Hsoi Enterprises LLC
//  All rights reserved.
//  hsoi@hsoienterprises.com
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  * Neither the name of HEAnalytics nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import UIKit

class HEAnalyticsPlatformFlurry: HEAnalyticsPlatform {
   
    override init() {
        super.init()
    }
    
    override internal var platformKey: String {
        return "Flurry"
    }
    
    
    override func initializePlatform() {
        let configDict = self.loadPlatformConfig()

        if let logLevel = configDict["logLevel"] as? UInt {
            let levelAsUInt32 = UInt32(logLevel)
            Flurry.setLogLevel(FlurryLogLevel(levelAsUInt32))
        }
        else {
        #if DEBUG
            Flurry.setLogLevel(FlurryLogLevelDebug)
        #else
            Flurry.setLogLevel(FlurryLogLevelCriticalOnly)
        #endif
        }

        Flurry.setSessionReportsOnCloseEnabled(true)
        Flurry.setSessionReportsOnPauseEnabled(true)

        // Hsoi 2015-04-04 - Flurry uses the CFBUndleVersion to report versions. I tend to like using the
        // CFBundleShortVersionString for marketing version (e.g. "major.minor.bugfix") and the CFBundleVersion
        // for a simple incrementing build integer/number. So we'll make our own version number here to
        // force into Flurry so I can know exactly what I'm working with.
        let infoDict = NSBundle.mainBundle().infoDictionary!
        let shortVersion = infoDict["CFBundleShortVersionString"] as String
        let bundleVersion = infoDict["CFBundleVersion"] as String
        let flurryVersion = shortVersion + "." + bundleVersion
        Flurry.setAppVersion(flurryVersion)

        let apiKey = configDict["apiKey"] as String
        Flurry.startSession(apiKey)

        super.initializePlatform()
    }
    
    
    override var optOut: Bool {
        didSet {
            Flurry.setEventLoggingEnabled(!self.optOut)
        }
    }
    
    
    override func start() {
        if !self.optOut {
            super.start()
            Flurry.setEventLoggingEnabled(true)
        }
    }
    
    
    override func stop() {
        super.stop()
        Flurry.setEventLoggingEnabled(false)
    }

    
    override func trackData(data: HEAnalyticsData) {
        if self.optOut {
            return
        }

        let flurryEvent = data.category + " - " + data.event
        if data.parameters != nil {
            assert(data.parameters!.count <= 10, "Flurry SDK accepts at most 10 parameters per event")
            
            Flurry.logEvent(flurryEvent, withParameters: data.parameters!)
        }
        else {
            Flurry.logEvent(flurryEvent)
        }
    }
    
    
    override func trackView(viewController: UIViewController) {
        if self.optOut {
            return
        }

        // Hsoi 2015-04-11 - Flurry doesn't really have a good way to do view tracking. It does have
        // a way to log pageviews, but it's really just a count tracker and doesn't help us really know
        // what views users are viewing, how they navigate in and out of them, etc.. As I look for a
        // solution to this, it seems both Flurry and others say to do what we want to do, we should just
        // logEvent. So, here we are.

        let title = self.viewControlerTitle(viewController)
        let flurryEvent = "TrackView - " + title
        Flurry.logEvent(flurryEvent)
    }

}


//
//  VersionCheck.m
//  Clip
//
//  Created by Brandon Roth on 8/28/14.
//  Copyright (c) 2014 Rocketmade LLC. All rights reserved.
//

#import "RMAppStoreVersionCheck.h"
#import "RMAppVersionInformation.h"
#import <SystemConfiguration/SystemConfiguration.h>

NSString *const kItunesHostname = @"itunes.apple.com";

@interface RMAppStoreVersionCheck()

@property (copy, nonatomic) NSString *bundleID;
@property (copy, nonatomic) NSString *lookupURL;
@property (assign, nonatomic) SCNetworkReachabilityRef reachability;
@property (copy, nonatomic) appStoreCheckCallbackBlock completionBlock;

- (void)reachabilityEstablished;

@end

static void ReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void* info) {
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [RMAppStoreVersionCheck class]], @"info was wrong class in ReachabilityCallback");
    
    RMAppStoreVersionCheck* infoObject = (__bridge RMAppStoreVersionCheck *)info;
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    if (isReachable) {
        [infoObject reachabilityEstablished];
    }
}

@implementation RMAppStoreVersionCheck

#pragma mark - Entry points

- (void)checkAppStoreVersion:(appStoreCheckCallbackBlock)completion {
    [self checkAppStoreVersionForBundleID:[[NSBundle mainBundle] bundleIdentifier] completion:completion];
}

- (void)checkAppStoreVersionForBundleID:(NSString *)bundleID completion:(appStoreCheckCallbackBlock)completion {
    @try {
        NSParameterAssert(bundleID);
        self.bundleID = bundleID;
        self.completionBlock = completion;
        if (![self startReachability]) {
            NSError *error = [NSError errorWithDomain:@"com.rocketmade.VersionCheck" code:VersionCheckFailureItunesNotAvailble userInfo:@{NSLocalizedDescriptionKey: @"Failed to start reachability for iTunes"}];
            if (self.completionBlock) {
                @try {
                    completion(nil, error);
                }
                @catch (NSException *exception) {
                    
                }
                @finally {
                    
                }
                
            }
            self.completionBlock = nil;
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
}

- (void)checkAppStoreVersionForLookupURL: (NSString *)lookupURL completion:(appStoreCheckCallbackBlock)completion {
    @try {
        NSParameterAssert(lookupURL);
        self.lookupURL = lookupURL;
        self.completionBlock = completion;
        if (![self startReachability]) {
            NSError *error = [NSError errorWithDomain:@"com.rocketmade.VersionCheck" code:VersionCheckFailureItunesNotAvailble userInfo:@{NSLocalizedDescriptionKey: @"Failed to start reachability for iTunes"}];
            if (self.completionBlock) {
                @try {
                    completion(nil, error);
                }
                @catch (NSException *exception) {
                    
                }
                @finally {
                    
                }
                
            }
            self.completionBlock = nil;
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
}

#pragma mark - version check

- (void)appStoreCheck {
    //    assert(self.bundleID);
    
    //for test new versions without waiting for Apple, I changed the url to a custom one on my server containing a json file similar to the one returned by Apple
    NSString *urlString;
    @try {
        if (self.bundleID) {
            urlString = [@"https://itunes.apple.com/lookup?bundleId=" stringByAppendingString:self.bundleID];
        }else if (self.lookupURL) {
            urlString = self.lookupURL;
            self.bundleID = [[NSBundle mainBundle] bundleIdentifier];
        } else{
            urlString = [@"https://itunes.apple.com/lookup?bundleId=" stringByAppendingString:[[NSBundle mainBundle] bundleIdentifier]];
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            RMAppVersionInformation *version;
            NSError *error = connectionError;
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                NSString *appStoreVersion = [self versionFromResultsJSON:json[@"results"]];
                NSString *releaseNotes = [self releaseNotesFromResults:json[@"results"]];
                
                if (!appStoreVersion) {
                    error = [NSError errorWithDomain:@"com.rocketmade.VersionCheck" code:VersionCheckFailureMissingResponseData userInfo:@{NSLocalizedDescriptionKey : @"version key or bundle id not found in itunes response"}];
                }
                version = [[RMAppVersionInformation alloc] initWithAppStoreVersion:appStoreVersion andReleaseNotes:releaseNotes];
            }
            
            if (self.completionBlock) {
                self.completionBlock(version, error);
            }
            self.completionBlock = nil;
        }];
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
}

- (NSString *)versionFromResultsJSON:(NSArray *)JSON {
    for (NSDictionary *result in JSON) {
        NSString *resultBundleID = result[@"bundleId"];
        assert(self.bundleID);
        if ([resultBundleID isEqualToString:self.bundleID]) {
            return result[@"version"];
        }
    }
    return nil;
}

- (NSString *)releaseNotesFromResults:(NSArray *)JSON {
    for (NSDictionary *result in JSON) {
        NSString *resultBundleID = result[@"bundleId"];
        assert(self.bundleID);
        if ([resultBundleID isEqualToString:self.bundleID]) {
            return result[@"releaseNotes"];
        }
    }
    return nil;
}



#pragma mark - Reachability code

- (BOOL)startReachability {
    if (!self.reachability) {
        self.reachability = SCNetworkReachabilityCreateWithName(NULL, [kItunesHostname UTF8String]);
    }
    
    BOOL returnValue = NO;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    if (SCNetworkReachabilitySetCallback(self.reachability, ReachabilityCallback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(self.reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            returnValue = YES;
        }
    }
    return returnValue;
}

- (void)reachabilityEstablished {
    [self removeReachabilityFromRunLoop];
    [self appStoreCheck];
}

#pragma mark - lifecycle

- (void)removeReachabilityFromRunLoop
{
    if (self.reachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(self.reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void)dealloc {
    [self removeReachabilityFromRunLoop];
    CFRelease(self.reachability);
    self.reachability = nil;
}

@end

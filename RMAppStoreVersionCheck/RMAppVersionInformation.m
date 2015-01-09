//
//  AppVersionInformation.m
//  Clip
//
//  Created by Brandon Roth on 9/4/14.
//  Copyright (c) 2014 Rocketmade LLC. All rights reserved.
//

#import "RMAppVersionInformation.h"

NSString *const kUserDefaultsVersionCheckKey = @"versionCheck";

@implementation RMAppVersionInformation

- (instancetype)initWithAppStoreVersion:(NSString *)appStoreVersion andReleaseNotes:(NSString *)releaseNotes {
    if (!appStoreVersion) {
        return nil;
    }
    
    if (self = [super init]) {
        _appStoreVersion = appStoreVersion;
        _releaseNotes = releaseNotes;
        @try {
            NSMutableDictionary *knownVersions = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsVersionCheckKey]];
            if (!knownVersions) knownVersions = [NSMutableDictionary dictionary];
            
            _appStoreVersionDiscoveryDate = knownVersions[appStoreVersion];
            
            if (!_appStoreVersionDiscoveryDate) {
                _appStoreVersionDiscoveryDate = [NSDate date];
                knownVersions[appStoreVersion] = _appStoreVersionDiscoveryDate;
                [[NSUserDefaults standardUserDefaults] setObject:knownVersions forKey:kUserDefaultsVersionCheckKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                _isNewDiscovery = YES;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
            return nil;
        }
        @finally {
            
        }
        
    }
    return self;
}

- (NSString *)currentVersion {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

- (BOOL)newVersionAvailable {
    
    
    
    @try {
        NSArray *appStoreVersionStrings = [self.appStoreVersion componentsSeparatedByString:@"."];
        NSArray *currentVersionStrings = [self.currentVersion componentsSeparatedByString:@"."];
        if (self.appStoreVersion == self.currentVersion) {
            return  NO;
        }
        
        int smallerCount = appStoreVersionStrings.count;
        if (smallerCount > currentVersionStrings.count) {
            smallerCount = currentVersionStrings.count;
        }
        for (int i = 0; i<smallerCount; i++) {
            NSInteger a = [appStoreVersionStrings[i] integerValue];
            NSInteger b = [currentVersionStrings[i] integerValue];
            NSLog(@"compare %zd > %zd", a, b);
            if (a > b) {
                NSLog(@"new version available");
                return YES;
            } else if(a < b){
                return NO;
            }
        }
        
        return NO;
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    return NO;
    
    
    //    NSComparisonResult comparision = [self.appStoreVersion compare:self.currentVersion];
    //    NSLog(@"COMPARISON: %d", comparision);
    //    if (comparision == NSOrderedAscending) {
    //        NSLog(@"ascending");
    //        return NO;
    //    } else if (comparision == NSOrderedDescending){
    //        NSLog(@"descending");
    //        return YES;
    //    }
    //    return NO;
}

- (NSString *)description {
    NSString *desc = [super description];
    return [NSString stringWithFormat:@"%@, CurrentVersion: %@, AppStoreVersion: %@",desc,self.currentVersion, self.appStoreVersion];
}

@end
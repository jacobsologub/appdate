/*
  ==============================================================================
   
   Copyright (C) 2012 Jacob Sologub
   
   Permission is hereby granted, free of charge, to any person obtaining a copy of
   this software and associated documentation files (the "Software"), to deal in
   the Software without restriction, including without limitation the rights to
   use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
   of the Software, and to permit persons to whom the Software is furnished to do
   so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
  
  ==============================================================================
*/

#import "Appdate.h"

const NSString* const kAppdateUrl = @"http://itunes.apple.com/lookup";

@interface Appdate (Private)
- (NSComparisonResult) compareVersions: (NSString*) version1 version2: (NSString*) version2;
@end

@implementation Appdate : NSObject

@synthesize delegate;

#pragma mark -
#pragma mark Object Lifecycle
//==============================================================================
- (id) init {
    return [self initWithAppleId: -1];
}

- (id) initWithAppleId: (int) appleIdToUse {
    if ((self = [super init]) != nil) {
        NSAssert (appleIdToUse != -1, @"The Apple ID has to be valid.");
        appleId = appleIdToUse;
        
       #if NS_BLOCKS_AVAILABLE
        completionBlock = nil;
       #endif
    }
    
    return self;
}

+ (Appdate*) appdateWithAppleId: (int) appleIdToUse {
    return [[[Appdate alloc] initWithAppleId: appleIdToUse] autorelease];
}

- (void) dealloc {
   #if NS_BLOCKS_AVAILABLE
    Block_release (completionBlock), completionBlock = nil;
   #endif
    
    delegate = nil;
    [super dealloc];
}

- (NSComparisonResult) compareVersions: (NSString*) version1 version2: (NSString*) version2 {
    NSComparisonResult result = NSOrderedSame;
    
    NSMutableArray* a = (NSMutableArray*) [version1 componentsSeparatedByString: @"."];
    NSMutableArray* b = (NSMutableArray*) [version2 componentsSeparatedByString: @"."];
    
    while (a.count < b.count) { [a addObject: @"0"]; }
    while (b.count < a.count) { [b addObject: @"0"]; }
    
    for (int i = 0; i < a.count; ++i) {
        if ([[a objectAtIndex: i] integerValue] < [[b objectAtIndex: i] integerValue]) {
            result = NSOrderedAscending;
            break;
        }
        else if ([[b objectAtIndex: i] integerValue] < [[a objectAtIndex: i] integerValue]) {
            result = NSOrderedDescending;
            break;
        }
    }
    
    return result;
}

#pragma mark -
#pragma mark Check Method(s)
//==============================================================================
- (void) checkNow {
    NSURL* url = [NSURL URLWithString: [NSString stringWithFormat: @"%@?id=%d", kAppdateUrl, appleId]];
    if ([NSURLConnection connectionWithRequest: [NSURLRequest requestWithURL: url] delegate: self] == nil) {
        NSDictionary* info = [NSDictionary dictionaryWithObject: @"A connection can't be created." forKey: @"message"];
        NSError* error = [NSError errorWithDomain: @"NSURLErrorDomain" code: -1 userInfo: info];
        
        if ([delegate respondsToSelector: @selector (appdateFailed:)]) {
            [delegate appdateFailed: [NSError errorWithDomain: @"NSURLErrorDomain" code: -1 userInfo: info]];
        }
        
       #if NS_BLOCKS_AVAILABLE
        if (completionBlock != nil) {
            completionBlock (error, nil, NO);
            Block_release (completionBlock), completionBlock = nil;
        }
       #endif
    }
    else {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
}

#if NS_BLOCKS_AVAILABLE
- (void) checkNowWithBlock: (AppdateCompletionBlock) block {
    if (completionBlock != nil) {
        Block_release (completionBlock);
        completionBlock = nil;
    }
    
    if (block != nil) {
        completionBlock = Block_copy (block);
        [self checkNow];
    }
}
#endif

#pragma mark -
#pragma mark NSURLConnection Delegate
//==============================================================================
- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data {
    NSError* error = nil;
    NSDictionary* object = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableLeaves error: &error];
    if (error != nil) {
        if ([delegate respondsToSelector: @selector (appdateFailed:)]) {
            [delegate appdateFailed: error];
        }
        
        #if NS_BLOCKS_AVAILABLE
        if (completionBlock != nil) {
            completionBlock (error, nil, NO);
            Block_release (completionBlock), completionBlock = nil;
        }
       #endif
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        return;
    }
    
    NSArray* results = [object objectForKey: @"results"];
    if (results.count > 0) {
        NSDictionary* jsonData = [results objectAtIndex: 0];
        
        NSString* thisVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString*) kCFBundleVersionKey];
        NSString* thatVersion = [jsonData objectForKey: @"version"];
        
        BOOL hasUpdate = [self compareVersions: thisVersion version2: thatVersion] == NSOrderedAscending;
        
        if ([delegate respondsToSelector: @selector (appdateComplete:updateAvailable:)]) {
            [delegate appdateComplete: jsonData updateAvailable: hasUpdate];
        }
        
       #if NS_BLOCKS_AVAILABLE
        if (completionBlock != nil) {
            completionBlock (nil, jsonData, hasUpdate);
            Block_release (completionBlock), completionBlock = nil;
        }
       #endif
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void) connection: (NSURLConnection*) connection didFailWithError: (NSError*) error {
    if ([delegate respondsToSelector: @selector (appdateFailed:)]) {
        [delegate appdateFailed: error];
    }
    
   #if NS_BLOCKS_AVAILABLE
    if (completionBlock != nil) {
        completionBlock (error, nil, NO);
        Block_release (completionBlock), completionBlock = nil;
    }
   #endif
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
@end

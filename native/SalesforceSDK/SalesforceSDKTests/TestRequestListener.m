/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "TestRequestListener.h"


NSString* const kTestRequestStatusWaiting = @"waiting";
NSString* const kTestRequestStatusDidLoad = @"didLoad";
NSString* const kTestRequestStatusDidFail = @"didFail";
NSString* const kTestRequestStatusDidCancel = @"didCancel";
NSString* const kTestRequestStatusDidTimeout = @"didTimeout";

@implementation TestRequestListener

@synthesize originalRequest = _originalRequest;
@synthesize jsonResponse = _jsonResponse;
@synthesize lastError = _lastError;
@synthesize returnStatus = _returnStatus;

@synthesize maxWaitTime = _maxWaitTime;

- (id)initWithRequest:(id)request {
    self = [super init];
    if (nil != self) {
        self.maxWaitTime = 30.0;
        self.originalRequest = request;
        NSAssert([request respondsToSelector:@selector(setDelegate:)], @"The request does not expose a delegate.  Nothing to do.");
        [request setDelegate:self];
        self.returnStatus = kTestRequestStatusWaiting;
    }
    
    return self;
}

- (void)dealloc {
    if ([self.originalRequest respondsToSelector:@selector(setDelegate:)]) {
        [self.originalRequest setDelegate:nil];
    }
    self.originalRequest = nil;
    self.jsonResponse = nil;
    self.lastError = nil;
    self.returnStatus = nil;
    [super dealloc];
}


- (NSString *)waitForCompletion {
    
    NSDate *startTime = [NSDate date] ;
        
    while ([self.returnStatus isEqualToString:kTestRequestStatusWaiting]) {
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
        if (elapsed > self.maxWaitTime) {
            NSLog(@"Request took too long (> %f secs) to complete: %@", elapsed, self.originalRequest);
            return kTestRequestStatusDidTimeout;
        }
        
        NSLog(@"## sleeping...");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    return self.returnStatus;
}

#pragma mark - SFRestDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    self.jsonResponse = jsonResponse;
    self.returnStatus = kTestRequestStatusDidLoad;
}

- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    self.lastError = error;
    self.returnStatus = kTestRequestStatusDidFail;
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    self.returnStatus = kTestRequestStatusDidCancel;
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    self.returnStatus = kTestRequestStatusDidTimeout;
}

#pragma mark - SFIdentityCoordinatorDelegate

- (void)identityCoordinatorRetrievedData:(SFIdentityCoordinator *)coordinator
{
    self.returnStatus = kTestRequestStatusDidLoad;
}

- (void)identityCoordinator:(SFIdentityCoordinator *)coordinator didFailWithError:(NSError *)error
{
    self.lastError = error;
    self.returnStatus = kTestRequestStatusDidFail;
}

#pragma mark - SFOAuthCoordinatorDelegate

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator willBeginAuthenticationWithView:(UIWebView *)view
{
    NSAssert(NO, @"User Agent flow not supported in this class.");
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didStartLoad:(UIWebView *)view
{
    NSAssert(NO, @"User Agent flow not supported in this class.");
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFinishLoad:(UIWebView *)view error:(NSError*)errorOrNil
{
    NSAssert(NO, @"User Agent flow not supported in this class.");
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didBeginAuthenticationWithView:(UIWebView *)view
{
    NSAssert(NO, @"User Agent flow not supported in this class.");
}

- (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator
{
    self.returnStatus = kTestRequestStatusDidLoad;
}

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error
{
    self.lastError = error;
    self.returnStatus = kTestRequestStatusDidFail;
}

@end

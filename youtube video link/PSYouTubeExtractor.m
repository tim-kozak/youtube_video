//
//  PSYouTubeExtractor.m
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSYouTubeExtractor.h"
#import <UIKit/UIKit.h>

@interface PSYouTubeExtractor() <UIWebViewDelegate> {
    BOOL testedDOM_;
    NSUInteger retryCount_;
    NSInteger  domWaitCounter_;
    UIWebView *webView_;
    NSURLRequest *lastRequest_;
    PSYouTubeExtractor *selfReference_;
    void (^successBlock_) (NSURL *URL);
    void (^failureBlock_) (NSError *error);
    
    NSString *notification_;
    
    BOOL done;
}
- (void)DOMLoaded_;
- (void)cleanup_;
- (BOOL)doRetry_;
@end

@implementation PSYouTubeExtractor

@synthesize youTubeURL = youTubeURL_;

#define kMaxNumberOfRetries 4 // numbers of retries
#define kWatchdogDelay 3.f    // seconds we wait for the DOM
#define kExtraDOMDelay 3.f    // if DOM doesn't load, wait for some extra time

// uncomment to enable logging
//#define PSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#define PSLog(fmt, ...) 

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject
- (id)init {
    if ((self = [super init])) {
        selfReference_ = self;
    }
    return self;
}
- (id)initWithNSNotificationName:(NSString *)s {
    if ((self = [super init])) {
        notification_ = s;
        selfReference_ = self;
    }
    return self;
}
- (id)initWithNSNotificationName:(NSString *)s youTubeLink:(NSURL *)u
{
    if ((self = [super init]))
    {
        [self getVideoUrlForUrl:u notificatoinName:s];
    }

    return self;
}
- (id)initWithYouTubeURL:(NSURL *)youTubeURL success:(void(^)(NSURL *URL))success failure:(void(^)(NSError *error))failure {
    if ((self = [super init])) {
        successBlock_ = success;
        failureBlock_ = failure;
        youTubeURL_ = youTubeURL;
        selfReference_ = self; // retain while running!
        PSLog(@"Starting YouTube extractor for %@", youTubeURL);
        [self doRetry_];
    }
    return self;
}
- (void) getVideoUrlForUrl:(NSURL *) u notificatoinName:(NSString *)n
{
    [self cleanup_];
    notification_ = n;
    youTubeURL_ = u;
    [self doRetry_];
}
- (void)dealloc {
    [self cleanup_];
    webView_.delegate = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)cleanup_ {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(DOMLoaded_) object:nil]; // cancel watchdog
    successBlock_ = nil;
    failureBlock_ = nil;
    notification_ = nil;
    selfReference_ = nil;    
    [webView_ stopLoading];
    webView_ = nil;
    retryCount_ = 0;
    domWaitCounter_ = 0;
}

- (BOOL)cancel {
    PSLog(@"Cancel called.");
    if (selfReference_) {
        [self cleanup_];
        return YES;
    }
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

// very possible that the DOM isn't really loaded after all or sth failed. Try to load website again.
- (BOOL)doRetry_ {
    if (retryCount_ <= kMaxNumberOfRetries + 1 && !done) {
        retryCount_++;
        domWaitCounter_ = 0;
        PSLog(@"Trying to load page...");

        if (!webView_)
            webView_ = [[UIWebView alloc] init];
        else
            webView_.delegate = nil;

        webView_.delegate = self;
        [webView_ loadRequest:[NSURLRequest requestWithURL:youTubeURL_]];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(DOMLoaded_) object:nil];
        return YES;
    }
    return NO;
}

- (void)DOMLoaded_ {
//    PSLog(@"DOMLoaded_ / watchdog hit");
    
    // figure out if we can extract the youtube url!
    NSString *youTubeMP4URL = [webView_ stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('src')"];
    
    if ([youTubeMP4URL hasPrefix:@"http"]) {
        // probably ok
        done = YES;
        NSURL *URL = [NSURL URLWithString:youTubeMP4URL];
        NSLog(@"%@",URL);
        
        if (notification_)
            [[NSNotificationCenter defaultCenter] postNotificationName:notification_ object:URL];
        else
        {
            if (successBlock_)
                successBlock_(URL);
        }

        [self cleanup_];
    } else {
        if (domWaitCounter_ < kExtraDOMDelay * 2) {
            domWaitCounter_++;
            [self performSelector:@selector(DOMLoaded_) withObject:nil afterDelay:0.5f]; // try every 0.5 sec
            return;
        }
        
        if (![self doRetry_]) {
            NSError *error = [NSError errorWithDomain:@"com.petersteinberger.betteryoutube" code:100 userInfo:[NSDictionary dictionaryWithObject:@"MP4 URL could not be found." forKey:NSLocalizedDescriptionKey]];
            if (failureBlock_) {
                failureBlock_(error);
            }
            [self cleanup_];
        }
    }    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType {
	BOOL should = YES;
	NSURL *url = [aRequest URL];
	NSString *scheme = [url scheme];
    
	// Check for DOM load message
	if ([scheme isEqualToString:@"x-sswebview"]) {
		NSString *host = [url host];
		if ([host isEqualToString:@"dom-loaded"]) {
            PSLog(@"DOM load detected!");
			[self DOMLoaded_];
		}
		return NO;
	}
    
	// Only load http or http requests if delegate doesn't care
	else {
		should = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
	}
    
	// Stop if we shouldn't load it
	if (should == NO) {
		return NO;
	}
    
	// Starting a new request
	if ([[aRequest mainDocumentURL] isEqual:[lastRequest_ mainDocumentURL]] == NO) {
		lastRequest_ = [aRequest retain];
		testedDOM_ = NO;
	}
    
	return should;
}

// With some guidance of SSToolKit this was pretty easy. Thanks Sam!
- (void)webViewDidFinishLoad:(UIWebView *)webView {
     PSLog(@"webViewDidFinishLoad");
    
	// Check DOM
	if (testedDOM_ == NO) {
		testedDOM_ = YES;
        
        // The internal delegate will intercept this load and forward the event to the real delegate
        // Crazy javascript from http://dean.edwards.name/weblog/2006/06/again
		static NSString *testDOM = @"var _SSWebViewDOMLoadTimer=setInterval(function(){if(/loaded|complete/.test(document.readyState)){clearInterval(_SSWebViewDOMLoadTimer);location.href='x-sswebview://dom-loaded'}},10);";
		[webView_ stringByEvaluatingJavaScriptFromString:testDOM];        
	}
    
    // add watchdog in case DOM never get initialized
    [self performSelector:@selector(DOMLoaded_) withObject:nil afterDelay:kWatchdogDelay];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    PSLog(@"didFailLoadWithError");
    
    if (![self doRetry_]) {
        if (failureBlock_) {
            failureBlock_(error);
        }
        [self cleanup_];
    }
}

@end

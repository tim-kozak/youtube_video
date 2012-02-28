//
//  PSYouTubeExtractor.h
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import <Foundation/Foundation.h>

/// This class opens a hidden UIWebView and extracts the mobile YouTube URL if possible.
/// It's not a subclass of NSOperation because of the UIWebView interaction.
/// While running, the class retains itself. Call cancel to stop and release the internal retain.
@interface PSYouTubeExtractor : NSObject

/// Tries to extract the actual mp4 used to play a YouTube movie. 
/// There are quite some movies out there that don't support mobile and don't have a mp4 version set.
- (id)init;
- (id)initWithYouTubeURL:(NSURL *)youTubeURL success:(void(^)(NSURL *URL))success failure:(void(^)(NSError *error))failure;
- (id)initWithNSNotificationName:(NSString *)s;
- (id)initWithNSNotificationName:(NSString *)s youTubeLink:(NSURL *)u;

- (void) getVideoUrlForUrl:(NSURL *)u notificatoinName:(NSString *)n;

/// Cancels a potential running request. Returns NO if request already finished.
- (BOOL)cancel;

/// Access the original YouTube URL.
@property(nonatomic, strong, readonly) NSURL *youTubeURL;

@end

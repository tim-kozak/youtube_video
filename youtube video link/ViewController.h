//
//  ViewController.h
//  youtube video link
//
//  Created by comonitos on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSYouTubeExtractor.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController
{
    PSYouTubeExtractor *extractor;
    NSURLConnection *con;
    NSURL *url;
    NSMutableData *videoData;
    MPMoviePlayerController *movieController;
}
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activity;

- (void) getVideo;
- (void) play:(NSNotification *)n;
@end

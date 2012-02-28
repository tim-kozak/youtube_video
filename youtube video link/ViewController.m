//
//  ViewController.m
//  youtube video link
//
//  Created by comonitos on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize activity;

#pragma mark - View lifecycle
- (void)dealloc {
    [activity release];
    [extractor release];
    [con release];
    [url release];
    [videoData release];
    [movieController release];

    [super dealloc];
}
- (void)viewDidUnload {
    [self setActivity:nil];
    
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // follow twitter @comonitos
    // my app store app http://itunes.apple.com/us/app/frendium/id488565877 @Frendium
    

    //Patched a little !!!! Thanks Peter Steinberger for PSYouTubeExtractor https://github.com/steipete/PSYouTubeExtractor
    extractor = [[PSYouTubeExtractor alloc] init];
    
    [self getVideo];
}

- (void) getVideo 
{
    // YOUTUBE LINK
    NSURL *youTubeURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=wO4HJOf_DGU"];

    [extractor getVideoUrlForUrl:youTubeURL notificatoinName:@"URLDidFinishExtractingFromYouTubeURL"];

    //notifications that comes with url
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(play:) name:@"URLDidFinishExtractingFromYouTubeURL" object:nil];
    
    [activity startAnimating];
}

- (void) play:(NSNotification *)n {
    
    [activity stopAnimating];

    url = [(NSURL *)n.object retain];

    //NSURLConnection will download the video
    con = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
    
//COMMENT THIS IF YOU DON'T WANT TO WATCH
    if (movieController)
        movieController.contentURL = url;
    else
        movieController = [[MPMoviePlayerController alloc] initWithContentURL:url];
    
    movieController.view.frame = self.view.bounds;
    movieController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;   
    [self.view addSubview:movieController.view];

    [movieController prepareToPlay];
    [movieController setShouldAutoplay:YES];
//UP TO HERE
}

#pragma mark - NSURLConnection DELEGATE

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    videoData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [videoData appendData:data];
}

//when downloading done
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/%f.mp4", NSHomeDirectory(),[[NSDate date] timeIntervalSince1970]];

    [videoData writeToFile:filePath atomically:YES];

    [videoData release];
    
    NSLog(@"LOCAL VIDEO LINK %@",filePath);
}
@end

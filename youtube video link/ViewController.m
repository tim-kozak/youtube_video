//
//  ViewController.m
//  youtube video link
//
//  Created by comonitos on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // twitter @comonitos
    // my app store app http://itunes.apple.com/us/app/frendium/id488565877 @Frendium
    
	// YOUTUBE LINK
    NSURL *youTubeURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=wO4HJOf_DGU"];

    //notifications that comes with url
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(play:) name:@"URLDidFinishExtractingFromYouTubeURL" object:nil];
    
    //Thanks Peter Steinberger for PSYouTubeExtractor https://github.com/steipete/PSYouTubeExtractor
    
    //Patched a little !!!!
    extractor = [PSYouTubeExtractor extractorForYouTubeURL:youTubeURL success:nil failure:nil];
}

- (void) play:(NSNotification *)n {
    
    url = [(NSURL *)n.object retain];
    
    con = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
    
//COMMENT THIS IF YOU DON'T WANT TO WATCH
    MPMoviePlayerController *movieController = [[MPMoviePlayerController alloc] initWithContentURL:url];
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
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/%f.mp4", NSHomeDirectory(),[[NSDate date] timeIntervalSince1970]];

    [videoData writeToFile:filePath atomically:YES];

    [videoData release];
}
@end

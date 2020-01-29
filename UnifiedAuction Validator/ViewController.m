//
//  ViewController.m
//  UnifiedAuction Validator
//
//  Created by Jason C on 11/30/19.
//  Copyright © 2019 Jason C. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ASInterstitialViewControllerDelegate, ASAdViewDelegate>

@end

@implementation ViewController


    NSMutableData *_responseData;               // Response data from the delegate (not being used)
    NSString * baseApiURL = @"http://107.170.192.117:8900/api/session/";



     ASInterstitialViewController* interVC;          // Interstitial view controller
    ASAdView* bannerView;                           // Banner ad view
    
    bool adRequestInProgress = false;               // Track the status of the ad request
    bool hasInterstitialImpression = false;         // Track the impression
    NSString * impressionFromBuyer = @"";           // Track the last known buyer for metrics


    // Statistics
    NSInteger numAdAttempts;                    // Track the number of attempts
    NSInteger numAdFilled;                      // Track the number of attempts
    NSInteger numAdShown;                       // Track the number of attempts
    NSInteger numClientSideTimeout;             // Track the number of client timeouts
    NSInteger numAdError;                       // Track the number of errors (todo: move this into the dictionary)
    NSInteger numInternalError;
    NSInteger numConnectionError;
    NSInteger numAvgAuctionTime;                // Keep a running total of average auction time (to implement)
    
    // Timing Tests
    long long timeAdReqBegin;
    long long timeAdReqEnd;
    long long timeElapsed;
        

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onTouchBeginTest:(id)sender {

     [self createAndBeginLoadingInterstitial];
    //    [self createAndLoadMREC];
    
    NSLog(@"--------- onTouchBeginTest");
    
}


#pragma mark Metric Section

- (void) setStartingMetricTime {
    timeAdReqBegin = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSString *timeTrackingString = [NSString stringWithFormat:@"%lld%@" , timeAdReqBegin, @" begin tracking time!"];
    NSLog(@"%@", timeTrackingString);
}

- (void) setEndMetricTime {
    timeAdReqEnd = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSString *timeTrackingString = [NSString stringWithFormat:@"%lld%@" , timeAdReqEnd, @" end tracking time!"];
    NSLog(@"%@", timeTrackingString);
}


- (NSString*) returnStartingMetricTime{
    double formatTimeToUse = (double)timeAdReqBegin;
    NSString *timeString = [NSString stringWithFormat:@"%f" , formatTimeToUse/1000.0];
    return timeString;
}


- (NSString*) returnEndMetricTime{
    double formatTimeToUse = (double)timeAdReqEnd;
    NSString *timeString = [NSString stringWithFormat:@"%f" , formatTimeToUse/1000.0];
    return timeString;
}


- (NSString*) calculateTrackingTimeAndReturnValueForSendWithStart:(long long)start WithEnd:(long long) end  {
    timeElapsed = (end - start);
    double formatTimeToSend = (double)timeElapsed;
    NSString *totalTimeString = [NSString stringWithFormat:@"%f" , formatTimeToSend/1000.0];
    NSLog(@"%@", totalTimeString);
    
    return totalTimeString;
}


- (void) fireMetricWithTime:(NSString* )timeElapsed andStart:(NSString* ) startTime andEnd:(NSString*) endTime forPlacement:(NSString* ) plc{

    NSDictionary *jsonBodyDict = @{
        @"request_startTime":startTime,
        @"request_endTime":endTime,
        @"request_totalTimeElapsed":timeElapsed,
        @"device_name":@"ios 7+ jason's nice desk",
        @"device_ip": @"some US IP",
        @"device_platform":@"iOS",
        @"ad_request_placement":plc,
        @"ad_request_geo":@"USA",
        @"ad_delivery_status": @YES
    };
    
    // Serialize the data in the request
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:kNilOptions error:nil];
    
    // Create the request
    NSURL *url = [NSURL URLWithString:baseApiURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody: jsonBodyData];
        
    // Create url connection and fire request.
    // TODO: Update this since we're using a deprecated method
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"NSURLConnection didReceiveResponse from: %@", response.URL.absoluteString);
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"NSURLConnection didReceiveData with length: %lu", (unsigned long)data.length);
    [_responseData appendData:data];
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSLog(@"NSURLConnection connectionDidFinishLoading");
}


// TODO: show something if it errors
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // The request has failed for some reason! Check the error var
    }



#pragma mark Ad Test Control Methods


- (void) createAndBeginLoadingInterstitial {
    
    // Create ASInterstitial VC
    interVC = [ASInterstitialViewController viewControllerForPlacementID:default_int_plc withDelegate:self];

    // Load the interstitial 5 seconds later
    [self delayedSubmitInterstitialRequest:initial_request_delay];

}

- (void) createAndLoadMREC {
    
    // Create  banner view
    bannerView = [ASAdView viewWithPlacementID:default_mrec_plc asAdSize:CGSizeMake(300.0f, 250.0f)andDelegate:self];
    
    // Configure the banner
    bannerView.isPreload = false;
    bannerView.delegate = self;
    bannerView.bannerRefreshTimeInterval = 30.0f;
    
    // Do banner load on the main queue
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest now running!");
        
        // Load the banner
        [bannerView loadAd];
        
        // Add banner to view
        [self.view addSubview:bannerView];
        
    });
    
}




- (void) delayedSubmitInterstitialRequest:(unsigned long long)time {
    
    NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest has been submitted");

    
    // Do a delay before invoking the load interstitial function.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest now running!");
        [self setStartingMetricTime];
        
        // Load the interstitial VC
        [interVC loadAd];
        
        // Ensure we set this to false so our timeout can reference this value.
        hasInterstitialImpression = false;
        adRequestInProgress = true;             // Set this to true so we know that we're attempting an ad request
        impressionFromBuyer = @"";              // Set to empty string since we don't have a buyer yet
        
        // Begin a timeout for the global request timeout seconds
        [self attemptTimeoutAfterTime:global_request_timeout forVC:interVC];
        
        // Track the # of attempts
        [self stat_incrementNumAdAttempts];
        [self view_updateAllStats];
    });
    
}

- (void) attemptTimeoutAfterTime:(unsigned long long)time forVC:(ASInterstitialViewController*)vc{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // Only try to cancel this if we don't have an impresison before this timeout value.
        if (!hasInterstitialImpression && adRequestInProgress){
            NSLog(@"--------- InterstitialVC, attemptTimeoutAfterTime since we don't have an impression yet after: %lld", time);
            
            [self stat_incrementNumClientTimeout];
            [self view_updateAllStats];
            
            [vc cancel];
            
            // Load another interstitial a couple seconds later, just to be safe.
            [self delayedSubmitInterstitialRequest:time_before_next_request];
                        
        } else {
            
            if (!hasInterstitialImpression) {
                 NSLog(@"--------- InterstitialVC, do NOT timeout since we have an impression after: %lld", time);
            }
            
            if (adRequestInProgress) {
                 NSLog(@"--------- InterstitialVC, ad request is still in progress! %lld", time);
            }
            
    
        }
        
    });
    

    
}


- (void) attemptCloseInterstitialViewAfterTime:(unsigned long long)time forVC:(ASInterstitialViewController*)vc {
    
    // Do a delay before invoking the load interstitial function.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"--------- InterstitialVC, attemptCloseInterstitialViewAfterTime");
        
        [vc cancel];

        UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        
        while (true)
        {
            if (topViewController.presentedViewController) {
                topViewController = topViewController.presentedViewController;
                
                [topViewController dismissViewControllerAnimated:false completion:nil];

                
            } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *nav = (UINavigationController *)topViewController;
                topViewController = nav.topViewController;
            } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tab = (UITabBarController *)topViewController;
                topViewController = tab.selectedViewController;
            } else {
                break;
            }
        }
        
        topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [topViewController dismissViewControllerAnimated:false completion:nil];
        
        
        
        

    
        
    });
    
}


#pragma mark - ASInterstitialViewControllerDelegate Protocol Methods

- (void)interstitialViewControllerAdFailedToLoad:(ASInterstitialViewController*)viewController withError:(NSError*)error {
    
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdFailedToLoad:withError: -- error: %ld", (long)error.code);
    
    // We're done with the ad request
    adRequestInProgress = false;
        
    // Update # of errors and update view
    [self stat_incrementNumAdErrorsForError:error.code];
    [self view_updateAllStats];
    [self delayedSubmitInterstitialRequest:time_before_next_request];
    
}

- (void)interstitialViewControllerAdLoadedSuccessfully:(ASInterstitialViewController*)viewController {
    
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdLoadedSuccessfully");
    [viewController showFromViewController:self];
    
    // We're done with the ad request, now we're waterfalling client side
       adRequestInProgress = false;
    
    // Attempt to close the controller after 5 seconds
    [self attemptCloseInterstitialViewAfterTime:global_request_timeout forVC:viewController];
    [self delayedSubmitInterstitialRequest:time_before_next_request];
    
}

- (void)interstitialViewControllerDidPreloadAd:(ASInterstitialViewController*)viewController {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerDidPreloadAd:");
}


- (void)interstitialViewController:(ASInterstitialViewController*)viewController didLoadAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    
    NSLog(@"--------- InterstitialVC, interstitialViewController:didLoadAdWithTransactionInfo: - transactionInfo: %@", transactionInfo);
    
    // Fire metric and send value
    [self setEndMetricTime];
    
    [self fireMetricWithTime:[self calculateTrackingTimeAndReturnValueForSendWithStart:timeAdReqBegin WithEnd:timeAdReqEnd] andStart:[self returnStartingMetricTime] andEnd:[self returnEndMetricTime] forPlacement:default_int_plc];
    
    // Update # of ads filled and update view
    
    [self stat_incrementNumAdFilled];
    [self view_updateAllStats];
    
    // Auction shown here is the winner
    [self view_updateCurrentAuctionWinnerAs: [transactionInfo objectForKey:@"buyerName"]];
    
    // Winning auction will be associated with this price
    [self view_updateCurrentAuctionWinPriceAs: [transactionInfo objectForKey:@"buyerPrice"]];
    
}

- (void)interstitialViewController:(ASInterstitialViewController*)viewController didShowAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    
    NSLog(@"--------- InterstitialVC, interstitialViewController:didShowAdWithTransactionInfo: - transactionInfo: %@", transactionInfo);

    // Auction shown may NOT be the auction winner.
    [self view_updateCurrentAuctionShownAs: [transactionInfo objectForKey:@"buyerName"]];
    
    // Likewise, the price may update
    [self view_updateCurrentAuctionPriceAs: [transactionInfo objectForKey:@"buyerPrice"]];

    // We're expecting an impression from the buyer; set and display only when it is visible.
    impressionFromBuyer = [transactionInfo objectForKey:@"buyerName"];
    
}


- (void)interstitialViewControllerWillAppear:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerWillAppear:");
}

- (void)interstitialViewControllerDidAppear:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerDidAppear:");

}

- (void)interstitialViewControllerAdImpression:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdImpression:");
    
    
    hasInterstitialImpression = true;
    [self view_updateCurrentImpressionShownAs:impressionFromBuyer];
    
    // Update # of ads shown (with imp) and update view
    [self stat_incrementNumAdShown];
    [self view_updateAllStats];
    
}

- (void)interstitialViewControllerAdDidComplete:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdDidComplete");
}

- (void)interstitialViewControllerWillDisappear:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerWillDisappear");
}

- (void)interstitialViewControllerDidDisappear:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerDidDisappear");
}

- (void)interstitialViewControllerAdWasTouched:(ASInterstitialViewController*)viewController  {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdWasTouched:");
}





#pragma mark - ASAdViewDelegate / MPADdViewDelegate Protocol Methods

// ASAdViewDelegate & MPAdViewDelegate Overloaded
- (UIViewController*)viewControllerForPresentingModalView {
    return self;
}

// ASAdViewDelegate & MPAdViewDelegate Overloaded
- (void)adViewDidLoadAd:(id)adView {
    if([adView isKindOfClass:[ASAdView class]]) {
        NSLog(@"-------- ASBannerCallback: adViewDidLoadAd:");
        ASAdView* asAdView = adView;
        asAdView.center = self.view.center;
        
        [self stat_incrementNumAdFilled];
        [self view_updateAllStats];
        
    }
}
// ASAdViewDelegate
- (void)adViewDidFailToLoadAd:(ASAdView*)adView withError:(NSError*)error {
    NSLog(@"-------- ASBannerCallback: adViewDidFailToLoadAd:withError: - error: %@", error.description);
    
    [self stat_incrementNumAdErrorsForError:error.code];
    [self view_updateAllStats];
    
}

// ASAdViewDelegate
- (void)adViewDidPreloadAd:(ASAdView*)adView {
    NSLog(@"-------- ASBannerCallback: adViewDidPreloadAd:");
}

// ASAdViewDelegate
- (void)adViewAdImpression:(ASAdView*)adView {
    NSLog(@"-------- ASBannerCallback: adViewAdImpression:");
    
  
    
}

// ASAdViewDelegate & MPAdViewDelegate Overloaded
- (void)willPresentModalViewForAd:(id)adView {
    if([adView isKindOfClass:[ASAdView class]]) {
        NSLog(@"-------- ASBannerCallback: willPresentModalViewForAd:");
    }
}

// ASAdViewDelegate & MPAdViewDelegate Overloaded
- (void)didDismissModalViewForAd:(id)adView {
    if([adView isKindOfClass:[ASAdView class]]) {
        NSLog(@"-------- ASBannerCallback: didDismissModalViewForAd:");
    }
}

// ASAdViewDelegate & MPAdViewDelegate Overloaded
- (void)willLeaveApplicationFromAd:(id)adView {
    if([adView isKindOfClass:[ASAdView class]]) {
        NSLog(@"-------- ASBannerCallback: willLeaveApplicationFromAd:");
    }
}

// ASAdViewDelegate
- (void)adViewDidCompletePlayingWithVastAd:(ASAdView*)adView {
    NSLog(@"-------- ASBannerCallback: adViewDidCompletePlayingWithVastAd:");
}

// ASAdViewDelegate
- (void)adWasClicked:(ASAdView*)adView {
    NSLog(@"-------- ASBannerCallback: adWasClicked:");
}

// ASAdViewDelegate
- (void)adView:(ASAdView*)adView didLoadAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    NSLog(@"-------- ASBannerCallback: adView:didLoadAdWithTransactionInfo: %@", transactionInfo);
    
    [self stat_incrementNumAdFilled];
    [self view_updateAllStats];
    
}

// ASAdViewDelegate
- (void)adView:(ASAdView*)adView didShowAdWithTransactionInfo:(NSDictionary*)transcationInfo {
    NSLog(@"-------- ASBannerCallback: adView:didShowAdWithTransactionInfo: %@", transcationInfo);
    
    [self stat_incrementNumAdShown];
      [self view_updateAllStats];
    
}







#pragma mark - Statistical get/set Methods

- (void) stat_incrementNumAdAttempts{
    numAdAttempts++;
    NSLog(@"--------- stat_incrementNumAdAttempts: %li", numAdAttempts);
    [self view_updateAllStats];

}

- (void) stat_incrementNumAdFilled{
    numAdFilled++;
    NSLog(@"--------- stat_incrementNumAdFilled: %li", numAdFilled);
    [self view_updateAllStats];
}


- (void) stat_incrementNumAdErrorsForError:(NSInteger) errCode{
    numAdError++;
    NSLog(@"--------- stat_incrementNumAdErrors: %li", numAdError);
    
    if (errCode == 1){
        numInternalError++;
        NSLog(@"--------- stat_incrementNumAdErrors for err 1: %li", numInternalError);
        
    }
    
    if (errCode == 11){
        numConnectionError++;
        NSLog(@"--------- stat_incrementNumAdErrors for err 11: %li", numConnectionError);
        

    }
    
    [self view_updateAllStats];

}

- (void) stat_incrementNumAdShown{
    numAdShown++;
    NSLog(@"--------- stat_incrementNumAdShown: %li", numAdShown);
    [self view_updateAllStats];
}


- (void) stat_incrementNumClientTimeout{
    numClientSideTimeout++;
    NSLog(@"--------- stat_incrementNumClientTimeout: %li", numClientSideTimeout);
    [self view_updateAllStats];
}

- (void) stat_recalculateAverageAuctionTime{
    numClientSideTimeout++;
    NSLog(@"--------- stat_recalculateAverageAuctionTime: %li", numAvgAuctionTime);
    [self view_updateAllStats];
}



#pragma mark - Single Auction View view set Methods

- (void) view_updateCurrentAuctionWinnerAs:(NSString*)val{
    [self.labelValueCurrentAuctionWinner setText:val];
}

- (void) view_updateCurrentAuctionWinPriceAs:(NSNumber*)val{
    [self.labelValueCurrentAuctionWinPrice setText:[NSString stringWithFormat:@"%@",val]];
}


- (void) view_updateCurrentAuctionPriceAs:(NSNumber*)val{
    [self.labelValueCurrentAuctionPrice setText:[NSString stringWithFormat:@"%@",val]];
}

- (void) view_updateCurrentAuctionShownAs:(NSString*)val{
    [self.labelValueCurrentAuctionShown setText:val];
}

- (void) view_updateCurrentImpressionShownAs:(NSString*)val{
    [self.labelValueCurrentImpressionFrom setText:val];
}






#pragma mark - Updating/Reporting view Methods

- (void) report_printAllStats {
    NSLog(@"--------- Number of Ad Attempts: %li", numAdAttempts);
    NSLog(@"--------- Number of Ad Fills: %li", numAdFilled);
    NSLog(@"--------- Number of Ad Errors: %li", numAdError);
    NSLog(@"--------- Number of Ad Shown: %li", numAdShown);
    NSLog(@"--------- Number of Client timeout: %li", numClientSideTimeout);
     NSLog(@"--------- Number of Connection err: %li", numConnectionError);
     NSLog(@"--------- Number of Internal err: %li", numInternalError);

}

// To do to make this cleaner.
- (void) view_updateForSingleStat:(NSString*)stat {
    
    if ([stat isEqualToString:@"attempt"]){
        [self.labelValueNumAdRequest setText:[NSString stringWithFormat:@"%ld",numAdFilled]];
    }
    // TODO: Implement the rest

    
}


- (void) view_updateAllStats{
    
    // Update all of the running statistics.
    
    [self.labelValueNumAdRequest setText:[NSString stringWithFormat:@"%ld",numAdAttempts]];
    [self.labelValueNumAdFilled setText:[NSString stringWithFormat:@"%ld",numAdFilled]];
    [self.labelValueNumAdError setText:[NSString stringWithFormat:@"%ld",numAdError]];
    [self.labelValueNumAdShown setText:[NSString stringWithFormat:@"%ld",numAdShown]];
    [self.labelValueNumClientTimeout setText:[NSString stringWithFormat:@"%ld",numClientSideTimeout]];
    [self.labelValueInternalErrorCount setText:[NSString stringWithFormat:@"%ld",numInternalError]];
    [self.labelValueConnectionErrorCount setText:[NSString stringWithFormat:@"%ld",numConnectionError]];
    
}









@end

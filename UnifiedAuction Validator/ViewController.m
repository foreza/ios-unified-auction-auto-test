//
//  ViewController.m
//  UnifiedAuction Validator
//
//  Created by Jason C on 11/30/19.
//  Copyright © 2019 Jason C. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ASInterstitialViewControllerDelegate, ASAdViewDelegate, IMInterstitialDelegate>



@end

@implementation ViewController


    NSMutableData *_responseData;               // Response data from the delegate (not being used)
    NSString * baseApiURL = @"http://107.170.192.117:8900/api/session/";


    // Test Variables

     ASInterstitialViewController* interVC;          // Interstitial view controller

//    NSString * plc = @"1069520";                   // [Int] SE test placement ID for mirror
//    NSString * plc = @"1070080";                   // [Int] focus test smaato / dsui adline
    NSString * plc = @"1067688";                     // [Int] MSFT iOS int placement
//    NSString * plc = @"380003";                    // [Int] Sample VAST placement ID

    ASAdView* bannerView;                           // Banner ad view

    NSString * bPLC = @"1067944";                   // MSFT iOS MREC placement

    
    NSInteger globalRequestTimeout = 5;            // Once this timeout is reached, we'll terminate the request if an impression is not yet fired.
    NSInteger timeBeforeNextRequest = 35;       // We'll wait this amount of time before firing off another request
    NSInteger timeForAdOnScreen = 15;               // Amount of time we'll allow an ad to be on screen before we ask for another one.

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
        

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [self createAndBeginLoadingInterstitial];
//    [self createAndLoadMREC];
    
}

- (IBAction)onTouchBeginTest:(id)sender {
    
//     [self createAndBeginLoadingInterstitial];
    
    [self fireMetricWithTime:@"999.0"];

//    NSLog(@"--------- InterstitialVC, onTouchBeginTest");
    
}

- (void) fireMetricWithTime:(NSString* )timeElapsed{

    NSDictionary *jsonBodyDict = @{
        @"request_totalTimeElapsed":timeElapsed,
        @"device_name":@"ios 7+ jason desk",
        @"device_ip": @"some US IP",
        @"device_platform":@"iOS",
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
//    [request setValue:[NSString stringWithFormat:@"%d", [jsonBodyData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: jsonBodyData];
        
    // Create url connection and fire request.
    // TODO: Update this since we're using a deprecated method
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    

    // watch out: error is nil here, but you never do that in production code. Do proper checks!
    
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    _responseData = [[NSMutableData alloc] init];
        
    NSLog(@"NSURLConnection didReceiveResponse from: %@", response.URL.absoluteString);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    
    // Note: connection:didReceiveData: will be hit several times
    
    [_responseData appendData:data];
    
    NSLog(@"NSURLConnection didReceiveData with length: %lu", (unsigned long)data.length);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    NSLog(@"NSURLConnection connectionDidFinishLoading");
}


// TODO: show something if it errors
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    // The request has failed for some reason!
    // Check the error var
    }





- (void) createAndBeginLoadingInterstitial {
    
    // Create ASInterstitial VC
    interVC = [ASInterstitialViewController viewControllerForPlacementID:plc withDelegate:self];

    
    // Load the interstitial 5 seconds later
    [self delayedSubmitInterstitialRequest:5];

}

- (void) createAndLoadMREC {
    
    // Create  banner view
    bannerView = [ASAdView viewWithPlacementID:bPLC
                                                   asAdSize:CGSizeMake(300.0f, 250.0f)
                                                andDelegate:self];
       
       bannerView.isPreload = false;
       bannerView.delegate = self;
       bannerView.bannerRefreshTimeInterval = 30.0f;
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
          
          NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest now running!");
        
        [bannerView loadAd];
        [self.view addSubview:bannerView];
        
    });
    
}



- (void) delayedSubmitInterstitialRequest:(unsigned long long)time {
    
    NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest has been submitted");

    
    // Do a delay before invoking the load interstitial function.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest now running!");
    
        
        // Load the interstitial VC
        [interVC loadAd];
        
        // Ensure we set this to false so our timeout can reference this value.
        hasInterstitialImpression = false;
        adRequestInProgress = true;             // Set this to true so we know that we're attempting an ad request
        impressionFromBuyer = @"";              // Set to empty string since we don't have a buyer yet
        
        // Begin a timeout for the global request timeout seconds
        [self attemptTimeoutAfterTime:globalRequestTimeout forVC:interVC];
        
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
            [self delayedSubmitInterstitialRequest:timeBeforeNextRequest];
                        
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



// IMInterstitialDelegate & GADInterstitialDelegate
- (void)interstitialDidReceiveAd:(id)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialDidReceiveAd:");
}

// IMInterstitialDelegate
- (void)interstitialDidFinishLoading:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialDidFinishLoading:");
  
}

// IMInterstitialDelegate
- (void)interstitial:(IMInterstitial*)interstitial didFailToLoadWithError:(IMRequestStatus*)error {
    NSLog(@"--------- InterstitialVC, interstitial:didFailToLoadWithError: - error: %@", error.description);

}

// IMInterstitialDelegate
- (void)interstitialWillPresent:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialWillPresent:");

}

// IMInterstitialDelegate
- (void)interstitialDidPresent:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialDidPresent:");
}

// IMInterstitialDelegate
- (void)interstitial:(IMInterstitial*)interstitial didFailToPresentWithError:(IMRequestStatus*)error {
    NSLog(@"--------- InterstitialVC, interstitial:didFailToPresentWithError: - error: %@", error);
}

// IMInterstitialDelegate
- (void)interstitialWillDismiss:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialWillDismiss:");
}

// IMInterstitialDelegate
- (void)interstitialDidDismiss:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, interstitialDidDismiss:");

}

// IMInterstitialDelegate
- (void)interstitial:(IMInterstitial*)interstitial didInteractWithParams:(NSDictionary*)params {
    NSLog(@"--------- InterstitialVC, interstitial:didInteractWithParams: - params: %@", params);
}

// IMInterstitialDelegate
- (void)interstitial:(IMInterstitial*)interstitial rewardActionCompletedWithRewards:(NSDictionary*)rewards {
    NSLog(@"--------- InterstitialVC, interstitial:rewardActionCompletedWithRewards: - rewards: %@", rewards);
}

// IMInterstitialDelegate
- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial*)interstitial {
    NSLog(@"--------- InterstitialVC, userWillLeaveApplicationFromInterstitial:");
}




#pragma mark - ASInterstitialViewControllerDelegate Protocol Methods

- (void)interstitialViewControllerAdFailedToLoad:(ASInterstitialViewController*)viewController withError:(NSError*)error {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdFailedToLoad:withError: -- error: %ld", (long)error.code);
    
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdFailedToLoad:withError: -- error:", error);
    
    
    
    // We're done with the ad request
    adRequestInProgress = false;
        
    // Update # of errors and update view
    [self stat_incrementNumAdErrorsForError:error.code];
    [self view_updateAllStats];
    
    [self delayedSubmitInterstitialRequest:timeBeforeNextRequest];
}

- (void)interstitialViewControllerAdLoadedSuccessfully:(ASInterstitialViewController*)viewController {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdLoadedSuccessfully");
    [viewController showFromViewController:self];
    
    // We're done with the ad request, now we're waterfalling client side
       adRequestInProgress = false;
    
    // Attempt to close the controller after 5 seconds
    [self attemptCloseInterstitialViewAfterTime:globalRequestTimeout forVC:viewController];
    
     [self delayedSubmitInterstitialRequest:timeBeforeNextRequest];
}

- (void)interstitialViewControllerDidPreloadAd:(ASInterstitialViewController*)viewController {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerDidPreloadAd:");
}


- (void)interstitialViewController:(ASInterstitialViewController*)viewController didLoadAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    NSLog(@"--------- InterstitialVC, interstitialViewController:didLoadAdWithTransactionInfo: - transactionInfo: %@", transactionInfo);
    
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

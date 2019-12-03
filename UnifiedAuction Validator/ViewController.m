//
//  ViewController.m
//  UnifiedAuction Validator
//
//  Created by Jason C on 11/30/19.
//  Copyright © 2019 Jason C. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ASInterstitialViewControllerDelegate>



@end

@implementation ViewController


    // Test Variables

    ASInterstitialViewController* interVC;          // Interstitial view controller
    NSString * plc = @"1069520";                     // AerServ placement ID
//    NSString * plc = @"380003";                     // Sample placement ID

    
    NSInteger globalRequestTimeout = 5;            // Once this timeout is reached, we'll terminate the request if an impression is not yet fired.
    NSInteger timeBeforeNextRequest = 15;           // We'll wait this amount of time before firing off another request
    NSInteger timeForAdOnScreen = 10;               // Amount of time we'll allow an ad to be on screen before we ask for another one.

    bool adRequestInProgress = false;               // Track the status of the ad request
    bool hasInterstitialImpression = false;         // Track the impression
    NSString * impressionFromBuyer = @"";           // Track the last known buyer for metrics


    // Statistics

    NSInteger numAdAttempts;                    // Track the number of attempts
    NSInteger numAdFilled;                      // Track the number of attempts
    NSInteger numAdShown;                       // Track the number of attempts
    NSInteger numClientSideTimeout;             // Track the number of client timeouts
    NSInteger numAdError;                       // Track the number of errors (todo: move this into the dictionary)
    NSInteger numAvgAuctionTime;                // Keep a running total of average auction time (to implement)
        
    NSDictionary *errorDictonary;               // TODO: Implement

//    = @{
//           @"noFill" : @0,
//        @"internalError" : @0,
//        @"timeout" : @0
//    };
//




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createAndBeginLoadingInterstitial];
    
}

- (IBAction)onTouchBeginTest:(id)sender {
    
     [self createAndBeginLoadingInterstitial];

    NSLog(@"--------- InterstitialVC, onTouchBeginTest");

    
}


- (void) createAndBeginLoadingInterstitial {
    
    // Create ASInterstitial VC
    interVC = [ASInterstitialViewController viewControllerForPlacementID:plc withDelegate:self];
    
    // Load the interstitial 5 seconds later
    [self delayedSubmitInterstitialRequest:5];

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
                        
        } else {
            NSLog(@"--------- InterstitialVC, do NOT timeout since we have an impression after: %lld", time);
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
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdFailedToLoad:withError: -- error: %@", error.localizedDescription);
    
    // We're done with the ad request
    adRequestInProgress = false;
    
    // Update # of errors and update view
    [self stat_incrementNumAdErrors];
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


- (void) stat_incrementNumAdErrors{
    numAdError++;
    NSLog(@"--------- stat_incrementNumAdErrors: %li", numAdError);
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
    // [self.labelValueNumClientTimeout setText:[NSString stringWithFormat:@"TODO"]];

}







@end

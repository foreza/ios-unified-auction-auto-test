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
//    NSString * plc = @"1069520";                     // AerServ placement ID
    NSString * plc = @"380003";                     // Sample placement ID
    bool hasInterstitialImpression = false;         // Track the impression


    // Statistics

    NSInteger numAdAttempts;                    // Track the number of attempts
    NSInteger numAdFilled;                      // Track the number of attempts
    NSInteger numAdShown;                       // Track the number of attempts
    NSInteger numAdError;                       // Track the number of errors (todo: move this into the dictionary)
        
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
    
    // Do a delay before invoking the load interstitial function.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        NSLog(@"--------- InterstitialVC, delayedSubmitInterstitialRequest");
        

        
        // Load the interstitial VC
        [interVC loadAd];
        
        // Ensure we set this to false so our timeout can reference this value.
        hasInterstitialImpression = false;
        
        // Begin a timeout for 3 seconds
        [self attemptTimeoutAfterTime:3 forVC:interVC];
        
        // Track the # of attempts
        [self stat_incrementNumAdAttempts];
    });
    
}

- (void) attemptTimeoutAfterTime:(unsigned long long)time forVC:(ASInterstitialViewController*)vc{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // Only try to cancel this if we don't have an impresison before this timeout value.
        if (!hasInterstitialImpression){
            NSLog(@"--------- InterstitialVC, attemptTimeoutAfterTime since we don't have an impression yet after: %lld", time);
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
    
    [self delayedSubmitInterstitialRequest:10];

}

- (void)interstitialViewControllerAdLoadedSuccessfully:(ASInterstitialViewController*)viewController {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerAdLoadedSuccessfully");
    [viewController showFromViewController:self];
    
    // Attempt to close the controller after 5 seconds
    [self attemptCloseInterstitialViewAfterTime:10 forVC:viewController];
    
     [self delayedSubmitInterstitialRequest:15];
    
}

- (void)interstitialViewControllerDidPreloadAd:(ASInterstitialViewController*)viewController {
    NSLog(@"--------- InterstitialVC, interstitialViewControllerDidPreloadAd:");
}


- (void)interstitialViewController:(ASInterstitialViewController*)viewController didLoadAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    NSLog(@"--------- InterstitialVC, interstitialViewController:didLoadAdWithTransactionInfo: - transactionInfo: %@", transactionInfo);
}

- (void)interstitialViewController:(ASInterstitialViewController*)viewController didShowAdWithTransactionInfo:(NSDictionary*)transactionInfo {
    NSLog(@"--------- InterstitialVC, interstitialViewController:didShowAdWithTransactionInfo: - transactionInfo: %@", transactionInfo);
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
    NSLog(@"--------- stat_incrementNumAdAttempts: %i", numAdAttempts);

}

// TODO: Implement the rest




@end

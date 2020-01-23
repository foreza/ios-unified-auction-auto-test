//
//  ViewController.h
//  UnifiedAuction Validator
//
//  Created by Jason C on 11/30/19.
//  Copyright © 2019 Jason C. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <InMobiSDK/InMobiSDK.h>


@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *labelValueNumAdRequest;
@property (weak, nonatomic) IBOutlet UILabel *labelValueNumAdFilled;
@property (weak, nonatomic) IBOutlet UILabel *labelValueNumAdError;
@property (weak, nonatomic) IBOutlet UILabel *labelValueNumAdShown;
@property (weak, nonatomic) IBOutlet UILabel *labelValueNumClientTimeout;
@property (weak, nonatomic) IBOutlet UILabel *labelValueAverageAuctionTime;

@property (weak, nonatomic) IBOutlet UILabel *labelValueCurrentAuctionWinner;
@property (weak, nonatomic) IBOutlet UILabel *labelValueCurrentAuctionWinPrice;
@property (weak, nonatomic) IBOutlet UILabel *labelValueCurrentAuctionShown;
@property (weak, nonatomic) IBOutlet UILabel *labelValueCurrentAuctionPrice;
@property (weak, nonatomic) IBOutlet UILabel *labelValueCurrentImpressionFrom;
@property (weak, nonatomic) IBOutlet UILabel *labelValueThisAuctionTime;

@property (weak, nonatomic) IBOutlet UILabel *labelValueInternalErrorCount;
@property (weak, nonatomic) IBOutlet UILabel *labelValueConnectionErrorCount;

// To implement later
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *adLoadSActivityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *adLoadStepIndicator;

@end


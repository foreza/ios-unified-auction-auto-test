//
//  MetricMeasurement.h
//  UnifiedAuction Validator
//
//  Created by Jason C on 1/29/20.
//  Copyright © 2020 Jason C. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef MetricMeasurement_h
#define MetricMeasurement_h


@interface MetricMeasurement : NSObject


@property (strong, nonatomic) NSString *testUID;  // Need this for constructor

@property (strong, nonatomic) NSString *base_api_url;
@property (strong, nonatomic) NSString *ip_service_url;

@property (strong, nonatomic) NSString *device_name;
@property (strong, nonatomic) NSString *device_ip;
@property (strong, nonatomic) NSString *device_platform;
@property (strong, nonatomic) NSString *ad_request_geo;


@property long long timeAdReqBegin;
@property long long timeAdReqEnd;
@property long long timeElapsed;

- (instancetype)initWithUID:(NSString *)testUID;

- (void) setStartingMetricTime;
- (void) setEndMetricTime;
- (NSString*) returnStartingMetricTime;
- (NSString*) returnEndMetricTime;

- (NSString*) calculateTrackingTimeAndReturnValueForSendWithStart:(long long)start
                                    WithEnd:(long long) end;
- (void) fireMetricWithTime:(NSString* )timeElapsed
                   andStart:(NSString* ) startTime
                     andEnd:(NSString*) endTime
               forPlacement:(NSString* ) plc
                withSuccess:(BOOL) status;



@end

NS_ASSUME_NONNULL_END

#endif

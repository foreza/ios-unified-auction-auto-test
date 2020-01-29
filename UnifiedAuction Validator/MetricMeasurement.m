//
//  MetricMeasurement.m
//  UnifiedAuction Validator
//
//  Created by Jason C on 1/29/20.
//  Copyright © 2020 Jason C. All rights reserved.
//

#import "MetricMeasurement.h"

@implementation MetricMeasurement

NSMutableData *_responseData;               // Response data from the delegate (not being used)
//NSString * baseApiURL = @"http://107.170.192.117:8900/api/session/";

// Timing Tests
//long long timeAdReqBegin;
//long long timeAdReqEnd;
//long long timeElapsed;
//

- (instancetype)initWithUID:(NSString *)testUID{
    self = [super init];
    if (self) {
        _testUID = testUID;
        _base_api_url = @"http://107.170.192.117:8900/api/session/";    // TODO: find a way to do this better
    }
    return self;
}



- (void) setStartingMetricTime {
    self.timeAdReqBegin = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSString *timeTrackingString = [NSString stringWithFormat:@"%lld%@" , self.timeAdReqBegin, @" begin tracking time!"];
    NSLog(@"%@", timeTrackingString);
}

- (void) setEndMetricTime {
    self.timeAdReqEnd = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSString *timeTrackingString = [NSString stringWithFormat:@"%lld%@" , self.timeAdReqEnd, @" end tracking time!"];
    NSLog(@"%@", timeTrackingString);
}


- (NSString*) returnStartingMetricTime{
    double formatTimeToUse = (double)self.timeAdReqBegin;
    NSString *timeString = [NSString stringWithFormat:@"%f" , formatTimeToUse/1000.0];
    return timeString;
}


- (NSString*) returnEndMetricTime{
    double formatTimeToUse = (double)self.timeAdReqEnd;
    NSString *timeString = [NSString stringWithFormat:@"%f" , formatTimeToUse/1000.0];
    return timeString;
}


- (NSString*) calculateTrackingTimeAndReturnValueForSendWithStart:(long long)start WithEnd:(long long) end  {
    self.timeElapsed = (end - start);
    double formatTimeToSend = (double)self.timeElapsed;
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
    NSURL *url = [NSURL URLWithString:self.base_api_url];
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




@end

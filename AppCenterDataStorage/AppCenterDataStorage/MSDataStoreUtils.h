// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSDataStoreUtils : NSObject

/**
 * Deserialize string into `NSDate` instance.
 *
 * @param dateString String to deserialize.
 *
 * @return `NSDate` instance if `dateString` contains a valid date; nil otherwise.
 */
+ (NSDate *)deserializeDate:(NSString *)dateString;

/**
 * Serialize `NSDate` instance into a IS8601 formatted string.
 *
 * @param date Date to serialize.
 *
 * @return `NSString` instance representing the date in ISO 8601 format.
 */
+ (NSString *)serializeDate:(NSDate *)date;

@end

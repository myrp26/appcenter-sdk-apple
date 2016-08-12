/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 *
 * OpenAPI spec version: 1.0.0-preview20160708
 */

#import "AvalancheHub+Internal.h"
#import <Foundation/Foundation.h>

@interface AVAEventLog : AVALogWithProperties

/** Unique identifier for this event.
 */
@property(nonatomic) NSString *eventId;

/** Name of the event.
 */
@property(nonatomic) NSString *name;

@end
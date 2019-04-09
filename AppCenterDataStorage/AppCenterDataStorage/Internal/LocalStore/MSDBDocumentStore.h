// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDBStorage.h"
#import "MSDataStore.h"
#import "MSDocumentStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSDBDocumentStore : NSObject <MSDocumentStore>

/**
 * Create an instance of document store.
 *
 * @param dbStorage Database storage clinet.
 * @param schema Database schema.
 *
 * @return An intance of document store.
 */
- (instancetype)initWithDbStorage:(MSDBStorage *)dbStorage schema:(MSDBSchema *)schema;

/**
 * Get document table schema.
 *
 * @return Document table schema.
 */
+ (MSDBSchema *)documentTableSchema;

/**
 * Get column schema.
 *
 * @return Column schema.
 */
+ (MSDBColumnsSchema *)columnsSchema;

@end

NS_ASSUME_NONNULL_END
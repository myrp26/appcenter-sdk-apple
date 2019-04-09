// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSTestFrameworks.h"

@interface MSDBDocumentStoreTests : XCTestCase

@property(nonatomic, strong) MSDBStorage *dbStorag;
@property(nonatomic, strong) MSDBDocumentStore *sut;
@property(nonnull, strong) MSDBSchema *schema;

@end

@implementation MSDBDocumentStoreTests

- (void)setUp {
  [super setUp];
  self.schema = [MSDBDocumentStore documentTableSchema];
  self.dbStorag = [[MSDBStorage alloc] initWithSchema:self.schema version:0 filename:kMSDBDocumentFileName];
  self.sut = [[MSDBDocumentStore alloc] initWithDbStorage:self.dbStorag schema:self.schema];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testCreateOfApplicationLevelTable {

  // If
  NSUInteger expectedSchemaVersion = 1;
  MSDBSchema *expectedSchema = @{kMSAppDocumentTableName : [self expectedColumnSchema]};
  NSDictionary *expectedColumnIndexes = @{
    kMSAppDocumentTableName : @{
      kMSIdColumnName : @(0),
      kMSPartitionColumnName : @(1),
      kMSDocumentIdColumnName : @(2),
      kMSDocumentColumnName : @(3),
      kMSETagColumnName : @(4),
      kMSExpirationTimeColumnName : @(5),
      kMSDownloadTimeColumnName : @(6),
      kMSOperationTimeColumnName : @(7),
      kMSPendingDownloadColumnName : @(8)
    }
  };
  OCMStub([MSDBStorage columnsIndexes:expectedSchema]).andReturn(expectedColumnIndexes);

  // When
  self.sut = [MSDBDocumentStore new];

  // Then
  OCMVerify([self.sut.dbStorage initWithSchema:expectedSchema version:expectedSchemaVersion filename:kMSDBDocumentFileName]);
  OCMVerify([MSDBStorage columnsIndexes:expectedSchema]);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSIdColumnName] integerValue], self.sut.idColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName] integerValue], self.sut.partitionColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName] integerValue], self.sut.documentIdColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDocumentColumnName] integerValue], self.sut.documentColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSETagColumnName] integerValue], self.sut.eTagColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSExpirationTimeColumnName] integerValue],
                 self.sut.expirationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSDownloadTimeColumnName] integerValue],
                 self.sut.downloadTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSOperationTimeColumnName] integerValue],
                 self.sut.operationTimeColumnIndex);
  XCTAssertEqual([expectedColumnIndexes[kMSAppDocumentTableName][kMSPendingDownloadColumnName] integerValue],
                 self.sut.pendingOperationColumnIndex);
}

- (void)testCreationOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  // When
  [self.sut createUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorag createTable:tableName
                         columnsSchema:[self expectedColumnSchema]
               uniqueColumnsConstraint:[self expectedUniqueColumnsConstraint]]);
}

- (void)testDeletionOfUserLevelTable {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *userTableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];

  // When
  [self.sut deleteUserStorageWithAccountId:expectedAccountId];

  // Then
  OCMVerify([self.dbStorag dropTable:userTableName]);
}

- (void)testDeletionOfAllTables {

  // If
  NSString *expectedAccountId = @"Test-account-id";
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, expectedAccountId];
  [self.sut createUserStorageWithAccountId:expectedAccountId];
  OCMVerify([self.dbStorag createTable:tableName columnsSchema:[self expectedColumnSchema]]);
  XCTAssertTrue([self tableExists:tableName]);

  // When
  [self.sut deleteAllTables];

  // Then
  XCTAssertFalse([self tableExists:tableName]);
}

- (MSDBColumnsSchema *)expectedColumnSchema {
  return @[
    @{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]},
    @{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]},
    @{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}, @{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]},
    @{kMSETagColumnName : @[ kMSSQLiteTypeText ]}, @{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}, @{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]},
    @{kMSPendingDownloadColumnName : @[ kMSSQLiteTypeText ]}
  ];
}

- (BOOL)tableExists:(NSString *)tableName {
  NSArray<NSArray *> *result = [self.dbStorag
      executeSelectionQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM \"sqlite_master\" WHERE \"type\"='table' AND \"name\"='%@';",
                                                       tableName]];
  return [(NSNumber *)result[0][0] boolValue];
}

- (NSArray<NSString *> *)expectedUniqueColumnsConstraint {
  return @[ kMSPartitionColumnName, kMSDocumentIdColumnName ];
}

@end
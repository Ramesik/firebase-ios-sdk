/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "Firestore/Source/Remote/FSTDatastore.h"

#import <FirebaseFirestore/FIRFirestoreErrors.h>
#import <GRPCClient/GRPCCall.h>
#import <XCTest/XCTest.h>

@interface FSTDatastoreTests : XCTestCase
@end

@implementation FSTDatastoreTests

- (void)testIsPermanentWriteError {
  // From GRPCCall -cancel
  NSError *error = [NSError errorWithDomain:FIRFirestoreErrorDomain
                                       code:FIRFirestoreErrorCodeCancelled
                                   userInfo:@{NSLocalizedDescriptionKey : @"Canceled by app"}];
  XCTAssertFalse([FSTDatastore isPermanentWriteError:error previousError:nil]);

  // From GRPCCall -startNextRead
  error =
      [NSError errorWithDomain:FIRFirestoreErrorDomain
                          code:FIRFirestoreErrorCodeResourceExhausted
                      userInfo:@{
                        NSLocalizedDescriptionKey :
                            @"Client does not have enough memory to hold the server response."
                      }];
  XCTAssertFalse([FSTDatastore isPermanentWriteError:error previousError:nil]);

  // From GRPCCall -startWithWriteable
  error = [NSError errorWithDomain:FIRFirestoreErrorDomain
                              code:FIRFirestoreErrorCodeUnavailable
                          userInfo:@{NSLocalizedDescriptionKey : @"Connectivity lost."}];
  XCTAssertFalse([FSTDatastore isPermanentWriteError:error previousError:nil]);

  // User info doesn't matter:
  error = [NSError errorWithDomain:FIRFirestoreErrorDomain
                              code:FIRFirestoreErrorCodeUnavailable
                          userInfo:nil];
  XCTAssertFalse([FSTDatastore isPermanentWriteError:error previousError:nil]);

  // Upon first encounter, "unauthenticated" is considered a recoverable error due to expired token.
  error = [NSError errorWithDomain:FIRFirestoreErrorDomain
                              code:FIRFirestoreErrorCodeUnauthenticated
                          userInfo:nil];
  XCTAssertFalse([FSTDatastore isPermanentWriteError:error previousError:nil]);

  // If "unauthenticated" is repeated twice in a row, the error is probably due to something else,
  // so it's considered unrecoverable.
  error = [NSError errorWithDomain:FIRFirestoreErrorDomain
                              code:FIRFirestoreErrorCodeUnauthenticated
                          userInfo:nil];
  XCTAssertTrue([FSTDatastore isPermanentWriteError:error previousError:error]);
}

@end

//
//  AFAsyncProcessingHTTPRequestOperation.h
//  EQDocs
//
//  Created by Paul Melnikow on 5/23/13.
//
//

#import "AFHTTPRequestOperation.h"

@interface AFAsyncProcessingHTTPRequestOperation : AFHTTPRequestOperation

- (instancetype) initWithRequest:(NSURLRequest *)urlRequest processingQueue:(dispatch_queue_t) processingQueue;

// Subclasses must override. The result will be returned as `-responseObject`.
// This method will be invoked on processingQueue
// It should return the response object
// It's guaranteed to be called only once per operation
// error is guaranteed to be non-nil
- (id) handleSuccessWithError:(NSError **) outError;

// Subclasses may override these.

// The default implementation sets *error to [super error] and returns nil
- (id) handleFailureWithError:(NSError **) outError;

// Subclasses may override
+ (NSSet *) acceptableContentTypes;
+ (BOOL) canProcessRequest:(NSURLRequest *) request;

// Subclasses should not override
- (NSError *) error;
- (id) responseObject;

- (void) setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject)) success
                               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error)) failure;

@end

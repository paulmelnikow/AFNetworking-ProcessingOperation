//
//  AFAsyncProcessingHTTPRequestOperation.m
//  EQDocs
//
//  Created by Paul Melnikow on 5/23/13.
//
//

#import "AFAsyncProcessingHTTPRequestOperation.h"

@interface AFURLConnectionOperation ()
- (void) finish;
@end

@interface AFAsyncProcessingHTTPRequestOperation ()
@property (readwrite, nonatomic) dispatch_queue_t processingQueue;
@property (readwrite, nonatomic, retain) id privateResponseObject;
@property (readwrite, nonatomic, retain) NSError *privateError;
@property (assign) BOOL didFinishProcessing;
@end

@implementation AFAsyncProcessingHTTPRequestOperation
@synthesize processingQueue = _processingQueue;

#pragma mark - Initialization


- (instancetype) initWithRequest:(NSURLRequest *)urlRequest processingQueue:(dispatch_queue_t) processingQueue {
    if (self = [super initWithRequest:urlRequest]) {
        self.processingQueue = processingQueue;
    }
    return self;
}


- (instancetype) initWithRequest:(NSURLRequest *)urlRequest {
    [NSException raise:NSInvalidArgumentException format:@"Use the designated initializer -initWithRequest:processingQueue:"];
    return self = nil;
}


- (void) dealloc {
    if (_processingQueue) {
#if !OS_OBJECT_USE_OBJC
        dispatch_release(_processingQueue);
#endif
        _processingQueue = NULL;
    }
}


#pragma mark - Processing queue and completion handler


+ (dispatch_queue_t) defaultProcessingQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.alamofire.networking.asyncprocessing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return queue;
}


- (void)setProcessingQueue:(dispatch_queue_t)processingQueue {
    if (processingQueue != _processingQueue) {
        if (_processingQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_release(_processingQueue);
#endif
            _processingQueue = NULL;
        }
        
        if (processingQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(processingQueue);
#endif
            _processingQueue = processingQueue;
        }
    }
}


- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    // completionBlock is manually nilled out in AFURLConnectionOperation to break the retain cycle.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.completionBlock = ^{
        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            if (success) {
                dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                    success(self, self.responseObject);
                });
            }
        }
    };
#pragma clang diagnostic pop
}

#pragma mark - Processing and processing result


- (void) finish {
    dispatch_async(self.processingQueue ?: [self.class defaultProcessingQueue], ^{
        @try {
            NSError *error = [super error];
            if (error)
                self.privateResponseObject = [self handleFailureWithError:&error];
            else
                self.privateResponseObject = [self handleSuccessWithError:&error];
            self.privateError = error;
        }
        @catch (id exception) {
            @throw;
        }
        @finally {
            self.didFinishProcessing = YES;
            [super finish];
        }
    });
}


- (id) responseObject {
    if (!self.didFinishProcessing) {
        [NSException raise:NSInvalidArgumentException
                    format:@"-responseObject invoked before processing finished"];
        return nil;
    }
    return self.privateResponseObject;
}


- (NSError *) error {
    if (!self.didFinishProcessing) {
        [NSException raise:NSInvalidArgumentException
                    format:@"-error invoked before processing finished"];
        return nil;
    }
    return self.privateError;
}


#pragma mark - Methods for subclasses to override


- (id) handleSuccessWithError:(NSError **) outError {
    [NSException raise:NSInvalidArgumentException format:@"Subclasses must override"];
    return nil;
}


- (id) handleFailureWithError:(NSError **) outError {
    *outError = [super error];
    return nil;
}


+ (NSSet *) acceptableContentTypes { return [super acceptableContentTypes]; };


+ (BOOL) canProcessRequest:(NSURLRequest *) request { return [super canProcessRequest:request]; }


@end

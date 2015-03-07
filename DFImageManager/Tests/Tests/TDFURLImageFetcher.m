//
//  TDFURLImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 1/22/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTestingKit.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


/*! The TDFURLImageFetcher is a test suite for DFURLImageFetcher class.
 */
@interface TDFURLImageFetcher : XCTestCase

@end

@implementation TDFURLImageFetcher {
    DFURLImageFetcher *_fetcher;
}

- (void)setUp {
    [super setUp];

    _fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (void)tearDown {
    [super tearDown];
    
    [OHHTTPStubs removeAllStubs];
}

#pragma mark - Canonical Requests

- (void)testThatCanonicalRequestCreatesFetcherSpecificOptionsWithoutOverridingInitialOptions {
    // Create options with non-default parameters.
    DFImageRequestOptions *options = TDFCreateRequestOptionsWithNotDefaultParameters();
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFit options:options];
    
    DFImageRequest *canonicalRequest = [_fetcher canonicalRequestForRequest:[request copy]];
    
    XCTAssertTrue([canonicalRequest.resource isEqual:[NSURL URLWithString:@"http://path/resourse"]]);
    XCTAssertTrue(CGSizeEqualToSize(canonicalRequest.targetSize, CGSizeMake(100.f, 100.f)));
    XCTAssertTrue(canonicalRequest.contentMode == DFImageContentModeAspectFit);
    
    XCTAssertTrue([canonicalRequest.options isKindOfClass:[DFURLImageRequestOptions class]]);
    
    DFURLImageRequestOptions *canonicalOptions = (DFURLImageRequestOptions *)canonicalRequest.options;
    XCTAssertTrue(canonicalOptions.cachePolicy == NSURLRequestUseProtocolCachePolicy);
    XCTAssertTrue(canonicalOptions != options);
    TDFAssertBaseOptionsAreEqual(options, canonicalOptions);
}

- (void)testThatCanonicalRequestCreatesFetcherSpecificOptionsWhenInitialsOptionsAreNil {
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse"] targetSize:CGSizeMake(100.f, 100.f) contentMode:DFImageContentModeAspectFit options:nil];
    
    DFImageRequest *canonicalRequest = [_fetcher canonicalRequestForRequest:[request copy]];
    XCTAssertTrue([canonicalRequest.options isKindOfClass:[DFURLImageRequestOptions class]]);
    
    DFURLImageRequestOptions *canonicalOptions = (DFURLImageRequestOptions *)canonicalRequest.options;
    XCTAssertTrue(canonicalOptions.cachePolicy == NSURLRequestUseProtocolCachePolicy);
    
    TDFAssertDefaultOptionsAreValid(canonicalOptions);
}

- (void)testThatCanonicalRequestDoesntRewriteFetcherSpecificOptions {
    DFURLImageRequestOptions *options = [DFURLImageRequestOptions new];
    options.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse"] targetSize:CGSizeMake(100.f, 100.f) contentMode:   DFImageContentModeAspectFit options:options];
    
    DFImageRequest *canonicalRequest = [_fetcher canonicalRequestForRequest:[request copy]];
    XCTAssertTrue([canonicalRequest.options isKindOfClass:[DFURLImageRequestOptions class]]);
    
    DFURLImageRequestOptions *canonicalOptions = (DFURLImageRequestOptions *)canonicalRequest.options;
    XCTAssertTrue(canonicalOptions.cachePolicy == NSURLRequestReturnCacheDataDontLoad);
    
    TDFAssertDefaultOptionsAreValid(options);
}

#pragma mark - Request Cache Equivalence

- (void)testThatRequestsWithTheSameURLAreCacheEquivalent {
    DFImageRequest *request1 = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse"]];
    DFImageRequest *request2 = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse"]];
    XCTAssertTrue([_fetcher isRequestCacheEquivalent:request1 toRequest:request2]);
}

- (void)testThatRequestsWithDifferentURLsAreNotCacheEquivalent {
    DFImageRequest *request1 = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse_01"]];
    DFImageRequest *request2 = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:@"http://path/resourse_02"]];
    XCTAssertFalse([_fetcher isRequestCacheEquivalent:request1 toRequest:request2]);
}

#pragma mark - Schemes

/*! Test 'file' scheme
 */
- (void)testThatURLFetcherSupportsFileSystemURL {
    NSURL *fileURL = [TDFTesting testImageURL];
    
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:fileURL];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_completed"];
    request = [_fetcher canonicalRequestForRequest:request];
    [_fetcher startOperationWithRequest:request progressHandler:nil completion:^(DFImageResponse *response) {
        XCTAssertNotNil(response.image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

/*! Test 'data' scheme
 */
- (void)testThatURLImageFetcherSupportsDataScheme {
    NSData *imgData = [TDFTesting testImageData];
    NSString *dataFormatString = @"data:image/png;base64,%@";
    NSString *dataString = [NSString stringWithFormat:dataFormatString, [imgData base64EncodedStringWithOptions:0]];
    NSURL *dataURL = [NSURL URLWithString:dataString];
    
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:dataURL];
    XCTAssertTrue([_fetcher canHandleRequest:request]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetch_completed"];
    [_fetcher startOperationWithRequest:[_fetcher canonicalRequestForRequest:request] progressHandler:nil completion:^(DFImageResponse *response) {
        XCTAssertNotNil(response.image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

@end

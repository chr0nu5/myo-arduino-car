//
//  Myo_Arduino_CarTests.m
//  Myo-Arduino-CarTests
//
//  Created by Jonathan Querubina on 4/3/15.
//  Copyright (c) 2015 Jonathan Querubina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface Myo_Arduino_CarTests : XCTestCase

@end

@implementation Myo_Arduino_CarTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

//
//  FileObjectProxyTest.m
//  BlueLocalization
//
//  Created by Max Seelemann on 07.05.09.
//  Copyright 2009 The Blue Technologies Group. All rights reserved.
//

#import "ObjectProxyTest.h"

#import <BlueLocalization/BLStringKeyObject.h>
#import <BlueLocalization/BLStringsFileObject.h>
#import <OCMock/OCMock.h>
#import <objc/runtime.h>

#define HC_SHORTHAND
#import <hamcrest/hamcrest.h>


@implementation ObjectProxyTest

- (void)setUp
{
	object1 = [BLFileObject fileObjectWithPathExtension: @"strings"];
	object2 = [BLFileObject fileObjectWithPathExtension: @"strings"];
	proxy = [BLObjectProxy proxyWithObject: object1];
	pObject = (BLFileObject *)proxy;
	
	path = [self pathForFile: @"simple"];
}

- (NSString *)pathForFile:(NSString *)file
{
	return [[NSBundle bundleForClass: [self class]] pathForResource:file ofType:@"strings" inDirectory:@"Test Data/Strings/specific"];
}

- (void)testCreation
{
	STAssertTrue([proxy class] == [BLStringsFileObject class], @"Direct question should NOT reveal identity");
	STAssertTrue(object_getClass(proxy) == [BLObjectProxy class], @"Only runtime should reveal identity");
	STAssertTrue([proxy isKindOfClass: [BLFileObject class]], @"Should pose as a file object");
	STAssertFalse([proxy isKindOfClass: [BLKeyObject class]], @"Should not pose as a key object");
}

- (void)testAccessors
{
	[pObject setBundleObject: [BLBundleObject bundleObject]];
	[pObject setFlags: 0];
	
	STAssertTrue([[pObject bundleObject] isKindOfClass: [BLBundleObject class]], @"returned bundle of wrong class");
	STAssertTrue(object_getClass([pObject bundleObject]) == [BLObjectProxy class], @"returned bundle should actually be a proxy again");
	
	for (NSUInteger i=0; i<4; i++) {
		id object = [pObject objectForKey:[NSString stringWithFormat:@"blah%d", i] createIfNeeded:YES];
		STAssertTrue([object isKindOfClass: [BLKeyObject class]], @"key of wrong class");
		STAssertTrue(object_getClass(object) == [BLObjectProxy class], @"key should actually be a proxy again");
	}
	
	for (id object in [pObject objects]) {
		STAssertTrue([object isKindOfClass: [BLKeyObject class]], @"key of wrong class");
		STAssertTrue(object_getClass(object) == [BLObjectProxy class], @"key should actually be a proxy again");
	}
}

- (void)testInterpetation
{
	[[BLFileInterpreter interpreterForFileType: @"string"] interpreteFile:path intoObject:object2 withLanguage:@"en" referenceLanguage:nil];
	[[BLFileInterpreter interpreterForFileType: @"string"] interpreteFile:path intoObject:pObject withLanguage:@"en" referenceLanguage:nil];
	
	for (BLKeyObject *keyObject in [object2 objects]) {
		STAssertNotNil([pObject objectForKey: [keyObject key]], @"Key object does not exist");
		STAssertEquals([[pObject objectForKey: [keyObject key]] objectForLanguage: @"en"], [keyObject objectForLanguage: @"en"], @"String values don't match");
	}
}

- (void)testArguments
{
	BLKeyObject *keyObject;
	BLObjectProxy *pxy;
	BOOL yes = YES;
	id mock;
	
	// Set up environment
	mock = [OCMockObject mockForClass: [BLFileObject class]];
	[[[mock stub] andReturnValue: [NSValue value:&yes withObjCType:@encode(BOOL)]] isKindOfClass: OCMOCK_ANY];
	
	pxy = [BLObjectProxy proxyWithObject: mock];
	keyObject = [BLStringKeyObject keyObjectWithKey: @"hallo"];
	
	// Make a plan
	[[[mock stub] andReturn: keyObject] objectForKey: OCMOCK_ANY];
	
	[[mock expect] addObject: keyObject];
	[[mock expect] addObject: keyObject];
	[[mock expect] setObjects: (id)equalTo([NSArray arrayWithObject: keyObject])];
	
	// Run the plan
	[(id)pxy addObject: keyObject];
	keyObject = [(id)pxy objectForKey: nil];
	[(id)pxy addObject: keyObject];
	[(id)pxy setObjects: [NSArray arrayWithObject: keyObject]];
	
	// Verify
	[mock verify];
}

- (void)testChains
{
	[[BLBundleObject bundleObject] setFiles: [NSArray arrayWithObject: object1]];
	[object1 objectForKey:@"hups" createIfNeeded:YES];
	
	STAssertTrue(object_getClass(pObject) == [BLObjectProxy class], @"object should be a proxy");
	STAssertTrue(object_getClass([pObject bundleObject]) == [BLObjectProxy class], @"object should actually be a proxy again");
	STAssertTrue(object_getClass([[pObject bundleObject] files].lastObject) == [BLObjectProxy class], @"object should actually be a proxy again");
	STAssertTrue(object_getClass(((BLKeyObject*)pObject.objects.lastObject).fileObject) == [BLObjectProxy class], @"object should actually be a proxy again");
	STAssertTrue(object_getClass(((BLObject*)pObject.bundleObject.files.lastObject).objects.lastObject) == [BLObjectProxy class], @"object should actually be a proxy again");
	STAssertTrue(object_getClass(((BLKeyObject*)((BLObject*)pObject.bundleObject.files.lastObject).objects.lastObject).fileObject) == [BLObjectProxy class], @"object should actually be a proxy again");
}

- (void)testOrdinaryObjects
{
	STAssertNil([BLObjectProxy proxyWithObject: nil], @"No proxy for no object");
	STAssertThrows([BLObjectProxy proxyWithObject: (BLObject *)@"hallo"], @"Should throw for non-BLObject arguments");
}

@end

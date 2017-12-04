//
//  DXApplication.h
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/27/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CNContact, DXContactModel;

#define sApplication [DXApplication sharedInstance]

@interface DXApplication : NSObject

+ (id)sharedInstance;

/**
 Sort DXContactModel array and decide it to some sections,
 earch section is an array with sectintitle (NSString) and some rows data (DXContactModel)

 @param data : array of section
 @return : array of section data
 */
- (NSArray<NSArray *> *)sectionsArraySectionedWithData:(NSArray<DXContactModel *> *)data;

/**
 Sort DXContactModel array and add some section's titles for array
 to provide data for sectioned tableviewmodel
 
 @param data : array of DXContactModel objects
 @return : sectioned array with arranged DXContactModel objects and section titles
 */
- (NSArray *)arrangeSectionedWithData:(NSArray<DXContactModel *> *)data;

/**
 Sort DXContactModel array to provide data for sectioned tableviewmodel
 
 @param data : array of DXContactModel objects
 @return : array of arranged DXContactModel objects
 */
- (NSArray *)arrangeNonSectionedWithData:(NSArray<DXContactModel *> *)data;

/**
 Create new DXContactModel from CNContact

 @param contact : CNContact object
 @return : nullable DXContactModel object
 */
- (id)parseContactModelFromCNContact:(CNContact *)contact;

@end

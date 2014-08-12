//
//  MapPoint.h
//  BasicMap
//
//  Created by Mike Holp on 12/21/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapPoint : NSObject<MKAnnotation>
@property (nonatomic, copy) NSString *title;
@property (assign) NSInteger tag;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title tag:(NSInteger)tag;

@end

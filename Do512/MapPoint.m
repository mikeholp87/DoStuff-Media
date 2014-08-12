//
//  MapPoint.m
//  BasicMap
//
//  Created by Mike Holp on 12/21/13.
//  Copyright (c) 2013 Mike Holp. All rights reserved.
//

#import "MapPoint.h"

@implementation MapPoint

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)title tag:(NSInteger)tag
{
    if(self = [super init]){
        self.coordinate = coordinate;
        self.title = title;
        self.tag = tag;
    }
    
    return self;
}

@end

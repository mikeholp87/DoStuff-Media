//
//  EventsTable.h
//  Do512
//
//  Created by Michael Holp on 2/11/14.
//  Copyright (c) 2014 Flash. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

typedef void (^ReverseGeoCompletionBlock)(NSString *city, NSString *state);

@interface EventsTable : UITableViewController<CLLocationManagerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, MKMapViewDelegate, NSURLConnectionDelegate>

@property(nonatomic,retain) CLLocationManager *locMgr;

@property(nonatomic) CLLocationCoordinate2D userCoordinate;
@property(nonatomic) CLLocationCoordinate2D venueCoordinate;
@property(nonatomic,retain) NSMutableDictionary *events;
@property(nonatomic,retain) NSDictionary *layout;
@property(nonatomic,retain) NSDictionary *searchResults;
@property(nonatomic,retain) NSString *category;
@property(nonatomic,retain) NSString *areacode;
@property(nonatomic,retain) NSString *grouped;
@property(nonatomic,retain) NSDateFormatter *df;

@property(nonatomic,retain) UISearchDisplayController *searchDisplayController;
@property(nonatomic,retain) UIActivityIndicatorView *activityIndicator;
@property(nonatomic,retain) UISearchBar *searchBar;

@property(nonatomic,retain) IBOutlet MKMapView *mapView;

@end

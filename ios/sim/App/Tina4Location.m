#import <CoreLocation/CoreLocation.h>

extern void tina4_location_result(int status, double latitude, double longitude,
                                  double accuracy, double altitude, double speed,
                                  double timestamp, const char *error);

static void Tina4LocationNotifyView(void) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"Tina4LocationReady" object:nil];
}

@interface Tina4LocationDelegate : NSObject <CLLocationManagerDelegate>
@property(nonatomic, strong) CLLocationManager *manager;
@property(nonatomic, assign) BOOL requesting;
@property(nonatomic, assign) BOOL backgroundRequested;
@end

@implementation Tina4LocationDelegate
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    CLAuthorizationStatus status = manager.authorizationStatus;
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        tina4_location_result(4, 0, 0, 0, 0, 0, 0, "location permission denied");
        Tina4LocationNotifyView();
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
             status == kCLAuthorizationStatusAuthorizedAlways)
        if (self.requesting) {
            manager.allowsBackgroundLocationUpdates = self.backgroundRequested;
            [manager startUpdatingLocation];
        }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    if (!location) return;
    tina4_location_result(0, location.coordinate.latitude, location.coordinate.longitude,
                          location.horizontalAccuracy, location.altitude, location.speed,
                          location.timestamp.timeIntervalSince1970, NULL);
    Tina4LocationNotifyView();
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // Core Location reports kCLErrorLocationUnknown (code 0) transiently
    // while the simulator/device is acquiring or switching coordinates. It
    // is not a terminal failure and should not reach the application log.
    if (error.code == kCLErrorLocationUnknown) return;
    int status = (error.code == kCLErrorDenied) ? 4 : 7;
    tina4_location_result(status, 0, 0, 0, 0, 0, 0, error.localizedDescription.UTF8String);
    Tina4LocationNotifyView();
}
@end

static Tina4LocationDelegate *Tina4LocationShared;
static Tina4LocationDelegate *Tina4LocationGet(void) {
    if (!Tina4LocationShared) {
        Tina4LocationShared = [Tina4LocationDelegate new];
        Tina4LocationShared.manager = [CLLocationManager new];
        Tina4LocationShared.manager.delegate = Tina4LocationShared;
        Tina4LocationShared.manager.desiredAccuracy = kCLLocationAccuracyBest;
        Tina4LocationShared.manager.distanceFilter = kCLDistanceFilterNone;
        Tina4LocationShared.manager.pausesLocationUpdatesAutomatically = NO;
    }
    return Tina4LocationShared;
}
void tina4_ios_location_request(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ [Tina4LocationGet().manager requestWhenInUseAuthorization]; });
}
void tina4_ios_location_start(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Tina4LocationDelegate *delegate = Tina4LocationGet();
        delegate.requesting = YES;
        delegate.backgroundRequested = NO;
        CLLocationManager *manager = delegate.manager;
        manager.allowsBackgroundLocationUpdates = NO;
        if (manager.authorizationStatus == kCLAuthorizationStatusNotDetermined)
            [manager requestWhenInUseAuthorization];
        else if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
                 manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
            [manager startUpdatingLocation];
        else if (manager.authorizationStatus == kCLAuthorizationStatusDenied ||
                 manager.authorizationStatus == kCLAuthorizationStatusRestricted) {
            tina4_location_result(4, 0, 0, 0, 0, 0, 0, "location permission denied");
            Tina4LocationNotifyView();
        }
    });
}
void tina4_ios_location_start_background(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Tina4LocationDelegate *delegate = Tina4LocationGet();
        delegate.requesting = YES;
        delegate.backgroundRequested = YES;
        CLLocationManager *manager = delegate.manager;
        manager.allowsBackgroundLocationUpdates = YES;
        if (manager.authorizationStatus == kCLAuthorizationStatusNotDetermined ||
            manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse)
            [manager requestAlwaysAuthorization];
        else if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
            [manager startUpdatingLocation];
        else if (manager.authorizationStatus == kCLAuthorizationStatusDenied ||
                 manager.authorizationStatus == kCLAuthorizationStatusRestricted) {
            tina4_location_result(4, 0, 0, 0, 0, 0, 0, "location permission denied");
            Tina4LocationNotifyView();
        }
    });
}
void tina4_ios_location_stop(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Tina4LocationDelegate *delegate = Tina4LocationGet();
        delegate.requesting = NO;
        delegate.backgroundRequested = NO;
        delegate.manager.allowsBackgroundLocationUpdates = NO;
        [delegate.manager stopUpdatingLocation];
    });
}

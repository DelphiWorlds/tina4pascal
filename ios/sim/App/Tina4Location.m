#import <CoreLocation/CoreLocation.h>

extern void tina4_location_result(int status, double latitude, double longitude,
                                  double accuracy, double altitude, double speed,
                                  double timestamp, const char *error);

@interface Tina4LocationDelegate : NSObject <CLLocationManagerDelegate>
@property(nonatomic, strong) CLLocationManager *manager;
@property(nonatomic, assign) BOOL requesting;
@end

@implementation Tina4LocationDelegate
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    CLAuthorizationStatus status = manager.authorizationStatus;
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
        tina4_location_result(4, 0, 0, 0, 0, 0, 0, "location permission denied");
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
             status == kCLAuthorizationStatusAuthorizedAlways)
        if (self.requesting) [manager startUpdatingLocation];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    if (!location) return;
    tina4_location_result(0, location.coordinate.latitude, location.coordinate.longitude,
                          location.horizontalAccuracy, location.altitude, location.speed,
                          location.timestamp.timeIntervalSince1970, NULL);
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    int status = (error.code == kCLErrorDenied) ? 4 : 6;
    tina4_location_result(status, 0, 0, 0, 0, 0, 0, error.localizedDescription.UTF8String);
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
        CLLocationManager *manager = delegate.manager;
        if (manager.authorizationStatus == kCLAuthorizationStatusNotDetermined)
            [manager requestWhenInUseAuthorization];
        else if (manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
                 manager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
            [manager startUpdatingLocation];
        else if (manager.authorizationStatus == kCLAuthorizationStatusDenied ||
                 manager.authorizationStatus == kCLAuthorizationStatusRestricted)
            tina4_location_result(4, 0, 0, 0, 0, 0, 0, "location permission denied");
    });
}
void tina4_ios_location_stop(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Tina4LocationDelegate *delegate = Tina4LocationGet();
        delegate.requesting = NO; [delegate.manager stopUpdatingLocation];
    });
}

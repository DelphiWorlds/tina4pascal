#import <UIKit/UIKit.h>

// Status values mirror TTina4CapabilityStatus in Tina4Capabilities.pas:
// success=0, started=1, unsupported=2, invalid=3, permission=4,
// unavailable=5, cancelled=6, failed=7.
extern void tina4_share_result(int status, const char *activity, const char *error);

static void Tina4ShareResult(int status, NSString *activity, NSString *error) {
    tina4_share_result(status, activity.UTF8String ?: "", error.UTF8String ?: "");
}

void tina4_ios_share_items(const char *json, const char *anchor) {
    NSString *source = json ? [NSString stringWithUTF8String:json] : @"[]";
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError = nil;
    id decoded = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
    if (![decoded isKindOfClass:[NSArray class]]) {
        Tina4ShareResult(7, @"", parseError.localizedDescription ?: @"invalid share payload");
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *items = [NSMutableArray array];
        for (NSDictionary *entry in (NSArray *)decoded) {
            if (![entry isKindOfClass:[NSDictionary class]]) continue;
            NSString *kind = entry[@"kind"];
            NSString *value = entry[@"value"];
            if (![kind isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSString class]]) continue;
            if ([kind isEqualToString:@"text"])
                [items addObject:value];
            else if ([[NSFileManager defaultManager] fileExistsAtPath:value])
                [items addObject:[NSURL fileURLWithPath:value]];
        }
        if (items.count == 0) {
            Tina4ShareResult(3, @"", @"no shareable items");
            return;
        }

        UIViewController *presenter = UIApplication.sharedApplication.keyWindow.rootViewController;
        while (presenter.presentedViewController) presenter = presenter.presentedViewController;
        if (!presenter) {
            Tina4ShareResult(5, @"", @"no presenting view controller");
            return;
        }
        UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                            applicationActivities:nil];
        vc.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed,
                                          NSArray *returnedItems, NSError *activityError) {
            Tina4ShareResult(activityError ? 7 : (completed ? 0 : 6),
                             activityType ?: @"", activityError.localizedDescription ?: @"");
        };
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            vc.popoverPresentationController.sourceView = presenter.view;
            vc.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
                                                                      CGRectGetMidY(presenter.view.bounds), 1, 1);
        }
        [presenter presentViewController:vc animated:YES completion:nil];
    });
}

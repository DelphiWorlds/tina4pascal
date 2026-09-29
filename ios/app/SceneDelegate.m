#import "SceneDelegate.h"
#import "Tina4ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
 willConnectToSession:(UISceneSession *)session
        options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [Tina4ViewController new];
    [self.window makeKeyAndVisible];
}

@end

//
//  AppDelegate.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/20/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "AppDelegate.h"
#import "DXHomeViewController.h"
#import "DXViewController.h"
#import "DXFilesViewController.h"
#import "DXDownloadViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:128 * 1024 * 1024
                                                         diskCapacity:1024 * 1024 * 1024
                                                             diskPath:@"com.nhuduydoan.downloadmanager"];
    [NSURLCache setSharedURLCache:urlCache];
    
    CGRect screen =  [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:screen];
    [self setupRootViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)setupRootViewController {
    
    UITabBarController *tabbarController = [[UITabBarController alloc] init];
    [tabbarController setViewControllers:[self viewControllers]];
    self.window.rootViewController = tabbarController;
}

- (NSArray *)viewControllers {
    
    DXHomeViewController *contactsViewController = [DXHomeViewController new];
    contactsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Contacts" image:[UIImage imageNamed:@"tab_contact"] selectedImage:[UIImage imageNamed:@"tab_contact"]];
    UINavigationController *navContacts = [[UINavigationController alloc] initWithRootViewController:contactsViewController];
    
    DXDownloadViewController *downloadsController = [[DXDownloadViewController alloc] init];
    downloadsController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Downloads" image:[UIImage imageNamed:@"tab_download"] selectedImage:[UIImage imageNamed:@"tab_download"]];
    UINavigationController *navDownloads = [[UINavigationController alloc] initWithRootViewController:downloadsController];
    
    DXFilesViewController *filesController = [[DXFilesViewController alloc] init];
    filesController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:[UIImage imageNamed:@"tab_file"] selectedImage:[UIImage imageNamed:@"tab_file"]];
    UINavigationController *navFiles = [[UINavigationController alloc] initWithRootViewController:filesController];
    
    return @[navContacts, navDownloads, navFiles];
}

- (void)application:(UIApplication *)application handleIntent:(INIntent *)intent completionHandler:(void (^)(INIntentResponse * _Nonnull))completionHandler {
    
}
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler {
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end

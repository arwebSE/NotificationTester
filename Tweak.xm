#include "headers.h"
#include "sqlite3.h"
#include "Globals.m"

@implementation NotificationTester
//Query application list from applications database and filter out apple identifiers
+ (NSString *)randomID {
  NSMutableArray * applications =[[NSMutableArray alloc] init];
  NSString *filePath = @"/private/var/mobile/Library/FrontBoard/applicationState.db";
  sqlite3* db = NULL;
  sqlite3_stmt* stmt =NULL;
  int rc=0;
  rc = sqlite3_open_v2([filePath UTF8String], &db, SQLITE_OPEN_READONLY , NULL);
  if (SQLITE_OK != rc) {
    sqlite3_close(db);
    NSLog(@"Failed to open db connection");
  }
  else {
    NSString  * query = @"SELECT * from application_identifier_tab";

    rc =sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL);
    if(rc == SQLITE_OK) {
      while (sqlite3_step(stmt) == SQLITE_ROW) {
        NSString * name =[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];

        NSDictionary *app = [NSDictionary dictionaryWithObjectsAndKeys:name,@"id", nil];
        if (![excludedApps containsObject:name]) {
          [applications addObject:app];
        }
      }
      sqlite3_finalize(stmt);
    }
    else {
      NSLog(@"Failed to prepare statement with rc:%d",rc);
    }
    sqlite3_close(db);
  }
  [applications retain];
  [applications release];
  return [[applications objectAtIndex:arc4random() % [applications count]] valueForKey:@"id"];
}

//Lockscreen notifications (dispatch timer to wait for the screen to lock)
+ (void)lockscreenNotification {
  [[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    bundleID = @"com.apple.Preferences";
    for (int i = 0; i < customAmount; i++) {
      if (randomApps) {
        bundleID = [self randomID];
      }
      [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"NotificationTester" message:customText bundleID:bundleID];
    }
  });
}

//How normal notifications
+ (void)normalNotification {
  bundleID = @"com.apple.Preferences";
  for (int i = 0; i < customAmount; i++) {
    if (randomApps) {
      bundleID = [self randomID];
    }
    [[objc_getClass("JBBulletinManager") sharedInstance] showBulletinWithTitle:@"NotificationTester" message:customText bundleID:bundleID];
  }
}
@end

//Show message after installation
%hook SBDashBoardViewController
- (void)viewDidAppear:(_Bool)arg1 {
  %orig;
  if([[NSDictionary dictionaryWithContentsOfFile:welcomeMessage] objectForKey:@"Message"] == nil) {
    UIAlertController *alertController1 = [UIAlertController alertControllerWithTitle:@"NotificationTester" message:@"\nThanks for downloading NotificationTester!\n\nThis tweak is free, but a lot of work was put into this.\nA donation is highly appreciated but never required!" preferredStyle:UIAlertControllerStyleAlert];
      [alertController1 addAction:[UIAlertAction actionWithTitle:@"Donate! (:" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSMutableDictionary *preferences = [NSMutableDictionary dictionary];
        [preferences addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:welcomeMessage]];
        [preferences setObject:@"What are you doing here, you peasant?!" forKey:@"Message"];
        [preferences writeToFile:welcomeMessage atomically:YES];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DaniWinter"]];
      }]];
      [alertController1 addAction:[UIAlertAction actionWithTitle:@"No thanks." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSMutableDictionary *preferences = [NSMutableDictionary dictionary];
        [preferences addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:welcomeMessage]];
        [preferences setObject:@"What are you doing here, you peasant?!" forKey:@"Message"];
        [preferences writeToFile:welcomeMessage atomically:YES];
      }]];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController1 animated:YES completion:NULL];
  }
}
%end

static void lsNotificationCallBack() {
  [NotificationTester lockscreenNotification];
}
static void ncNotificationCallBack() {
  [NotificationTester normalNotification];
}

//Load preferences
static void loadPrefs() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefBundle];
    if(prefs) {
      customText = ( [prefs objectForKey:@"customText"] ? [prefs objectForKey:@"customText"] : customText );
      customAmount = ( [prefs objectForKey:@"customAmount"] ? [[prefs objectForKey:@"customAmount"] intValue] : customAmount );
      randomApps = ( [prefs objectForKey:@"randomApps"] ? [[prefs objectForKey:@"randomApps"] boolValue] : randomApps );
      if ([customText isEqualToString:@""]) {
        customText = @"This is a mighty fine Test Notification!";
      }
      [customText retain];
    }
    [prefs release];
}

//Initialize event listeners and load preferences.
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)lsNotificationCallBack, CFSTR("nl.d4ni.notificationtester/ls"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ncNotificationCallBack, CFSTR("nl.d4ni.notificationtester/nc"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("nl.d4ni.notificationtester/changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  loadPrefs();
}

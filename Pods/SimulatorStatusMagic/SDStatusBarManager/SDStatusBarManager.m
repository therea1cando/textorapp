
#import <UIKit/UIKit.h>
#import "SDStatusBarManager.h"
#import "SDStatusBarOverriderPre8_3.h"
#import "SDStatusBarOverriderPost8_3.h"
#import "SDStatusBarOverriderPost9_0.h"
#import "SDStatusBarOverriderPost9_3.h"
#import "SDStatusBarOverriderPost10_0.h"
#import "SDStatusBarOverriderPost10_3.h"
#import "SDStatusBarOverriderPost11_0.h"

static NSString * const SDStatusBarManagerUsingOverridesKey = @"using_overrides";
static NSString * const SDStatusBarManagerBluetoothStateKey = @"bluetooth_state";
static NSString * const SDStatusBarManagerNetworkTypeKey = @"network_type";
static NSString * const SDStatusBarManagerCarrierNameKey = @"carrier_name";
static NSString * const SDStatusBarManagerTimeStringKey = @"time_string";

@interface SDStatusBarManager ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) id <SDStatusBarOverrider> overrider;

@end

@implementation SDStatusBarManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    // Set any defaults for the status bar
    self.batteryDetailEnabled = YES;
  }
  return self;
}

- (void)enableOverrides
{
  self.usingOverrides = YES;

  self.overrider.timeString = [self localizedTimeString];
  self.overrider.carrierName = self.carrierName;
  self.overrider.bluetoothEnabled = self.bluetoothState != SDStatusBarManagerBluetoothHidden;
  self.overrider.bluetoothConnected = self.bluetoothState == SDStatusBarManagerBluetoothVisibleConnected;
  self.overrider.batteryDetailEnabled = self.batteryDetailEnabled;
  self.overrider.networkType = self.networkType;

  [self.overrider enableOverrides];
}

- (void)disableOverrides
{
  self.usingOverrides = NO;

  [self.overrider disableOverrides];
}

#pragma mark Properties
- (BOOL)usingOverrides
{
  return [self.userDefaults boolForKey:SDStatusBarManagerUsingOverridesKey];
}

- (void)setUsingOverrides:(BOOL)usingOverrides
{
  [self.userDefaults setBool:usingOverrides forKey:SDStatusBarManagerUsingOverridesKey];
}

- (void)setBluetoothState:(SDStatusBarManagerBluetoothState)bluetoothState
{
  if (self.bluetoothState == bluetoothState) return;

  [self.userDefaults setValue:@(bluetoothState) forKey:SDStatusBarManagerBluetoothStateKey];

  if (self.usingOverrides) {
    [self enableOverrides];
  }
}

- (SDStatusBarManagerBluetoothState)bluetoothState
{
  return [[self.userDefaults valueForKey:SDStatusBarManagerBluetoothStateKey] integerValue];
}

- (void)setNetworkType:(SDStatusBarManagerNetworkType)networkType
{
  if (self.networkType == networkType) return;
  
  [self.userDefaults setValue:@(networkType) forKey:SDStatusBarManagerNetworkTypeKey];
  
  if (self.usingOverrides) {
    [self enableOverrides];
  }
}

- (SDStatusBarManagerNetworkType)networkType
{
  return [[self.userDefaults valueForKey:SDStatusBarManagerNetworkTypeKey] integerValue];
}

- (void)setCarrierName:(NSString *)carrierName
{
  if ([self.carrierName isEqualToString:carrierName]) return;
  
  [self.userDefaults setObject:carrierName forKey:SDStatusBarManagerCarrierNameKey];
  
  if (self.usingOverrides) {
    [self enableOverrides];
  }
}

- (NSString *)carrierName
{
  return [self.userDefaults valueForKey:SDStatusBarManagerCarrierNameKey];
}

- (void)setTimeString:(NSString *)timeString
{
  if ([self.timeString isEqualToString:timeString]) return;
  
  [self.userDefaults setObject:timeString forKey:SDStatusBarManagerTimeStringKey];

  if (self.usingOverrides) {
    [self enableOverrides];
  }
}

- (NSString *)timeString
{
  return [self.userDefaults valueForKey:SDStatusBarManagerTimeStringKey];
}

- (NSUserDefaults *)userDefaults
{
  if (!_userDefaults) {
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.shinydevelopment.SDStatusBarManager"];
  }
  return _userDefaults;
}

+ (id<SDStatusBarOverrider>)overriderForSystemVersion:(NSString *)systemVersion
{
  id<SDStatusBarOverrider> overrider = nil;
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 11, 0, 0 }]) {
    overrider = [SDStatusBarOverriderPost11_0 new];
  } else if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 10, 3, 0 }]) {
    overrider = [SDStatusBarOverriderPost10_3 new];
  } else if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 10, 0, 0 }]) {
    overrider = [SDStatusBarOverriderPost10_0 new];
  } else if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 9, 3, 0 }]) {
    overrider = [SDStatusBarOverriderPost9_3 new];
  } else if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 9, 0, 0 }]) {
    overrider = [SDStatusBarOverriderPost9_0 new];
  } else if ([pi isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){ 8, 3, 0 }]) {
    overrider = [SDStatusBarOverriderPost8_3 new];
  } else {
    overrider = [SDStatusBarOverriderPre8_3 new];
  }
  return overrider;
}

- (id<SDStatusBarOverrider>)overrider
{
  if (!_overrider) {
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    _overrider = [SDStatusBarManager overriderForSystemVersion:systemVersion];
  }
  return _overrider;
}

#pragma mark Date helper
- (NSString *)localizedTimeString
{
  if (self.timeString.length > 0) {
    return self.timeString;
  }
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterNoStyle;
  formatter.timeStyle = NSDateFormatterShortStyle;

  NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
  components.hour = 9;
  components.minute = 41;

  return [formatter stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
}

#pragma mark Singleton instance
+ (SDStatusBarManager *)sharedInstance
{
  static dispatch_once_t predicate = 0;
  __strong static id sharedObject = nil;
  dispatch_once(&predicate, ^{ sharedObject = [[self alloc] init]; });
  return sharedObject;
}

@end

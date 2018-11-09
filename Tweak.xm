//
//  Tweak.xm
//  Hack SpringBoard to fill Appstore password automatically
//
//  Created by twotrees on 2018/11/09.
//  Copyright © 2018 twotrees. All rights reserved.
//

#import <UIKit/UIKit.h>

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

@interface _UIAlertControllerTextField : UITextField
@end

@interface _UIAlertControllerTextFieldViewController : UICollectionViewController
@property (readonly) NSArray * textFields; 
@end

@interface _SBAlertController : UIAlertController
@end

@interface SBAlertItem : NSObject
-(_SBAlertController*)alertController;
@end

@interface SBUserNotificationAlert : SBAlertItem
@end

@interface SBUserNotificationAlert()
- (void)_ttapx_autoFillPassword;
- (BOOL)_ttapx_enabled;
- (NSString*)_ttapx_password;
- (BOOL)_ttapx_autoOK;
- (void)_ttapx_triggerDefaultActionForAlert:(UIAlertController*)alert;
- (BOOL)_ttapx_showDebugMSG:(NSString*)msg;
@end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

%hook SBUserNotificationAlert

-(void)willActivate {
	%orig;

	if (![[self valueForKey:@"_alertSource"] isEqualToString:@"itunesstored"])
		return;

	if (![self _ttapx_enabled])
		return;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self _ttapx_autoFillPassword];
    });	
}

%new
- (void)_ttapx_autoFillPassword {
	UIAlertController* alert = [self valueForKey:@"alertController"];
	if (!alert)
		return;

	_UIAlertControllerTextFieldViewController* textFieldsVC = [alert valueForKey:@"_textFieldViewController"];
	if (!textFieldsVC)
		return;

	NSArray* textFields = textFieldsVC.textFields;
	if (!textFields)
		return;

	for (UITextField* text in textFields) {
		if (text.secureTextEntry) {
			NSString* password = [self _ttapx_password];
			if (password.length) {
				text.text = password;
			}
		}
	}

	if ([self _ttapx_autoOK]) {
		[self _ttapx_triggerDefaultActionForAlert:alert];
	}
}

%new
- (BOOL)_ttapx_enabled {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    BOOL enabled = [prefs[@"Enabled"] boolValue];
    return enabled;
}

%new
- (NSString*)_ttapx_password {

	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    NSString* password = prefs[@"Password"];

    return password;
}

%new
- (BOOL)_ttapx_autoOK {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    BOOL autoOK = [prefs[@"AutoOK"] boolValue];
    return autoOK;
}

%new 
- (void)_ttapx_triggerDefaultActionForAlert:(UIAlertController*)alert {
	UIAlertAction* action = alert.preferredAction;
	if (!action)
		return;

	SEL triggerSelector = NSSelectorFromString(@"_dismissAnimated:triggeringAction:triggeredByPopoverDimmingView:dismissCompletion:");
    NSMethodSignature* signature = [[alert class] instanceMethodSignatureForSelector:triggerSelector];
    if (!signature) {
        // Try pre iOS11 - OK as we're not trying to use the completion block
        triggerSelector = NSSelectorFromString(@"_dismissAnimated:triggeringAction:triggeredByPopoverDimmingView:");
        signature = [[alert class] instanceMethodSignatureForSelector:triggerSelector];
    }
    NSAssert(signature != nil, @"Couldn't find trigger method");
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:alert];
    [invocation setSelector:triggerSelector];

    BOOL boolValue = YES; // Animated & dimmingView
    [invocation setArgument:&boolValue atIndex:2];
    [invocation setArgument:&action atIndex:3];
    [invocation setArgument:&boolValue atIndex:4];
    // Not setting anything for the dismissCompletion block atIndex:5
    [invocation invoke];
}

%new
- (BOOL)_ttapx_showDebugMSG:(NSString*)msg {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"debug" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
}

%end
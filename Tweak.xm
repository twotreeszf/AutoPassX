//
//  Tweak.xm
//  Hack SpringBoard to fill Appstore password automatically
//
//  Created by twotrees on 2018/11/09.
//  Copyright © 2018 twotrees. All rights reserved.
//

#import <UIKit/UIKit.h>

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

void _ttapxDebugMsg(NSString* msg) {
	NSLog(@"AutoPassX: %@", msg);
}

BOOL _ttapxEnabled() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    BOOL enabled = [prefs[@"Enabled"] boolValue];
    return enabled;
}

NSString* _ttapxPassword() {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    NSString* password = prefs[@"Password"];

    return password;
}

BOOL _ttapxAutoOK() {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.autopassxprefer.plist"];
    BOOL autoOK = [prefs[@"AutoOK"] boolValue];
    return autoOK;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

typedef void (^ViewFilterBlock)(UIView* view);
@interface UIView(viewRecursion)
- (void)aptxFindRecursive:(ViewFilterBlock)block;
@end

@implementation UIView (viewRecursion)
- (void)aptxFindRecursive:(ViewFilterBlock)block {
	block(self);

	for (UIView *subview in self.subviews) {
		[subview aptxFindRecursive:block];
	}
}
@end

%ctor {
	_ttapxDebugMsg([NSString stringWithFormat:@"booted pid: %d", [NSProcessInfo processInfo].processIdentifier]);
}


@interface PKPaymentAuthorizationServiceViewController : UIViewController
@end

@interface PKPaymentAuthorizationServiceViewController()
- (void)_ttapxAutoFill;
- (BOOL)_ttapxEnabled;
- (BOOL)_ttapxAutoOK;
- (NSString*)_ttapxPassword;
- (BOOL)_ttapxDebugMsg:(NSString*)msg;
@end

// iOS 11+
%hook PKPaymentAuthorizationServiceViewController

- (void)viewDidAppear:(BOOL)animated {
	%orig;

	_ttapxDebugMsg(@"hooked PKPaymentAuthorizationServiceViewController");
	if (_ttapxEnabled()) {
		_ttapxDebugMsg(@"begin auto fill");
		[self _ttapxAutoFill];
	}
}

%new
- (void)_ttapxAutoFill {
	[self.view aptxFindRecursive:^(UIView* view) {
		if ([view isKindOfClass:NSClassFromString(@"PKContinuousButton")]) {
			UIButton* btn = (UIButton*)view;
			if ([btn.currentTitle isEqualToString:@"消费"] || [btn.currentTitle isEqualToString:@"购买"]) {							
				_ttapxDebugMsg(@"finded purchas button");
				if (_ttapxAutoOK()) {
					_ttapxDebugMsg(@"click purchas button");
					[btn sendActionsForControlEvents:UIControlEventTouchUpInside];
				}

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[self.view aptxFindRecursive:^(UIView* view) {
						if ([view isKindOfClass:NSClassFromString(@"_AKInsetTextField")]) {
							_ttapxDebugMsg(@"finded password field");							
							UITextField* edit = (UITextField*)view;
							NSString* password = _ttapxPassword();							
							if (password.length) {
								_ttapxDebugMsg(@"fill password field");							
								edit.text = password;
							}						
						}						

						if ([view isKindOfClass:NSClassFromString(@"AKRoundedButton")]) {
							UIButton* btn = (UIButton*)view;
							if ([btn.currentTitle isEqualToString:@"登录"]) {
								_ttapxDebugMsg(@"finded login button");							
								NSString* password = _ttapxPassword();							
								if (password.length) {
									if (_ttapxAutoOK()) {
										_ttapxDebugMsg(@"click login button");							
										[btn sendActionsForControlEvents:UIControlEventTouchUpInside];
									}
								}
							}
						}
					}];
    			});
			}
		}
	}];
}

%end

// iOS 10
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
- (void)_ttapxAutoFillPassword;
- (void)_ttapxDismissAlert:(UIAlertController*)alert;
@end

%hook SBUserNotificationAlert

-(void)willActivate {
	%orig;

	NSString* source = [self valueForKey:@"_alertSource"];
	_ttapxDebugMsg([NSString stringWithFormat:@"alert source: %@", source]);

	if (![source isEqualToString:@"itunesstored"])
		return;

	if (!_ttapxEnabled())
		return;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self _ttapxAutoFillPassword];
    });	
}

%new
- (void)_ttapxAutoFillPassword {
	UIAlertController* alert = [self valueForKey:@"alertController"];
	if (!alert)
		return;

	_UIAlertControllerTextFieldViewController* textFieldsVC = [alert valueForKey:@"_textFieldViewController"];
	if (textFieldsVC) {
		NSArray* textFields = textFieldsVC.textFields;
		if (textFields) {
			for (UITextField* text in textFields) {
				if (text.secureTextEntry) {
					NSString* password = _ttapxPassword();
					if (password.length) {
						_ttapxDebugMsg(@"fill password");
						text.text = password;
					}
				}
			}
		}
	}

	if (_ttapxAutoOK())
		[self _ttapxDismissAlert:alert];
}

%new
- (void)_ttapxDismissAlert:(UIAlertController*) alert {
	_ttapxDebugMsg(@"dismiss alert");
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
%end
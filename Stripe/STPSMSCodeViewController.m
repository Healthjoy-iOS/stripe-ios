//
//  STPSMSCodeViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 5/10/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSMSCodeViewController.h"
#import "STPSMSCodeTextField.h"
#import "STPCheckoutAPIClient.h"
#import "STPCheckoutAPIVerification.h"
#import "STPPromise.h"
#import "STPTheme.h"
#import "STPPaymentActivityIndicatorView.h"
#import "StripeError.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIBarButtonItem+Stripe.h"

@interface STPSMSCodeViewController()<STPSMSCodeTextFieldDelegate>

@property(nonatomic)STPCheckoutAPIClient *checkoutAPIClient;
@property(nonatomic)STPCheckoutAPIVerification *verification;

@property(nonatomic, weak)UIScrollView *scrollView;
@property(nonatomic, weak)UILabel *topLabel;
@property(nonatomic, weak)STPSMSCodeTextField *codeField;
@property(nonatomic, weak)UILabel *bottomLabel;
@property(nonatomic, weak)UIButton *cancelButton;
@property(nonatomic, weak)UILabel *errorLabel;
@property(nonatomic, weak)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic)BOOL loading;

@end

@implementation STPSMSCodeViewController

- (instancetype)initWithCheckoutAPIClient:(STPCheckoutAPIClient *)checkoutAPIClient
                             verification:(STPCheckoutAPIVerification *)verification {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _checkoutAPIClient = checkoutAPIClient;
        _verification = verification;
        _theme = [STPTheme new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.scrollEnabled = NO;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    UILabel *topLabel = [UILabel new];
    topLabel.text = NSLocalizedString(@"Enter the verification code to use the payment info you stored with Stripe.", nil);
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.numberOfLines = 0;
    [self.scrollView addSubview:topLabel];
    self.topLabel = topLabel;
    
    STPSMSCodeTextField *codeField = [STPSMSCodeTextField new];
    [self.scrollView addSubview:codeField];
    codeField.delegate = self;
    self.codeField = codeField;
    
    UILabel *bottomLabel = [UILabel new];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = NSLocalizedString(@"Didn't receive the code?", nil);
    [self.scrollView addSubview:bottomLabel];
    self.bottomLabel = bottomLabel;
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [cancelButton setTitle:NSLocalizedString(@"Fill in your card details manually", nil) forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:cancelButton];
    self.cancelButton = cancelButton;
    
    UILabel *errorLabel = [UILabel new];
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.alpha = 0;
    errorLabel.text = NSLocalizedString(@"Invalid Code", nil);
    [self.scrollView addSubview:errorLabel];
    self.errorLabel = errorLabel;
    
    STPPaymentActivityIndicatorView *activityIndicator = [STPPaymentActivityIndicatorView new];
    [self.view addSubview:activityIndicator];
    _activityIndicator = activityIndicator;
    
    [self updateAppearance];
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    [self.navigationItem.leftBarButtonItem stp_setTheme:self.theme];
    [self.navigationItem.rightBarButtonItem stp_setTheme:self.theme];
    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    self.topLabel.font = self.theme.smallFont;
    self.topLabel.textColor = self.theme.secondaryForegroundColor;
    self.codeField.theme = self.theme;
    self.bottomLabel.font = self.theme.smallFont;
    self.bottomLabel.textColor = self.theme.secondaryForegroundColor;
    self.cancelButton.titleLabel.font = self.theme.smallFont;
    self.cancelButton.titleLabel.textColor = self.theme.accentColor;
    self.errorLabel.font = self.theme.smallFont;
    self.errorLabel.textColor = self.theme.errorColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = self.view.bounds.size;
    
    CGFloat padding = 20.0f;
    CGFloat contentWidth = self.view.bounds.size.width - (padding * 2);
    
    CGSize topLabelSize = [self.topLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.topLabel.frame = CGRectMake(padding, 40, contentWidth, topLabelSize.height);
    
    self.codeField.frame = CGRectMake(padding, CGRectGetMaxY(self.topLabel.frame) + 20, contentWidth, 76);
    
    CGSize bottomLabelSize = [self.bottomLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.bottomLabel.frame = CGRectMake(padding, CGRectGetMaxY(self.codeField.frame) + 20, contentWidth, bottomLabelSize.height);
    self.errorLabel.frame = self.bottomLabel.frame;
    
    self.cancelButton.frame = CGRectOffset(self.errorLabel.frame, 0, self.errorLabel.frame.size.height + 2);
    
    CGFloat activityIndicatorWidth = 30.0f;
    self.activityIndicator.frame = CGRectMake((self.view.bounds.size.width - activityIndicatorWidth) / 2, CGRectGetMaxY(self.cancelButton.frame) + 20, activityIndicatorWidth, activityIndicatorWidth);
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.codeField becomeFirstResponder];
}

- (void)codeTextField:(STPSMSCodeTextField *)codeField
         didEnterCode:(NSString *)code {
    __weak typeof(self) weakself = self;
    STPCheckoutAPIClient *client = self.checkoutAPIClient;
    [[[client submitSMSCode:code forVerification:self.verification] onSuccess:^(STPCheckoutAccount *account) {
        [weakself.delegate smsCodeViewController:self didAuthenticateAccount:account];
    }] onFailure:^(NSError *error) {
        BOOL tooManyTries = error.code == STPCheckoutTooManyAttemptsError;
        if (tooManyTries) {
            self.errorLabel.text = NSLocalizedString(@"Too many incorrect attempts", nil);
        }
        [codeField shakeAndClear];
        [UIView animateWithDuration:0.2f animations:^{
            self.bottomLabel.alpha = 0;
            self.cancelButton.alpha = 0;
            self.errorLabel.alpha = 1.0f;
        }];
        [UIView animateWithDuration:0.2f delay:0.3f options:0 animations:^{
            self.bottomLabel.alpha = 1.0f;
            self.cancelButton.alpha = 1.0f;
            self.errorLabel.alpha = 0;
        } completion:^(__unused BOOL finished) {
            [self.delegate smsCodeViewControllerDidCancel:self];
        }];
    }];
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.activityIndicator setAnimating:loading animated:YES];
    self.navigationItem.leftBarButtonItem.enabled = !loading;
    self.cancelButton.enabled = !loading;
}

- (void)cancel {
    [self.delegate smsCodeViewControllerDidCancel:self];
}

@end
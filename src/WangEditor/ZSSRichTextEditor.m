//
//  ZSSRichTextEditorViewController.m
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ZSSRichTextEditor.h"
#import "ZSSBarButtonItem.h"
#import "HRColorUtil.h"
#import "ZSSWeakProxy.h"

@import JavaScriptCore;


@interface ZSSRichTextEditor ()

/*
 *  Scroll view containing the toolbar
 */
@property (nonatomic, strong) UIScrollView *toolBarScroll;

/*
 *  Toolbar containing ZSSBarButtonItems
 */
@property (nonatomic, strong) UIToolbar *toolbar;

/*
 *  Holder for all of the toolbar components
 */
@property (nonatomic, strong) UIView *toolbarHolder;

/*
 *  String for the HTML
 */
@property (nonatomic, strong) NSString *htmlString;

/*
 *  CGRect for holding the frame for the editor view
 */
@property (nonatomic) CGRect editorViewFrame;

/*
 *  Last Editor Height, update when caret position update if height grow or less 10pt
 */
@property (nonatomic) CGFloat lastCaretLocEditorH;

/*
 *  BOOL for holding if the resources are loaded or not
 */
@property (nonatomic) BOOL resourcesLoaded;

/*
 *  Array holding the enabled editor items
 */
@property (nonatomic, strong) NSArray *editorItemsEnabled;

/*
 *  Alert View used when inserting links/images
 */
@property (nonatomic, strong) UIAlertView *alertView;

/*
 *  NSString holding the selected links URL value
 */
@property (nonatomic, strong) NSString *selectedLinkURL;

/*
 *  NSString holding the selected links title value
 */
@property (nonatomic, strong) NSString *selectedLinkTitle;

/*
 *  NSString holding the selected image URL value
 */
@property (nonatomic, strong) NSString *selectedImageURL;

/*
 *  NSString holding the selected image Alt value
 */
@property (nonatomic, strong) NSString *selectedImageAlt;

/*
 *  CGFloat holdign the selected image scale value
 */
@property (nonatomic, assign) CGFloat selectedImageScale;

/*
 *  NSString holding the base64 value of the current image
 */
@property (nonatomic, strong) NSString *imageBase64String;

/*
 *  Bar button item for the keyboard dismiss button in the toolbar
 */
@property (nonatomic, strong) UIBarButtonItem *keyboardItem;

/*
 *  Array for custom bar button items
 */
@property (nonatomic, strong) NSMutableArray *customBarButtonItems;

/*
 *  Array for custom ZSSBarButtonItems
 */
@property (nonatomic, strong) NSMutableArray *customZSSBarButtonItems;

/*
 *  NSString holding the html
 */
@property (nonatomic, strong) NSString *internalHTML;

/*
 *  NSString holding the css
 */
@property (nonatomic, strong) NSString *customCSS;

/*
 *  BOOL for if the editor is loaded or not
 */
@property (nonatomic) BOOL editorLoaded;

/*
 *  BOOL for if the editor is paste or not
 */
@property (nonatomic) BOOL editorPaste;
/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIImagePickerController *imagePicker;

// local var to hold first responder state after callback
@property (nonatomic) BOOL isFirstResponderUpdated;

// origin title view height
@property (nonatomic) CGFloat titleTVH;

// Keyboard Height
@property (nonatomic) CGFloat editorVisibleH;

/*
 *  Method for getting a version of the html without quotes
 */
- (NSString *)removeQuotesFromHTML:(NSString *)html;

/*
 *  Method for getting a tidied version of the html
 */
- (void)tidyHTML:(NSString *)html completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

/*
 * Method for enablign toolbar items
 */
- (void)enableToolbarItems:(BOOL)enable;

/*
 *  Setter for isIpad BOOL
 */
- (BOOL)isIpad;

@end

/*
 
 ZSSRichTextEditor
 
 */
@implementation ZSSRichTextEditor

//Scale image from device
static CGFloat kJPEGCompression = 0.8;
static CGFloat kDefaultScale = 1;
static CGFloat kTitleTVH = 45;
#pragma mark - View Did Load Section
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //Initialise variables
    self.editorLoaded = NO;
    self.receiveEditorDidChangeEvents = YES;
    self.alwaysShowToolbar = NO;
    self.shouldShowKeyboard = YES;
    self.formatHTML = NO;
    self.editorVisibleH = 0;
    
    //Initalise enabled toolbar items array
    self.enabledToolbarItems = [[NSArray alloc] init];
    
    //Frame for the source view and editor view
    self.titleTVH = 11 + kTitleTVH + 11;
    
    //Main Container
    [self createContainerView];

    //Title TextView
    [self createTitleTextView];

    //Source View
    [self createSourceView];

    //Editor View
    [self createEditorView];

    //Image Picker used to allow the user insert images from the device (base64 encoded)
    [self setUpImagePicker];

    //Scrolling View
    [self createToolBarScroll];

    //Toolbar with icons
    [self createToolbar];

    //Parent holding view
    [self createParentHoldingView];
    
    //Hide Keyboard
    if (![self isIpad]) {
        NSBundle *bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];
        
        // Toolbar holder used to crop and position toolbar
        UIView *toolbarCropper = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-44, 0, 44, 44)];
        toolbarCropper.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        toolbarCropper.clipsToBounds = YES;
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [btn addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [[UIImage imageNamed:@"SFkeyboard.png" inBundle:bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [btn setImage:image forState:UIControlStateNormal];
        btn.tintColor = [UIColor colorWithRed:43 / 255.0f green:43 / 255.0f blue:58 / 255.0f alpha:1];
        [toolbarCropper addSubview:btn];
        [self.toolbarHolder addSubview:toolbarCropper];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.6f, 44)];
        line.backgroundColor = [UIColor lightGrayColor];
        line.alpha = 0.7f;
        [toolbarCropper addSubview:line];
    }
    
    [self.view addSubview:self.toolbarHolder];
    
    //Build the toolbar
    [self buildToolbar];
    
    //Load Resources
    if (!self.resourcesLoaded) {
        [self loadResources];
    }
}

#pragma mark - View Will Appear Section
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Add observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.titleTV addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - View Will Disappear Section
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Remove observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.titleTV removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark - Set Up View Section

- (void)createContainerView {
    self.containerScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.containerScrollView];
}

- (void)createTitleTextView {
    self.titleTV = [[UITextView alloc] initWithFrame:CGRectMake(22, 11, self.view.bounds.size.width - 44, kTitleTVH)];
    self.titleTV.delegate = self;
    self.titleTV.text = ZSSEditorTitlePlaceHolder;
    self.titleTV.textColor = [[UIColor alloc] initWithRed:154 / 255.0 green:156 / 255.0 blue:178 / 255.0 alpha:1];
    self.titleTV.font = [UIFont systemFontOfSize:24 weight:UIFontWeightMedium];
    self.titleTV.alwaysBounceVertical = NO;
    [self.containerScrollView addSubview:self.titleTV];
}

- (void)createSourceView {
    CGFloat height = self.containerScrollView.frame.size.height - self.titleTVH;
    self.sourceView = [[ZSSTextView alloc] initWithFrame:CGRectMake(15, self.titleTVH, self.view.bounds.size.width - 30, height)];
    self.sourceView.hidden = YES;
    self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceView.font = [UIFont fontWithName:@"Courier" size:13.0];
    self.sourceView.autoresizesSubviews = YES;
    self.sourceView.delegate = self;
    [self.containerScrollView addSubview:self.sourceView];
}

- (void)createEditorView {
    //allocate config and contentController and add scriptMessageHandler
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences.javaScriptEnabled = YES;
    config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    config.suppressesIncrementalRendering = YES; // 是否支持记忆读取
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    if (@available(iOS 10.0, *)) {
         [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    }
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:[ZSSWeakProxy weakProxy:self] name:@"jsm"];
    config.userContentController = contentController;

    //set data detection to none so it doesnt conflict
    config.dataDetectorTypes = WKDataDetectorTypeNone;
    
    CGFloat height = self.containerScrollView.frame.size.height - self.titleTVH;
    CGRect frame = CGRectMake(15, self.titleTVH, self.view.bounds.size.width - 30, height);
    self.editorView = [[ZSSWebView alloc] initWithFrame:frame configuration: config];
    self.editorView.scrollView.contentInset = UIEdgeInsetsZero;
    self.editorView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.editorView.scrollView.scrollEnabled = NO;
    self.editorView.scrollView.showsHorizontalScrollIndicator = NO;
    self.editorView.scrollView.bounces = NO;
    self.editorView.scrollView.alwaysBounceVertical = NO;
    self.editorView.scrollView.alwaysBounceHorizontal = NO;
    self.editorView.scrollView.delegate = self;
    self.editorView.navigationDelegate = self;
    /*
    self.editorView.UIDelegate = self;
    self.editorView.allowsBackForwardNavigationGestures = YES;
    self.editorView.allowsLinkPreview = YES;
    */
    
    // 通过如下方法设置 键盘弹出的时候，不要有inset，contentInsetAdjustmentBehavior不管用
    [NSNotificationCenter.defaultCenter removeObserver:self.editorView name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self.editorView name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self.editorView name:UIKeyboardWillHideNotification object:nil];
    
    //TODO: Is this behavior correct? Is it the right replacement?
    //self.editorView.keyboardDisplayRequiresUserAction = NO;
    //[ZSSRichTextEditor allowDisplayingKeyboardWithoutUserAction];

    self.editorView.backgroundColor = [UIColor whiteColor];
    [self.containerScrollView addSubview:self.editorView];
}

- (void)setUpImagePicker {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.allowsEditing = YES;
    self.selectedImageScale = kDefaultScale; //by default scale to half the size
}

- (void)createToolBarScroll {
    self.toolBarScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [self isIpad] ? self.view.frame.size.width : self.view.frame.size.width - 44, 44)];
    self.toolBarScroll.backgroundColor = [UIColor clearColor];
    self.toolBarScroll.showsHorizontalScrollIndicator = NO;
}

- (void)createToolbar {
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.toolbar.backgroundColor = [UIColor clearColor];
    [self.toolBarScroll addSubview:self.toolbar];
    self.toolBarScroll.autoresizingMask = self.toolbar.autoresizingMask;
}

- (void)createParentHoldingView {
    //Background Toolbar
    UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //Parent holding view
    self.toolbarHolder = [[UIView alloc] init];
    
    if (_alwaysShowToolbar) {
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    } else {
        self.toolbarHolder.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44);
    }
    
    self.toolbarHolder.autoresizingMask = self.toolbar.autoresizingMask;
    [self.toolbarHolder addSubview:self.toolBarScroll];
    [self.toolbarHolder insertSubview:backgroundToolbar atIndex:0];
}

#pragma mark - Layout

- (void)updateEditorHeight:(BOOL)isLocationCaret {
    NSString *heightListener = @"document.getElementById('editor-text-area').clientHeight";
    __weak typeof(self) weakSelf = self;
    // evaluateJavaScript 实际上不会造成内存泄漏，先就这么写吧
    [self.editorView evaluateJavaScript:heightListener completionHandler:^(NSNumber *result, NSError *error) {
        if (error != NULL) {
            NSLog(@"%@", error);
        } else {
            CGFloat editorH = [result floatValue];
            NSLog(@"editorH = %@", @(editorH));
            if (editorH < weakSelf.editorVisibleH) {
                editorH = weakSelf.editorVisibleH;
            }
            // 如果变化小于10就不需要更新了
            if (abs(weakSelf.lastCaretLocEditorH - editorH) < 10) {
                return;
            }
            CGRect rect = weakSelf.editorView.frame;
            rect.size.height = editorH;
            
            weakSelf.editorView.frame = rect;
            weakSelf.sourceView.frame = rect;
            CGFloat scrollSizeH = weakSelf.editorView.frame.size.height + weakSelf.editorView.frame.origin.y;
            weakSelf.containerScrollView.contentSize = CGSizeMake(weakSelf.containerScrollView.bounds.size.width, scrollSizeH);
            
            if (isLocationCaret && weakSelf.editorVisibleH > 0) {
                // editorVisibleH > 0表示键盘弹出来过，不是第一次加载内容
                // 高度变化证明内容有更新，自定定位光标位置
                // 如果高度没有变化就不需要自动定位光标位置了
                weakSelf.lastCaretLocEditorH = editorH;
                [weakSelf scrollCaretToVisible];
            }
        }
    }];
}

/// Scrolls the editor to a position where the caret is visible.
/// Called repeatedly to make sure the caret is always visible when inputting text.
- (void)scrollCaretToVisible {
    if (self.editorView.frame.size.height <= self.editorVisibleH) {
        return;
    }
    UIScrollView *scrollView = self.containerScrollView;
    NSString *trigger = @"RE.getCaretYPosition();";
    __weak typeof(self) weakSelf = self;
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSNumber *result, NSError *error) {
        if (error != NULL) {
            NSLog(@"%@", error);
        } else {
            CGFloat curY = [result floatValue];
            NSLog(@"result == %@", @(curY));
            CGPoint offset = CGPointZero;
            offset.y = curY - 100;
            if (offset.y > scrollView.contentSize.height - scrollView.bounds.size.height) {
                offset.y = scrollView.contentSize.height - scrollView.bounds.size.height;
            }
            if (offset.y > 0) {
                [weakSelf.containerScrollView setContentOffset:offset animated:true];
            }
        }
    }];
}

#pragma mark - Keyboard status

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.titleTV && [keyPath isEqualToString:@"contentSize"]) {
        CGRect tvFrame = self.titleTV.frame;
        if (self.titleTV.contentSize.height < kTitleTVH) {
            tvFrame.size.height = kTitleTVH;
        } else {
            tvFrame.size.height = self.titleTV.contentSize.height;
        }
        self.titleTV.frame = tvFrame;
        self.titleTVH = 11 + tvFrame.size.height + 11;
        
        CGRect editorRect = self.editorView.frame;
        editorRect.origin.y = self.titleTVH;
        self.sourceView.frame = editorRect;
        self.editorView.frame = editorRect;
        
        CGFloat scrollSizeH = self.editorView.frame.size.height + self.editorView.frame.origin.y;
        self.containerScrollView.contentSize = CGSizeMake(self.containerScrollView.bounds.size.width, scrollSizeH);
    }
}

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Toolbar Sizes
    CGFloat sizeOfToolbar = self.toolbarHolder.frame.size.height;
    
    // Keyboard Size
    CGFloat keyboardHeight = keyboardEnd.size.height;
    
    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
    self.editorVisibleH = self.view.frame.size.height - keyboardEnd.size.height - 90 - 124; // 90 editor OriginY
    
    const int extraHeight = 10;
    
    if (keyboardEnd.origin.y < [[UIScreen mainScreen] bounds].size.height) {
        // 键盘弹出
        if (self.titleTV.isFirstResponder) {
            [self.containerScrollView setContentOffset:CGPointZero animated:YES];
            self.toolBarScroll.hidden = YES;
        } else {
            [self scrollCaretToVisible];
            self.toolBarScroll.hidden = NO;
        }
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            // Toolbar
            CGRect toolbarFrame = self.toolbarHolder.frame;
            CGRect kbRect = [self.toolbarHolder.superview convertRect:keyboardEnd fromView:nil];
            toolbarFrame.origin.y = kbRect.origin.y - sizeOfToolbar;
            self.toolbarHolder.frame = toolbarFrame;

            CGRect containerFrame = self.containerScrollView.frame;
            CGFloat containerH = toolbarFrame.origin.y - extraHeight - containerFrame.origin.y;
            containerFrame.size.height = containerH;
            self.containerScrollView.frame = containerFrame;
        } completion:nil];
    } else {
        // 键盘收起
        [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
            CGRect frame = self.toolbarHolder.frame;
            if (self->_alwaysShowToolbar) {
                CGFloat bottomSafeAreaInset = 0.0;
                if (@available(iOS 11.0, *)) {
                    bottomSafeAreaInset = self.view.safeAreaInsets.bottom;
                }
                frame.origin.y = self.view.frame.size.height - sizeOfToolbar - bottomSafeAreaInset;
            } else {
                frame.origin.y = self.view.frame.size.height + keyboardHeight;
            }
            self.toolbarHolder.frame = frame;
            CGRect containerFrame = self.containerScrollView.frame;
            CGFloat containerH = self.view.bounds.size.height - containerFrame.origin.y;
            containerFrame.size.height = containerH;
            self.containerScrollView.frame = containerFrame;
        } completion:nil];
        
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.titleTV) {
        // 设置大小
        CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
        CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
        if ( overflow > 0 ) {
            // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
            // Scroll caret to visible area
            CGPoint offset = textView.contentOffset;
            offset.y += overflow + 7; // leave 7 pixels margin
            // Cannot animate with setContentOffset:animated: or caret will not appear
            [UIView animateWithDuration:.2 animations:^{
                [textView setContentOffset:offset];
            }];
        }
        // 文字限制
        if (textView.text.length > ZSSEditorMaxTitleLength) {
            textView.text = [textView.text substringToIndex:ZSSEditorMaxTitleLength];
            [self toast:@"标题不能超过30个字"];
        }
        
        if (textView.text.length == 0) {
            self.titleTV.tag = 0;
        } else {
            self.titleTV.tag = 1;
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView == self.titleTV, textView.tag == 0) {
        self.titleTV.text = nil;
        self.titleTV.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.titleTV) {
        if (textView.text.length == 0) {
            textView.tag = 0;
            self.titleTV.text = ZSSEditorTitlePlaceHolder;
            self.titleTV.textColor = [[UIColor alloc] initWithRed:154 / 255.0 green:156 / 255.0 blue:178 / 255.0 alpha:1];
        } else {
            textView.tag = 1;
        }
    }
}

#pragma mark - Convenience replacement for keyboardDisplayRequiresUserAction in WKWebview
/// UIWebView：keyboardDisplayRequiresUserAction属性用户交互才可以呼出键盘，如果设置成NO，可以通过js的input.focus呼出
/// WKWebView：没有此种类方法通过以下方法hook实现
//+ (void)allowDisplayingKeyboardWithoutUserAction {
//    Class class = NSClassFromString(@"WKContentView");
//    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};
//    NSOperatingSystemVersion iOS_12_2_0 = (NSOperatingSystemVersion){12, 2, 0};
//    NSOperatingSystemVersion iOS_13_0_0 = (NSOperatingSystemVersion){13, 0, 0};
//    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_13_0_0]) {
//        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:");
//        Method method = class_getInstanceMethod(class, selector);
//        IMP original = method_getImplementation(method);
//        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
//        ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
//        });
//        method_setImplementation(method, override);
//    }
//   else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_12_2_0]) {
//        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
//        Method method = class_getInstanceMethod(class, selector);
//        IMP original = method_getImplementation(method);
//        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
//        ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
//        });
//        method_setImplementation(method, override);
//    }
//    else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_11_3_0]) {
//        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
//        Method method = class_getInstanceMethod(class, selector);
//        IMP original = method_getImplementation(method);
//        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
//            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
//        });
//        method_setImplementation(method, override);
//    } else {
//        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
//        Method method = class_getInstanceMethod(class, selector);
//        IMP original = method_getImplementation(method);
//        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
//            ((void (*)(id, SEL, void*, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3);
//        });
//        method_setImplementation(method, override);
//    }
//}

#pragma mark - Resources Section

- (void)loadResources {
    //Define correct bundle for loading resources
    NSBundle* bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];
    NSString *filePath = [bundle pathForResource:@"wang_editor" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [self.editorView loadFileURL:url allowingReadAccessToURL:url.URLByDeletingLastPathComponent];
    self.resourcesLoaded = YES;
}

#pragma mark - Toolbar Section

- (void)setEnabledToolbarItems:(NSArray *)enabledToolbarItems {
    _enabledToolbarItems = enabledToolbarItems;
    [self buildToolbar];
}

- (void)setToolbarItemTintColor:(UIColor *)toolbarItemTintColor {
    _toolbarItemTintColor = toolbarItemTintColor;
    
    // Update the color
    for (ZSSBarButtonItem *item in self.toolbar.items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    self.keyboardItem.tintColor = toolbarItemTintColor;
}

- (void)setToolbarItemSelectedTintColor:(UIColor *)toolbarItemSelectedTintColor {
    _toolbarItemSelectedTintColor = toolbarItemSelectedTintColor;
    _editorView.tintColor = toolbarItemSelectedTintColor;
    _titleTV.tintColor = toolbarItemSelectedTintColor;
}

- (NSArray *)itemsForToolbar {
    //Define correct bundle for loading resources
    NSBundle* bundle = [NSBundle bundleForClass:[ZSSRichTextEditor class]];
    NSMutableArray *items = [[NSMutableArray alloc] init];

    // None
    if (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarNone]) {
        return items;
    }

    BOOL customOrder = NO;
    if (_enabledToolbarItems && ![_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll]){
        customOrder = YES;
        for(int i=0; i < _enabledToolbarItems.count;i++){
            [items addObject:@""];
        }
    }
    
    // Bold
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarBold]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *bold = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFbold.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setBold)];
        bold.label = @"bold";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarBold] withObject:bold];
        } else {
            [items addObject:bold];
        }
    }

    // Italic
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarItalic]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *italic = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFitalic.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setItalic)];
        italic.label = @"italic";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarItalic] withObject:italic];
        } else {
            [items addObject:italic];
        }
    }

    // Subscript
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarSubscript]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *subscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsubscript.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setSubscript)];
        subscript.label = @"subscript";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarSubscript] withObject:subscript];
        } else {
            [items addObject:subscript];
        }
    }

    // Superscript
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarSuperscript]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *superscript = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSsuperscript.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setSuperscript)];
        superscript.label = @"superscript";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarSuperscript] withObject:superscript];
        } else {
            [items addObject:superscript];
        }
    }

    // Strike Through
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarStrikeThrough]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *strikeThrough = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSstrikethrough.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setStrikethrough)];
        strikeThrough.label = @"strikeThrough";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarStrikeThrough] withObject:strikeThrough];
        } else {
            [items addObject:strikeThrough];
        }
    }

    // Underline
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUnderline]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *underline = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFunderline.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setUnderline)];
        underline.label = @"underline";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarUnderline] withObject:underline];
        } else {
            [items addObject:underline];
        }
    }
    
    // Remove Format
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRemoveFormat]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *removeFormat = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSclearstyle.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(removeFormat)];
        removeFormat.label = @"removeFormat";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarRemoveFormat] withObject:removeFormat];
        } else {
            [items addObject:removeFormat];
        }
    }

    //  Fonts
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarFonts]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *fonts = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSfonts.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(showFontsPicker)];
        fonts.label = @"fonts";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarFonts] withObject:fonts];
        } else {
            [items addObject:fonts];
        }
    }

    // Undo
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUndo]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *undoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSundo.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(undo:)];
        undoButton.label = @"undo";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarUndo] withObject:undoButton];
        } else {
            [items addObject:undoButton];
        }
    }

    // Redo
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRedo]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *redoButton = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSredo.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(redo:)];
        redoButton.label = @"redo";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarRedo] withObject:redoButton];
        } else {
            [items addObject:redoButton];
        }
    }

    // Align Left
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyLeft]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignLeft = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFleftjustify.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignLeft)];
        alignLeft.label = @"justifyLeft";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarJustifyLeft] withObject:alignLeft];
        } else {
            [items addObject:alignLeft];
        }
    }

    // Align Center
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyCenter]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignCenter = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFcenterjustify.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignCenter)];
        alignCenter.label = @"justifyCenter";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarJustifyCenter] withObject:alignCenter];
        } else {
            [items addObject:alignCenter];
        }
    }

    // Align Right
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyRight]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignRight = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFrightjustify.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignRight)];
        alignRight.label = @"justifyRight";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarJustifyRight] withObject:alignRight];
        } else {
            [items addObject:alignRight];
        }
    }

    // Align Justify
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarJustifyFull]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *alignFull = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSforcejustify.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(alignFull)];
        alignFull.label = @"justifyFull";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarJustifyFull] withObject:alignFull];
        } else {
            [items addObject:alignFull];
        }
    }

    // Paragraph
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarParagraph]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *paragraph = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSparagraph.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(paragraph)];
        paragraph.label = @"p";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarParagraph] withObject:paragraph];
        } else {
            [items addObject:paragraph];
        }
    }

    // Header 1 梨花写作改成了H2
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH1]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h1 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFh1.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading1:)];
        h1.label = @"H2";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH1] withObject:h1];
        } else {
            [items addObject:h1];
        }
    }

    // Header 2
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH2]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h2 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFh2.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading2:)];
        h2.label = @"H3";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH2] withObject:h2];
        } else {
            [items addObject:h2];
        }
    }

    // Header 3
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH3]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h3 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFh3.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading3:)];
        h3.label = @"H4";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH3] withObject:h3];
        } else {
            [items addObject:h3];
        }
    }

    // Heading 4
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH4]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h4 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh4.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading4:)];
        h4.label = @"H4";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH4] withObject:h4];
        } else {
            [items addObject:h4];
        }
    }

    // Header 5
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH5]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h5 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh5.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading5:)];
        h5.label = @"H5";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH5] withObject:h5];
        } else {
            [items addObject:h5];
        }
    }

    // Heading 6
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarH6]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *h6 = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSh6.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(heading6:)];
        h6.label = @"H6";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarH6] withObject:h6];
        } else {
            [items addObject:h6];
        }
    }

    // Text Color
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarTextColor]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *textColor = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSStextcolor.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(textColor)];
        textColor.label = @"textColor";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarTextColor] withObject:textColor];
        } else {
            [items addObject:textColor];
        }
    }

    // Background Color
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarBackgroundColor]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *bgColor = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSbgcolor.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(bgColor)];
        bgColor.label = @"backgroundColor";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarBackgroundColor] withObject:bgColor];
        } else {
            [items addObject:bgColor];
        }
    }

    // Unordered List
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarUnorderedList]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *ul = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFunorderedlist.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setUnorderedList)];
        ul.label = @"unorderedList";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarUnorderedList] withObject:ul];
        } else {
            [items addObject:ul];
        }
    }

    // Ordered List
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarOrderedList]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *ol = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SForderedlist.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setOrderedList)];
        ol.label = @"orderedList";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarOrderedList] withObject:ol];
        } else {
            [items addObject:ol];
        }
    }

    // Horizontal Rule
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarHorizontalRule]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *hr = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSShorizontalrule.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setHR)];
        hr.label = @"horizontalRule";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarHorizontalRule] withObject:hr];
        } else {
            [items addObject:hr];
        }
    }

    // Indent
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarIndent]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *indent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFindent.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setIndent)];
        indent.label = @"indent";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarIndent] withObject:indent];
        } else {
            [items addObject:indent];
        }
    }

    // Outdent
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarOutdent]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *outdent = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFoutdent.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(setOutdent)];
        outdent.label = @"outdent";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarOutdent] withObject:outdent];
        } else {
            [items addObject:outdent];
        }
    }

    // Image
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarInsertImage]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *insertImage = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSimage.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(insertImage)];
        insertImage.label = @"image";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarInsertImage] withObject:insertImage];
        } else {
            [items addObject:insertImage];
        }
    }

    // Image From Device
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarInsertImageFromDevice]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *insertImageFromDevice = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFimageDevice.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(insertImageFromDevice)];
        insertImageFromDevice.label = @"imageFromDevice";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarInsertImageFromDevice] withObject:insertImageFromDevice];
        } else {
            [items addObject:insertImageFromDevice];
        }
    }

    // Insert Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarInsertLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *insertLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSlink.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(insertLink)];
        insertLink.label = @"link";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarInsertLink] withObject:insertLink];
        } else {
            [items addObject:insertLink];
        }
    }

    // Remove Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarRemoveLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *removeLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSunlink.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(removeLink)];
        removeLink.label = @"removeLink";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarRemoveLink] withObject:removeLink];
        } else {
            [items addObject:removeLink];
        }
    }

    // Quick Link
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarQuickLink]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *quickLink = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ZSSquicklink.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(quickLink)];
        quickLink.label = @"quickLink";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarQuickLink] withObject:quickLink];
        } else {
            [items addObject:quickLink];
        }
    }

    // Show Source
    if ((_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarViewSource]) || (_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarAll])) {
        ZSSBarButtonItem *showSource = [[ZSSBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SFviewsource.png" inBundle:bundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(showHTMLSource:)];
        showSource.label = @"source";
        if (customOrder) {
            [items replaceObjectAtIndex:[_enabledToolbarItems indexOfObject:ZSSRichTextEditorToolbarViewSource] withObject:showSource];
        } else {
            [items addObject:showSource];
        }
    }
    
    return [NSArray arrayWithArray:items];
}


- (void)buildToolbar {
    // Check to see if we have any toolbar items, if not, add them all
    NSArray *items = [self itemsForToolbar];
    if (items.count == 0 && !(_enabledToolbarItems && [_enabledToolbarItems containsObject:ZSSRichTextEditorToolbarNone])) {
        _enabledToolbarItems = @[ZSSRichTextEditorToolbarAll];
        items = [self itemsForToolbar];
    }
    
    if (self.customZSSBarButtonItems != nil) {
        items = [items arrayByAddingObjectsFromArray:self.customZSSBarButtonItems];
    }
    
    // get the width before we add custom buttons
    CGFloat toolbarWidth = items.count == 0 ? 0.0f : (CGFloat)(items.count * (44 + 12.0f));
    
    if (self.customBarButtonItems != nil) {
        items = [items arrayByAddingObjectsFromArray:self.customBarButtonItems];
        for(ZSSBarButtonItem *buttonItem in self.customBarButtonItems) {
            toolbarWidth += buttonItem.customView.frame.size.width + 12.0f;
        }
    }
    
    self.toolbar.items = items;
    for (ZSSBarButtonItem *item in items) {
        item.tintColor = [self barButtonItemDefaultColor];
    }
    
    self.toolbar.frame = CGRectMake(0, 0, toolbarWidth, 44);
    self.toolBarScroll.contentSize = CGSizeMake(self.toolbar.frame.size.width, 44);
}


#pragma mark - Editor Modification Section，
#pragma mark -- js库用的是wang_editor，一下js方法不是全部实现，仅对梨花写作支持的格式控制做了支持

- (void)setCSS:(NSString *)css {
    self.customCSS = css;
    if (self.editorLoaded) {
        [self updateCSS];
    }
}

- (void)updateCSS {
    if (self.customCSS != NULL && [self.customCSS length] != 0) {
        NSString *js = [NSString stringWithFormat:@"RE.setCustomCSS('%@');", self.customCSS];
        [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
         
        }];
    }
}

- (void)setPlaceholderText {
    //Call the setPlaceholder javascript method if a placeholder has been set
    if (self.placeholder != NULL && [self.placeholder length] != 0) {
        NSString *js = [NSString stringWithFormat:@"RE.setPlaceholder('%@');", self.placeholder];
        [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
         
        }];
    }
}

- (void)setFooterHeight:(float)footerHeight {
    //Call the setFooterHeight javascript method
    NSString *js = [NSString stringWithFormat:@"RE.setFooterHeight('%f');", footerHeight];
    [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setContentHeight:(float)contentHeight {
    //Call the contentHeight javascript method
    NSString *js = [NSString stringWithFormat:@"RE.contentHeight = %f;", contentHeight];
    [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

#pragma mark - Editor Interaction

- (void)focusTextEditor {
    //TODO: Is this behavior correct? Is it the right replacement?
//    self.editorView.keyboardDisplayRequiresUserAction = NO;
//    [ZSSRichTextEditor allowDisplayingKeyboardWithoutUserAction];
    NSString *js = [NSString stringWithFormat:@"RE.focusEditor();"];
    [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)blurTextEditor {
    NSString *js = [NSString stringWithFormat:@"RE.blurEditor();"];
    [self.editorView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setHTML:(NSString *)html {
    self.internalHTML = html;
    if (self.editorLoaded) {
        [self updateHTML];
    }
}

- (void)updateHTML {
    NSString *html = self.internalHTML;
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"RE.setHtml('%@');", cleanedHTML];
    __weak typeof(self) weakSelf = self;
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        
    }];
}

- (void)getHTML:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {
    __weak typeof(self) weakSelf = self;
    [self.editorView evaluateJavaScript:ZSSEditorHTML completionHandler:^(NSString *result, NSError *error) {
        if (error != NULL) {
            NSLog(@"HTML Parsing Error: %@", error);
        }
        NSString *html = [weakSelf removeQuotesFromHTML:result];
        completionHandler(html, error);
        // 去掉这些多余解析
        /*
        NSLog(@"%@", result);
        NSString *html = [weakSelf removeQuotesFromHTML:result];
        NSLog(@"%@", html);
        [self tidyHTML:html completionHandler:^(NSString *result, NSError *error) {
            completionHandler(result, error);
        }];
         */
    }];
}


- (void)insertHTML:(NSString *)html {
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"RE.insertHTML('%@');", cleanedHTML];
    __weak typeof(self) weakSelf = self;
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        
    }];
}

- (void)getText:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {
    [self.editorView evaluateJavaScript:ZSSEditorText completionHandler:^(NSString *result, NSError *error) {
        if (error != NULL) {
            NSLog(@"Text Parsing Error: %@", error);
        }
        completionHandler(result, error);
    }];
}

- (void)updateEditor {
    [self getHTML:^(NSString *htmlResult, NSError * _Nullable error) {
        // 通过正则匹配去掉标签获取text
        NSString *text = [self getZZwithString:htmlResult];
        [self editorDidChangeWithText:text andHTML:htmlResult];
    }];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (BOOL)isFirstResponder {
    __weak typeof(self) weakSelf = self;
    [self.editorView evaluateJavaScript:ZSSEditorContent completionHandler:^(NSNumber *result, NSError *error) {
        //save the result as a bool and then update the UI
        weakSelf.isFirstResponderUpdated = [result boolValue];
        if (weakSelf.isFirstResponderUpdated == true) {
            [weakSelf becomeFirstResponder];
        } else {
            [weakSelf resignFirstResponder];
        }
    }];
    
    //this state is old and will quickly be updated after the callback above completes
    //TODO: refactor to find a more elegant approach
    return self.isFirstResponderUpdated;
}

- (void)showHTMLSource:(ZSSBarButtonItem *)barButtonItem {
    if (self.sourceView.hidden) {
        __weak typeof(self) weakSelf = self;
        [self getHTML:^(NSString *result, NSError * _Nullable error) {
            weakSelf.sourceView.text = result;
        }];
        
        self.sourceView.hidden = NO;
        barButtonItem.tintColor = [UIColor blackColor];
        self.editorView.hidden = YES;
        [self enableToolbarItems:NO];
    } else {
        [self setHTML:self.sourceView.text];
        barButtonItem.tintColor = [self barButtonItemDefaultColor];
        self.sourceView.hidden = YES;
        self.editorView.hidden = NO;
        [self enableToolbarItems:YES];
    }
}

- (void)removeFormat {
    NSString *trigger = @"RE.removeFormating();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)alignLeft {
    NSString *trigger = @"RE.setJustifyLeft();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"align" value:@"left"];
    }];
}

- (void)alignCenter {
    NSString *trigger = @"RE.setJustifyCenter();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"align" value:@"center"];
    }];
}

- (void)alignRight {
    NSString *trigger = @"RE.setJustifyRight();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"align" value:@"right"];
    }];
}

- (void)alignFull {
    NSString *trigger = @"RE.setJustifyFull();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setBold {
    NSString *trigger = @"RE.setBold();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"font" value:@"bold"];
    }];
}

- (void)setItalic {
    NSString *trigger = @"RE.setItalic();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"font" value:@"italic"];
    }];
}

- (void)setSubscript {
    NSString *trigger = @"RE.setSubscript();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setUnderline {
    NSString *trigger = @"RE.setUnderline();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"font" value:@"underline"];
    }];
}

- (void)setSuperscript {
    NSString *trigger = @"RE.setSuperscript();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setStrikethrough {
    NSString *trigger = @"RE.setStrikeThrough();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setUnorderedList {
    NSString *trigger = @"RE.setBullets();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"sort" value:@"bullets"];
    }];
}

- (void)setOrderedList {
    NSString *trigger = @"RE.setNumbers();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"sort" value:@"number"];
    }];
}

- (void)setHR {
    NSString *trigger = @"RE.setHorizontalRule();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)setIndent {
    NSString *trigger = @"RE.setIndent();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"indent" value:@"indent"];
    }];
}

- (void)setOutdent {
    NSString *trigger = @"RE.setOutdent();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"indent" value:@"outdent"];
    }];
}

/// 梨花写作需求：小标题对于h2 以此类推
- (void)heading1:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('2');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
            [self didSetStyle:@"paragraph" value:@"H2"];
        }];
    }
}

- (void)heading2:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('3');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
            [self didSetStyle:@"paragraph" value:@"H3"];
        }];
    }
}

- (void)heading3:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('4');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
            [self didSetStyle:@"paragraph" value:@"H4"];
        }];
    }
}

- (void)heading4:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('4');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
         
        }];
    }
}


- (void)heading5:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('h5');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
         
        }];
    }
}

- (void)heading6:(UIBarButtonItem *)item {
    if (item.tag == 1) {
        [self paragraph];
    } else {
        NSString *trigger = @"RE.setHeading('h6');";
        [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
         
        }];
    }
}

- (void)paragraph {
    NSString *trigger = @"RE.setParagraph();";
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"paragraph" value:@"p"];
    }];
}

- (void)showFontsPicker {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    
    //Call picker
    ZSSFontsViewController *fontPicker = [ZSSFontsViewController cancelableFontPickerViewControllerWithFontFamily:ZSSFontFamilyDefault];
    fontPicker.delegate = self;
    [self.navigationController pushViewController:fontPicker animated:YES];
    
}

- (void)setSelectedFontFamily:(ZSSFontFamily)fontFamily {
    
    NSString *fontFamilyString;
    
    switch (fontFamily) {
        case ZSSFontFamilyDefault:
            fontFamilyString = @"Arial, Helvetica, sans-serif";
            break;
            
        case ZSSFontFamilyGeorgia:
            fontFamilyString = @"Georgia, serif";
            break;
            
        case ZSSFontFamilyPalatino:
            fontFamilyString = @"Palatino Linotype, Book Antiqua, Palatino, serif";
            break;
            
        case ZSSFontFamilyTimesNew:
            fontFamilyString = @"Times New Roman, Times, serif";
            break;
            
        case ZSSFontFamilyTrebuchet:
            fontFamilyString = @"Trebuchet MS, Helvetica, sans-serif";
            break;
            
        case ZSSFontFamilyVerdana:
            fontFamilyString = @"Verdana, Geneva, sans-serif";
            break;
            
        case ZSSFontFamilyCourierNew:
            fontFamilyString = @"Courier New, Courier, monospace";
            break;
            
        default:
            fontFamilyString = @"Arial, Helvetica, sans-serif";
            break;
    }
    
    NSString *trigger = [NSString stringWithFormat:@"RE.setFontFamily('%@');", fontFamilyString];
    
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)textColor {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 1;
    colorPicker.title = NSLocalizedString(@"Text Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
}

- (void)bgColor {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    
    // Call the picker
    HRColorPickerViewController *colorPicker = [HRColorPickerViewController cancelableFullColorPickerViewControllerWithColor:[UIColor whiteColor]];
    colorPicker.delegate = self;
    colorPicker.tag = 2;
    colorPicker.title = NSLocalizedString(@"BG Color", nil);
    [self.navigationController pushViewController:colorPicker animated:YES];
}

- (void)setSelectedColor:(UIColor*)color tag:(int)tag {
    NSString *hex = [NSString stringWithFormat:@"#%06x",HexColorFromUIColor(color)];
    NSString *trigger;
    if (tag == 1) {
        trigger = [NSString stringWithFormat:@"RE.setTextColor('%@');", hex];
    } else if (tag == 2) {
        trigger = [NSString stringWithFormat:@"RE.setBackgroundColor('%@');", hex];
    }
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
    
    }];
}

- (void)undo:(UIBarButtonItem *)barButtonItem {
    [self.editorView evaluateJavaScript:@"RE.undo();" completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"undo" value:nil];
    }];
}

- (void)redo:(UIBarButtonItem *)barButtonItem {
    [self.editorView evaluateJavaScript:@"RE.redo();" completionHandler:^(NSString *result, NSError *error) {
        [self didSetStyle:@"redo" value:nil];
    }];
}

- (void)insertLink {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];

    // Show the dialog for inserting or editing a link
    [self showInsertLinkDialogWithLink:self.selectedLinkURL title:self.selectedLinkTitle];
}


- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title {
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedLinkURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[ZSSRichTextEditor class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertURLAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Title", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (title) {
                textField.text = title;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *linkURL = [alertController.textFields objectAtIndex:0];
            UITextField *title = [alertController.textFields objectAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
                //NSLog(@"insert link");
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
    } else {
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Link", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 2;
        UITextField *linkURL = [self.alertView textFieldAtIndex:0];
        linkURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            linkURL.text = url;
        }
        
        linkURL.rightView = am;
        linkURL.rightViewMode = UITextFieldViewModeAlways;
        
        UITextField *alt = [self.alertView textFieldAtIndex:1];
        alt.secureTextEntry = NO;
        alt.placeholder = NSLocalizedString(@"Title", nil);
        if (title) {
            alt.text = title;
        }
        
        [self.alertView show];
    }
    
}

- (void)insertLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"RE.insertLink('%@', '%@');", url, title];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
    if (_receiveEditorDidChangeEvents) {
        [self updateEditor];
    }
}


- (void)updateLink:(NSString *)url title:(NSString *)title {
    NSString *trigger = [NSString stringWithFormat:@"RE.updateLink('%@', '%@');", url, title];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
    if (_receiveEditorDidChangeEvents) {
        [self updateEditor];
    }
}


- (void)dismissAlertView {
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:YES];
}

- (void)addCustomToolbarItemWithButton:(UIButton *)button {
    
    if(self.customBarButtonItems == nil) {
        self.customBarButtonItems = [NSMutableArray array];
    }
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28.5f];
    [button setTitleColor:[self barButtonItemDefaultColor] forState:UIControlStateNormal];
    [button setTitleColor:[self barButtonItemSelectedDefaultColor] forState:UIControlStateHighlighted];
    
    ZSSBarButtonItem *barButtonItem = [[ZSSBarButtonItem alloc] initWithCustomView:button];
    [self.customBarButtonItems addObject:barButtonItem];
    [self buildToolbar];
}

- (void)addCustomToolbarItem:(ZSSBarButtonItem *)item {
    if(self.customZSSBarButtonItems == nil) {
        self.customZSSBarButtonItems = [NSMutableArray array];
    }
    [self.customZSSBarButtonItems addObject:item];
    [self buildToolbar];
}

- (void)removeLink {
    [self.editorView evaluateJavaScript:@"RE.unlink();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    
    if (_receiveEditorDidChangeEvents) {
        [self updateEditor];
    }
}

- (void)quickLink {
    [self.editorView evaluateJavaScript:@"RE.quickLink();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    
    if (_receiveEditorDidChangeEvents) {
        [self updateEditor];
    }
}

- (void)insertImage {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];

    [self showInsertImageDialogWithLink:self.selectedImageURL alt:self.selectedImageAlt];
}

- (void)insertImageFromDevice {
    // Save the selection location
    [self.editorView evaluateJavaScript:@"RE.prepareInsert();" completionHandler:^(NSString *result, NSError *error) {
     
    }];
    [self showInsertImageDialogFromDeviceWithScale:self.selectedImageScale alt:self.selectedImageAlt];
}

- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt {
    
    // Insert Button Title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Insert", nil) : NSLocalizedString(@"Update", nil);
    
    // Picker Button
    UIButton *am = [UIButton buttonWithType:UIButtonTypeCustom];
    am.frame = CGRectMake(0, 0, 25, 25);
    [am setImage:[UIImage imageNamed:@"ZSSpicker.png" inBundle:[NSBundle bundleForClass:[ZSSRichTextEditor class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [am addTarget:self action:@selector(showInsertImageAlternatePicker) forControlEvents:UIControlEventTouchUpInside];
    
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"URL (required)", nil);
            if (url) {
                textField.text = url;
            }
            textField.rightView = am;
            textField.rightViewMode = UITextFieldViewModeAlways;
            textField.clearButtonMode = UITextFieldViewModeAlways;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *imageURL = [alertController.textFields objectAtIndex:0];
            UITextField *alt = [alertController.textFields objectAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
            [self focusTextEditor];
        }]];
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 1;
        UITextField *imageURL = [self.alertView textFieldAtIndex:0];
        imageURL.placeholder = NSLocalizedString(@"URL (required)", nil);
        if (url) {
            imageURL.text = url;
        }
        
        imageURL.rightView = am;
        imageURL.rightViewMode = UITextFieldViewModeAlways;
        imageURL.clearButtonMode = UITextFieldViewModeAlways;
        
        UITextField *alt1 = [self.alertView textFieldAtIndex:1];
        alt1.secureTextEntry = NO;
        alt1.placeholder = NSLocalizedString(@"Alt", nil);
        alt1.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            alt1.text = alt;
        }
        
        [self.alertView show];
    }
    
}

- (void)showInsertImageDialogFromDeviceWithScale:(CGFloat)scale alt:(NSString *)alt {
    
    // Insert button title
    NSString *insertButtonTitle = !self.selectedImageURL ? NSLocalizedString(@"Pick Image", nil) : NSLocalizedString(@"Pick New Image", nil);
    
    //If the OS version supports the new UIAlertController go for it. Otherwise use the old UIAlertView
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Insert Image From Device", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        //Add alt text field
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Alt", nil);
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            if (alt) {
                textField.text = alt;
            }
        }];
        
        //Add scale text field
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.clearButtonMode = UITextFieldViewModeAlways;
            textField.secureTextEntry = NO;
            textField.placeholder = NSLocalizedString(@"Image scale, 0.5 by default", nil);
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        }];
        
        //Cancel action
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self focusTextEditor];
        }]];
        
        //Insert action
        [alertController addAction:[UIAlertAction actionWithTitle:insertButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *textFieldAlt = [alertController.textFields objectAtIndex:0];
            UITextField *textFieldScale = [alertController.textFields objectAtIndex:1];
            
            self.selectedImageScale = [textFieldScale.text floatValue]?:kDefaultScale;
            self.selectedImageAlt = textFieldAlt.text?:@"";
            
            [self presentViewController:self.imagePicker animated:YES completion:nil];
            
        }]];
        
        [self presentViewController:alertController animated:YES completion:NULL];
        
    } else {
        
        self.alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Insert Image", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:insertButtonTitle, nil];
        self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        self.alertView.tag = 3;
        
        UITextField *textFieldAlt = [self.alertView textFieldAtIndex:0];
        textFieldAlt.secureTextEntry = NO;
        textFieldAlt.placeholder = NSLocalizedString(@"Alt", nil);
        textFieldAlt.clearButtonMode = UITextFieldViewModeAlways;
        if (alt) {
            textFieldAlt.text = alt;
        }
        
        UITextField *textFieldScale = [self.alertView textFieldAtIndex:1];
        textFieldScale.placeholder = NSLocalizedString(@"Image scale, 0.5 by default", nil);
        textFieldScale.keyboardType = UIKeyboardTypeDecimalPad;
        
        [self.alertView show];
    }
    
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"RE.insertImage('%@', '%@');", url, alt];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
        
    }];
}

- (void)insertImage:(NSString *)url alt:(NSString *)alt  width:(CGFloat)width height:(CGFloat)height {
    NSString *trigger = [NSString stringWithFormat:@"RE.insertImageWH('%@', '%@', '%@', '%@');", url, alt, @(width), @(height)];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {

    }];
}

- (void)updateImage:(NSString *)url alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"RE.updateImage('%@', '%@');", url, alt];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)insertImageBase64String:(NSString *)imageBase64String alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"RE.insertImageBase64String('%@', '%@');", imageBase64String, alt];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)updateImageBase64String:(NSString *)imageBase64String alt:(NSString *)alt {
    NSString *trigger = [NSString stringWithFormat:@"RE.updateImageBase64String('%@', '%@');", imageBase64String, alt];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)removeHighlight {
    NSString *trigger = [NSString stringWithFormat:@"RE.removeHighlight();"];
    [self.editorView evaluateJavaScript:trigger completionHandler:^(NSString *result, NSError *error) {
     
    }];
}

- (void)updateToolBarWithButtonName:(NSString *)name {
    
    // Items that are enabled
    NSMutableArray *itemNames = [[name componentsSeparatedByString:@","] mutableCopy];
    
    // 加上默认左对齐
    if ([itemNames containsObject:@"justifyCenter"] ||
        [itemNames containsObject:@"justifyRight"] ||
        [itemNames containsObject:@"justifyLeft"]) {
        // 有justify样式，就不主动设置
    } else {
        [itemNames addObject:@"justifyLeft"];
    }
    
    // Special case for link
    NSMutableArray *itemsModified = [[NSMutableArray alloc] init];
    for (NSString *linkItem in itemNames) {
        NSString *updatedItem = linkItem;
        if ([linkItem hasPrefix:@"link:"]) {
            updatedItem = @"link";
            self.selectedLinkURL = [linkItem stringByReplacingOccurrencesOfString:@"link:" withString:@""];
        } else if ([linkItem hasPrefix:@"link-title:"]) {
            self.selectedLinkTitle = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"link-title:" withString:@""]];
        } else if ([linkItem hasPrefix:@"image:"]) {
            updatedItem = @"image";
            self.selectedImageURL = [linkItem stringByReplacingOccurrencesOfString:@"image:" withString:@""];
        } else if ([linkItem hasPrefix:@"image-alt:"]) {
            self.selectedImageAlt = [self stringByDecodingURLFormat:[linkItem stringByReplacingOccurrencesOfString:@"image-alt:" withString:@""]];
        } else {
            self.selectedImageURL = nil;
            self.selectedImageAlt = nil;
            self.selectedLinkURL = nil;
            self.selectedLinkTitle = nil;
        }
        [itemsModified addObject:updatedItem];
    }
    itemNames = [NSArray arrayWithArray:itemsModified];
    
    self.editorItemsEnabled = itemNames;
    
    // Highlight items
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if ([itemNames containsObject:item.label]) {
            item.tintColor = [self barButtonItemSelectedDefaultColor];
            item.tag = 1;
        } else {
            item.tintColor = [self barButtonItemDefaultColor];
            item.tag = 0;
        }
    }
    
}

#pragma mark - WKScriptMessageHandler Delegate

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *urlString = (NSString *)message.body;
    NSLog(@"Message received: %@", urlString);
    if ([urlString rangeOfString:@"change://"].location != NSNotFound) {
        // We recieved the callback
        // 更新高度
        [self updateEditorHeight:YES];
        NSString *className = [urlString stringByReplacingOccurrencesOfString:@"change://" withString:@""];
        [self updateToolBarWithButtonName:className];
        if (_receiveEditorDidChangeEvents) {
            // 回调出去做 上一步 下一步的处理
            [self updateEditor];
        }
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        NSLog(@"Debug Found");
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
    } else if ([urlString rangeOfString:@"updateHeight://"].location != NSNotFound) {
        [self updateEditorHeight:NO];
    } else if ([urlString isEqualToString:@"input"]) {
        // 更新高度
        [self updateEditorHeight:NO];
    } else {
        [self recivedMessage:message];
    }
}

#pragma mark - WKNavigationDelegate Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *query = [navigationAction.request.URL query];
    NSString *urlString = [navigationAction.request.URL absoluteString];
    decisionHandler(WKNavigationActionPolicyAllow);
    NSLog(@"web request = %@", urlString);
    NSLog(@"web request = %@", query);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.editorLoaded = YES;
    if (!self.internalHTML) {
        self.internalHTML = @"";
    }
    [self updateHTML];
    if(self.placeholder) {
        [self setPlaceholderText];
    }
    if (self.customCSS) {
        [self updateCSS];
    }
    if (self.shouldShowKeyboard) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self focusTextEditor];
        });
    }
    // 添加EventListener
    NSString *inputListener = @"document.getElementById('editor-text-area').addEventListener('input', function() {window.webkit.messageHandlers.jsm.postMessage('input');});";
    [self.editorView evaluateJavaScript:inputListener completionHandler:^(NSString *result, NSError *error) {
        if (error != NULL) {
            NSLog(@"%@", error);
        }
    }];
    
    // 第一次加载成功回调
    [self editorContentDidLoad];
    
    /* addEventListener：js method, not needy in wang editor, it has its own change callback
     Create listeners for when text is changed, solution by @madebydouglas derived from richardortiz84 https://github.com/nnhubbard/ZSSRichTextEditor/issues/5
     */
//    NSString *inputListener = @"document.getElementById('zss_editor_content').addEventListener('input', function() {window.webkit.messageHandlers.jsm.postMessage('input');});";
//    NSString *pasteListener = @"document.getElementById('zss_editor_content').addEventListener('paste', function() {window.webkit.messageHandlers.jsm.postMessage('paste');});";
//    [self.editorView evaluateJavaScript:inputListener completionHandler:^(NSString *result, NSError *error) {
//        if (error != NULL) {
//            NSLog(@"%@", error);
//        }
//    }];
//    [self.editorView evaluateJavaScript:pasteListener completionHandler:^(NSString *result, NSError *error) {
//        if (error != NULL) {
//            NSLog(@"%@", error);
//        }
//    }];
}

#pragma mark - Mention & Hashtag Support Section

- (void)checkForMentionOrHashtagInText:(NSString *)text {
    if ([text containsString:@" "] && [text length] > 0) {
        NSString *lastWord = nil;
        NSString *matchedWord = nil;
        BOOL ContainsHashtag = NO;
        BOOL ContainsMention = NO;
        
        NSRange range = [text rangeOfString:@" " options:NSBackwardsSearch];
        lastWord = [text substringFromIndex:range.location];
        
        if (lastWord != nil) {
            //Check if last word typed starts with a #
            NSRegularExpression *hashtagRegex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
            NSArray *hashtagMatches = [hashtagRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
            for (NSTextCheckingResult *match in hashtagMatches) {
                NSRange wordRange = [match rangeAtIndex:1];
                NSString *word = [lastWord substringWithRange:wordRange];
                matchedWord = word;
                ContainsHashtag = YES;
            }
            
            if (!ContainsHashtag) {
                //Check if last word typed starts with a @
                NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
                NSArray *mentionMatches = [mentionRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
                
                for (NSTextCheckingResult *match in mentionMatches) {
                    NSRange wordRange = [match rangeAtIndex:1];
                    NSString *word = [lastWord substringWithRange:wordRange];
                    matchedWord = word;
                    ContainsMention = YES;
                }
            }
        }
        
        if (ContainsHashtag) {
            [self hashtagRecognizedWithWord:matchedWord];
        }
        
        if (ContainsMention) {
            [self mentionRecognizedWithWord:matchedWord];
        }
    }
    
}

#pragma mark - Callbacks
- (void)editorDidScrollWithPosition:(NSInteger)position {}

- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html  {}

- (void)hashtagRecognizedWithWord:(NSString *)word {}

- (void)mentionRecognizedWithWord:(NSString *)word {}

- (void)editorContentDidLoad {}

- (void)toast:(NSString *)message {}

- (void)didSetStyle:(NSString *)style value:(NSString *)value {}

- (void)recivedMessage:(WKScriptMessage *)message {}

#pragma mark - AlertView

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if (alertView.tag == 1) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        UITextField *textField2 = [alertView textFieldAtIndex:1];
        if ([textField.text length] == 0 || [textField2.text length] == 0) {
            return NO;
        }
    } else if (alertView.tag == 2) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0) {
            return NO;
        }
    }
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            UITextField *imageURL = [alertView textFieldAtIndex:0];
            UITextField *alt = [alertView textFieldAtIndex:1];
            if (!self.selectedImageURL) {
                [self insertImage:imageURL.text alt:alt.text];
            } else {
                [self updateImage:imageURL.text alt:alt.text];
            }
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            UITextField *linkURL = [alertView textFieldAtIndex:0];
            UITextField *title = [alertView textFieldAtIndex:1];
            if (!self.selectedLinkURL) {
                [self insertLink:linkURL.text title:title.text];
            } else {
                [self updateLink:linkURL.text title:title.text];
            }
        }
    } else if (alertView.tag == 3) {
        if (buttonIndex == 1) {
            UITextField *textFieldAlt = [alertView textFieldAtIndex:0];
            UITextField *textFieldScale = [alertView textFieldAtIndex:1];
            
            self.selectedImageScale = [textFieldScale.text floatValue]?:kDefaultScale;
            self.selectedImageAlt = textFieldAlt.text?:@"";
            
            [self presentViewController:self.imagePicker animated:YES completion:nil];
            
        }
    }
}

#pragma mark - Asset Picker

- (void)showInsertURLAlternatePicker {
    // Blank method. User should implement this in their subclass
}

- (void)showInsertImageAlternatePicker {
    // Blank method. User should implement this in their subclass
}

#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //Dismiss the Image Picker
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info{
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage]?:info[UIImagePickerControllerOriginalImage];
    
    //Scale the image
    CGSize targetSize = CGSizeMake(selectedImage.size.width * self.selectedImageScale, selectedImage.size.height * self.selectedImageScale);
    UIGraphicsBeginImageContext(targetSize);
    [selectedImage drawInRect:CGRectMake(0,0,targetSize.width,targetSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Compress the image, as it is going to be encoded rather than linked
    NSData *scaledImageData = UIImageJPEGRepresentation(scaledImage, kJPEGCompression);
    
    //Encode the image data as a base64 string
    NSString *imageBase64String = [scaledImageData base64EncodedStringWithOptions:0];
    
    //Decide if we have to insert or update
    if (!self.imageBase64String) {
        [self insertImageBase64String:imageBase64String alt:self.selectedImageAlt];
    } else {
        [self updateImageBase64String:imageBase64String alt:self.selectedImageAlt];
    }
    
    self.imageBase64String = imageBase64String;
    
    //Dismiss the Image Picker
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Utilities

// 有用不能删：wang editor会改变输入
- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}

- (void)tidyHTML:(NSString *)html completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {
    /*
    html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br />"];
    html = [html stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
    if (self.formatHTML) {
        /// style_html是JSBeautifier的方法
        html = [NSString stringWithFormat:@"style_html('%@');", html];
        [self.editorView evaluateJavaScript:html completionHandler:^(NSString *result, NSError *error) {
            if (error != NULL) {
                NSLog(@"HTML Tidying Error: %@", error);
            }
            NSLog(@"%@", result);
            completionHandler(result, error);
        }];
    } else {
        completionHandler(html, NULL);
    }
     */
    completionHandler(html, NULL);
}

- (UIColor *)barButtonItemDefaultColor {
    
    if (self.toolbarItemTintColor) {
        return self.toolbarItemTintColor;
    }
    
    return [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}

- (UIColor *)barButtonItemSelectedDefaultColor {
    
    if (self.toolbarItemSelectedTintColor) {
        return self.toolbarItemSelectedTintColor;
    }
    
    return [UIColor blackColor];
}


- (BOOL)isIpad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}


- (NSString *)stringByDecodingURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (void)enableToolbarItems:(BOOL)enable {
    NSArray *items = self.toolbar.items;
    for (ZSSBarButtonItem *item in items) {
        if (![item.label isEqualToString:@"source"]) {
            item.enabled = enable;
        }
    }
}

- (NSString *)getZZwithString:(NSString *)html {
    if (html.length <= 0) {
        return @"";
    }
    NSString *blankStr1 =@" ";
    html = [html stringByReplacingOccurrencesOfString:blankStr1 withString:@""];
    NSString *emspStr1 =@"&emsp;";
    html = [html stringByReplacingOccurrencesOfString:emspStr1 withString:@""];
    NSString *regEx =@"&nbsp;";
    html = [html stringByReplacingOccurrencesOfString:regEx withString:@""];
    NSString *regEx1 =@"<br>";
    html = [html stringByReplacingOccurrencesOfString:regEx1 withString:@""];
    NSString *regEx2 =@"<br/>";
    html = [html stringByReplacingOccurrencesOfString:regEx2 withString:@""];
    NSRegularExpression *regularExpretion = [NSRegularExpression regularExpressionWithPattern:@"<[^>]*>|"
                                                                                    options:0
                                                                                      error:nil];
    html = [regularExpretion stringByReplacingMatchesInString:html
                                                      options:NSMatchingReportProgress
                                                        range:NSMakeRange(0, html.length)
                                                 withTemplate:@""];
    return html;
}

#pragma mark - Memory Warning Section
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

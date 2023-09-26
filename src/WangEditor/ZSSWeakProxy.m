//
//  ZSSWeakProxy.m
//  SFRichTextEditor
//
//  Created by Jimzhang on 2022/11/3.
//

#import "ZSSWeakProxy.h"

@implementation ZSSWeakProxy

+ (instancetype)weakProxy:(id)object {
    return [[ZSSWeakProxy alloc] initWithObject:object];
}

- (instancetype)initWithObject:(id)object {
    self.object = object;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.object methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.object];
}

@end

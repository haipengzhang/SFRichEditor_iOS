//
//  ZSSWeakProxy.h
//  SFRichTextEditor
//
//  Created by Jimzhang on 2022/11/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZSSWeakProxy : NSProxy

+ (instancetype)weakProxy:(id)object;

@property (nonatomic, weak) id object;

@end

NS_ASSUME_NONNULL_END

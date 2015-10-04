//
//  CKHTask.m
//  ETicketClient
//
//  Created by GevinChen on 2015/9/30.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import "CKHTask.h"

@implementation CKHTask


- (instancetype)init
{
    self = [super init];
    if (self) {
        _blocks = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

-(instancetype)initWith:(CKHTaskBlock)taskBlock,...
{
    self = [super init];
    if (self) {
        _blocks = [[NSMutableArray alloc] initWithCapacity:10];
        va_list args;
        va_start(args, taskBlock);
        for ( CKHTaskBlock arg = taskBlock; arg != nil; arg = va_arg(args, CKHTaskBlock) )
        {
            [_blocks addObject: arg ];
        }
        va_end(args);
        
    }
    return self;
}

-(void)runWith:(CKHTaskBlock)taskBlock,...
{
    va_list args;
    va_start(args, taskBlock);
    for ( CKHTaskBlock arg = taskBlock; arg != nil; arg = va_arg(args, CKHTaskBlock) )
    {
        [_blocks addObject: arg ];
    }
    va_end(args);
}

-(void)start
{
    if ( _thread == nil ) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop) object:nil ];
        [_thread start];
        _playing = YES;
    }
}

-(void)next
{
    _hold = NO;
}


-(void)mainLoop
{
    @autoreleasepool {
        _playing = YES;
        while (YES) {
            
            CKHTaskBlock taskb = _blocks[currentIndex];
            _hold = taskb( self );
            while (_hold) {
                [NSThread sleepForTimeInterval:0.5];
            }
            currentIndex++;
            
            // 全部都執行完了
            if ( currentIndex == _blocks.count ) {
                _playing = NO;
                _finish = YES;
                break;
            }
        }
        
        _thread = nil;
    }
}

@end

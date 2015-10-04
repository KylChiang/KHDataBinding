//
//  CKHAsyncTask.m
//  ETicketClient
//
//  Created by GevinChen on 2015/10/2.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import "CKHAsyncTask.h"

@implementation CKHAsyncTask


- (instancetype)init
{
    self = [super init];
    if (self) {
        _tasks = [[NSMutableArray alloc] initWithCapacity:10 ];
    }
    return self;
}


-(void)addTask:(CKHTask*)task
{
    [_tasks addObject:task];    
}

-(void)start
{
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(mainLoop) object:nil];
    [_thread start];
    _playing = YES;
}


- (void)mainLoop
{
    @autoreleasepool {
        
        int i = 0;
        BOOL keepRun = YES;
        while ( keepRun ) {
            
            //  檢查 task 執行完了沒，全部都執行完成就離開迴圈
            //------------------------------------------
            while ( i < _tasks.count ) {
                CKHTask *task = _tasks[i];
                if (task.isFinish) {
                    [_tasks removeObjectAtIndex: i ];
                    if (_tasks.count == 0 ) {
                        keepRun = NO;
                        break;
                    }
                    continue;
                }
                i++;
            }
            [NSThread sleepForTimeInterval:0.5];
        }
        
        _playing = NO;
        _finish = YES;
        //  呼叫執行結束的 call back
        //------------------------------------------
        if ( _completed ) {
            _completed();
        }
        
        _thread = nil;
    }
    
}

@end

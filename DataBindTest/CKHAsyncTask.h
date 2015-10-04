//
//  CKHAsyncTask.h
//  ETicketClient
//
//  Created by GevinChen on 2015/10/2.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKHTask.h"

@interface CKHAsyncTask : NSObject
{
    
    NSMutableArray *_tasks;
    
    NSThread *_thread;
    
    //  完成的任務的數量
    NSInteger completedTaskCount;
    
}
@property (nonatomic,readonly,getter=isFinish) BOOL finish;
@property (nonatomic,readonly,getter=isPlaying) BOOL playing;
@property (nonatomic,copy) void(^completed)(void);

-(void)addTask:(CKHTask*)task;

-(void)start;

-(void)finish;

@end

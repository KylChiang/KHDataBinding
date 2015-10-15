//
//  CKHTask.h
//  ETicketClient
//
//  Created by GevinChen on 2015/9/30.
//  Copyright (c) 2015年 omg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CKHTask;

// return YES 表示要 hold 住執行緒等待，直到呼叫 CKHTask next 為止，主要是用在工作內容本身就已經是非同步執行的情況下，然後需要通知何時工作結束
typedef BOOL(^CKHTaskBlock)(CKHTask*task);

@interface CKHTask : NSObject
{
    void(^_taskBlock)(CKHTask*task);
    
    NSThread *_thread;
    
    NSMutableArray *_blocks;
    
    NSInteger currentIndex;
    
    BOOL _hold;
    
}

@property (nonatomic,readonly,getter=isFinish) BOOL finish;
@property (nonatomic,readonly,getter=isPlaying) BOOL playing;

-(instancetype)initWith:(CKHTaskBlock)taskBlock,...;

-(void)runWith:(CKHTaskBlock)taskBlock,...;

-(void)start;

-(void)next;

@end

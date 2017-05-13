//
//  AppDelegate.m
//  sandbox
//
//  Created by 仝兴伟 on 2017/5/13.
//  Copyright © 2017年 仝兴伟. All rights reserved.
//  将首次打开的文件路径保存到 NSUserDefaults中，每次App启动先检查 NSUserDefaults中是否保存有文件路径，有的话读取文件内容并且显示

// 遇到问题 1 打开txt文件出现 乱码 2 再次打开的时候之前写入到沙盒中的东西不见了


#import "AppDelegate.h"

#define  kFilePath @"kFilePath"

@interface AppDelegate ()
@property (weak) IBOutlet NSTextField *textField;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:kFilePath];
    // 如果文件路径不存在，不做任何操作
    if (!path) {
        return;
    }
    NSError *error;
    // 文件路径显示
    self.textField.stringValue = path;
    NSURL *url = [NSURL fileURLWithPath:path];
    // 读取文件内容
    NSString *string = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if (!error) {
        self.textView.string = string;
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark -- 按钮事件
// 保存文件
- (IBAction)saveClick:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 获取文件路径
    NSString *path = [defaults objectForKey:kFilePath];
    if (!path) {
        return;
    }
    
    NSString *text = self.textView.string;
    
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // 保存文件内容
    [text writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"save file error %@", error);
    }
}

- (IBAction)browseClick:(id)sender {
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    openDlg.canChooseFiles = YES;
    openDlg.canChooseDirectories = YES;
    openDlg.allowsMultipleSelection = YES;
    openDlg.allowedFileTypes = @[@"txt"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *fileURLs = [openDlg URLs];
            for (NSURL *url in fileURLs) {
                NSError *error;
                // 保存文件路径
                [defaults setObject:url.path forKey:kFilePath];
                [defaults synchronize];
                self.textField.stringValue = url.path;
                
                // 读取文件内容
                NSString *string = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
                
                if (!error) {
                    self.textView.string = string;
                }
            }
        }
    }];
}

@end

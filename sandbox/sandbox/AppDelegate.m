//
//  AppDelegate.m
//  sandbox
//
//  Created by 仝兴伟 on 2017/5/13.
//  Copyright © 2017年 仝兴伟. All rights reserved.
//  将首次打开的文件路径保存到 NSUserDefaults中，每次App启动先检查 NSUserDefaults中是否保存有文件路径，有的话读取文件内容并且显示

// 遇到问题 1 打开txt文件出现 乱码 2 再次打开的时候之前写入到沙盒中的东西不见了

/*
    App重新启动后，这个文件路径就不能直接访问了。想要永久获得应用的Container目录之外的文件，这里需要用到
 Security-Scoped Bookmark有两种
 
  An app-Scoped Bookmark 和  A document-scoped boolmark 两种
 An app-Scoped Bookmark---- 可以对应用中打开的文件或者文件夹再以后永久性访问而不需要再次通过NSOpenPanel代开。这种bookmark方式使用的比较多
 
 A document-scoped boolmark----- 提供对特殊的文档的永久访问权，可以理解为针对文档嵌套的一种权限模式。比如拟开发一个能编辑ppr文档的应用。里面嵌入了视频文件图片文件链接。那么下次打开这个ppt文档时候就能直接访问这些文件而不需要通过NSOPenPanel打开获取权限
 */

#import "AppDelegate.h"

#define  kFilePath @"kFilePath"

@interface AppDelegate ()
@property (weak) IBOutlet NSTextField *textField;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (weak) IBOutlet NSWindow *window;
@end

typedef void (^SBFileAccessBlock)();


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *path = [defaults objectForKey:kFilePath];
    // 如果文件路径不存在，不做任何操作
    if (!path) {
        return;
    }
     __block NSError *error;
    
    // 文件路径显示
    self.textField.stringValue = path;
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    [self accessFileURL:url withBlock:^{
        // 读取文件内容
        NSString *string = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        
        if (!error) {
            self.textView.string = string;
        }
    }];
    
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
                
                [self persistPermissionURL:url];
                
                // 读取文件内容
                NSString *string = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
                
                if (!error) {
                    self.textView.string = string;
                }
            }
        }
    }];
}

- (void)persistPermissionPath:(NSString *)path {
    [self persistPermissionURL:[NSURL fileURLWithPath:path]];
}

- (void)persistPermissionURL:(NSURL *)url {
    // store the sandbox permissions
    //NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
    
    NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSLog(@"persistPermissionURL bookmarkData %@ ",bookmarkData);
    
    if (bookmarkData) {
        
        [defaults setObject:bookmarkData forKey:url.path];
        
        [defaults synchronize];
    }
}

- (BOOL)accessFileURL:(NSURL *)fileUrl  withBlock:(SBFileAccessBlock)block {
    
    NSURL *allowedUrl = nil;
    
    // standardize the file url and remove any symlinks so that the url we lookup in bookmark data would match a url given by the askPermissionForUrl method
    // fileUrl = [[fileUrl URLByStandardizingPath] URLByResolvingSymlinksInPath];
    
    // lookup bookmark data for this url, this will automatically load bookmark data for a parent path if we have it
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *bookmarkData = [defaults objectForKey:fileUrl.path];
    
    
    NSLog(@"accessFileURL bookmarkData %@ ",bookmarkData);
    
    if (bookmarkData) {
        // resolve the bookmark data into an NSURL object that will allow us to use the file
        BOOL bookmarkDataIsStale;
        allowedUrl = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:NULL];
        // if the bookmark data is stale, we'll create new bookmark data further down
        if (bookmarkDataIsStale) {
            bookmarkData = nil;
        }
    }
    
    
    
    // if we have no bookmark data, we need to create it, this may be because our bookmark data was stale, or this is the first time being given permission
    if ( !bookmarkData) {
        [self persistPermissionURL:allowedUrl];
    }
    
    // execute the /block with the file access permissions
    @try {
        [allowedUrl startAccessingSecurityScopedResource];
        block();
    } @finally {
        [allowedUrl stopAccessingSecurityScopedResource];
    }
    
    return YES;
}



@end

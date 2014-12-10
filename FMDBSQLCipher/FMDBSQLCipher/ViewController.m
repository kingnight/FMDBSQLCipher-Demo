//
//  ViewController.m
//  FMDBSQLCipher
//
//  Created by pioneer on 14/12/8.
//  Copyright (c) 2014年 pioneer. All rights reserved.
//

#import "ViewController.h"
#import "sqlite3.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;
@property (weak, nonatomic) IBOutlet UILabel *runningTime;
@property (weak, nonatomic) IBOutlet UILabel *writeDoneTime;

@end

@implementation ViewController

sqlite3 *db;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *databasePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                              stringByAppendingPathComponent: @"sqlcipher.db"];
    NSLog(@"%@",databasePath);
    //self.DbPath.text=databasePath;
    
    if (sqlite3_open([databasePath UTF8String], &db) == SQLITE_OK) {
        const char* key = [@"BIGSecret" UTF8String];
        sqlite3_key(db, key, strlen(key));
        if(sqlite3_exec(db, (const char*) "CREATE TABLE sqlmaster (NAME TEXT , IMAGE BLOB);", NULL, NULL, NULL) ==SQLITE_OK)
        {
            // password is correct, or, database has been initialized
             
        } else {
            // incorrect password!
        }
        //sqlite3_close(db);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)writeToDbAction:(UIButton *)sender {
    NSLog(@"开始写入");
    NSDate *tmpStartData = [NSDate date];
    char *name = "test2";
    NSString * nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    NSString * filePath = [[NSBundle mainBundle] pathForResource:nameString ofType:@"jpg"];
    sqlite3_stmt * update;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData * imgData = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:filePath]);
        const  char * sequel = "insert into sqlmaster(name,image) values(?,?)";

        if (sqlite3_prepare_v2(db, sequel, -1, &update, NULL) == SQLITE_OK)
        {
            sqlite3_bind_text(update, 1, name, -1, NULL);
            sqlite3_bind_blob(update, 2, [imgData bytes], [imgData length], NULL);
            if(sqlite3_step(update) == SQLITE_DONE)
            {
                NSLog(@"已经写入数据");
            }
            sqlite3_finalize(update);
            double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
            self.writeDoneTime.text= [NSString stringWithFormat:@"%f",deltaTime*1000];
        }
    }
    else
    {
            NSLog(@"文件不存在");
    }
}

- (IBAction)readFromDbAction:(UIButton *)sender {
    NSLog(@"读取文件开始...");
    NSDate *tmpStartData = [NSDate date];
    const char * sequel = "select image from sqlmaster where name=?";
    sqlite3_stmt * getimg;
    if (sqlite3_prepare_v2(db, sequel, -1, &getimg, NULL) == SQLITE_OK)
    {
        NSLog(@"step 1");
        char *name = "test2";
        sqlite3_bind_text(getimg, 1, name, -1, NULL);
        if(sqlite3_step(getimg) == SQLITE_ROW)
        {
            int bytes = sqlite3_column_bytes(getimg, 0);
            Byte *value = (Byte*)sqlite3_column_blob(getimg, 0);
            NSLog(@"bytes=%d,value=%s",bytes,value);
            if (bytes !=0 && value != NULL)
            {
                NSData * data = [NSData dataWithBytes:value length:bytes];
                UIImage * img = [UIImage imageWithData:data];
                self.ImageView.image = img;
            }
        }
        else
            NSLog(@"fail 2");
        sqlite3_finalize(getimg);
        sqlite3_close(db);
        double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
        self.runningTime.text= [NSString stringWithFormat:@"%f",deltaTime*1000];
    }
    else
        NSLog(@"fail");
}

@end

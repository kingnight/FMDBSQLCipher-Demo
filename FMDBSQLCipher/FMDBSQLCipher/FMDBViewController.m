//
//  FMDBViewController.m
//  FMDBSQLCipher
//
//  Created by pioneer on 14/12/9.
//  Copyright (c) 2014年 pioneer. All rights reserved.
//

#import "FMDBViewController.h"
#import "FMDB.h"

@interface FMDBViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *readImageView;
@property (weak, nonatomic) IBOutlet UILabel *readTime;
@property (weak, nonatomic) IBOutlet UILabel *writeTime;
@property (nonatomic,retain) NSString *dbpath;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processIndicator;

@end

@implementation FMDBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.processIndicator startAnimating];
    // Do any additional setup after loading the view.
    NSString* docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.dbpath = [docsdir stringByAppendingPathComponent:@"user.sqlite"];
    NSLog(@"dbpath=%@",self.dbpath);
    FMDatabase *db = [FMDatabase databaseWithPath:self.dbpath];
    if (![db open]) {
        NSLog(@"db open error:%@",[db lastErrorMessage]);
        return;
    }
    [db setKey:@"secretKey"];
    NSString *createSql = @"CREATE TABLE sqlmaster (name TEXT , image BLOB)";
    if (![db executeUpdate:createSql]) {
        NSLog(@"db create error:%@",[db lastErrorMessage]);
    }

    [db close];
    [self.processIndicator stopAnimating];
    self.processIndicator.hidden = true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)writeDb:(UIButton *)sender {
    self.processIndicator.hidden = false;
    [self.processIndicator startAnimating];
    NSDate *tmpStartData = [NSDate date];
    char *name = "test2";
    NSString * nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    NSString * filePath = [[NSBundle mainBundle] pathForResource:nameString ofType:@"jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData * imgData = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:filePath]);

        FMDatabase *db = [FMDatabase databaseWithPath:self.dbpath];
        if (![db open]) {
            NSLog(@"db open error:%@",[db lastErrorMessage]);
            return;
        }
        [db setKey:@"secretKey"];
        NSString *sql = @"insert into sqlmaster (name,image) values(?,?)";
        BOOL res=[db executeUpdate:sql, nameString, imgData];
        if (res) {
            NSLog(@"succ insert");
        }
        else
            NSLog(@"fail insert");
        [db close];
        double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
        self.writeTime.text= [NSString stringWithFormat:@"%f",deltaTime*1000];
    }
    else
    {
        NSLog(@"文件不存在");
    }
    [self.processIndicator stopAnimating];
    self.processIndicator.hidden = true;
}

- (IBAction)readDb:(UIButton *)sender {
    NSDate *tmpStartData = [NSDate date];
    FMDatabase *db = [FMDatabase databaseWithPath:self.dbpath];
    if (![db open]) {
        NSLog(@"db open error:%@",[db lastErrorMessage]);
        return;
    }
    [db setKey:@"secretKey"];
    FMResultSet *s = [db executeQuery:@"select image from sqlmaster where name=?",@"test2"];
    if ([s next]) {
        NSData *data = [s dataForColumnIndex:0];
        UIImage * img = [UIImage imageWithData:data];
        self.readImageView.image = img;
    }
    [db close];
    double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    self.readTime.text= [NSString stringWithFormat:@"%f",deltaTime*1000];
}

- (IBAction)queryData:(UIButton *)sender {
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbpath];
    if ([db open]) {
        [db setKey:@"secretKey"];
        NSString * sql = @"select name from sqlmaster";
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            NSString * name = [rs stringForColumn:@"name"];
            NSLog(@"name=%@",name);
        }
        [db close];
    }
}

- (IBAction)deleteAll:(UIButton *)sender {
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbpath];
    if ([db open]) {
        [db setKey:@"secretKey"];
        NSString * sql = @"delete from sqlmaster";
        BOOL res = [db executeUpdate:sql];
        if (!res) {
            NSLog(@"error to delete db data");
        } else {
            NSLog(@"succ to deleta db data");
        }
        [db close];
    }
}

- (IBAction)multithread:(UIButton *)sender {
    FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:self.dbpath];
    dispatch_queue_t q1 = dispatch_queue_create("queue1", NULL);
    dispatch_queue_t q2 = dispatch_queue_create("queue2", NULL);
    
    dispatch_async(q1, ^{
        for (int i = 0; i < 1; ++i) {
            [queue inDatabase:^(FMDatabase *db) {
                [db setKey:@"secretKey"];
                char *name = "Roundicons-19";
                NSString * nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
                NSString * filePath = [[NSBundle mainBundle] pathForResource:nameString ofType:@"png"];
                NSData * imgData = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:filePath]);
                NSString * sql = @"insert into sqlmaster (name, image) values(?, ?) ";
                BOOL res = [db executeUpdate:sql, nameString, imgData];
                if (!res) {
                    NSLog(@"error to add db data");
                } else {
                    NSLog(@"succ to add db data");
                }
            }];
        }
    });
    
    dispatch_async(q2, ^{
        for (int i = 0; i < 1; ++i) {
            [queue inDatabase:^(FMDatabase *db) {
                [db setKey:@"secretKey"];
                char *name = "Roundicons-20";
                NSString * nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
                NSString * filePath = [[NSBundle mainBundle] pathForResource:nameString ofType:@"png"];
                NSData * imgData = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:filePath]);
                NSString * sql = @"insert into sqlmaster (name, image) values(?, ?) ";
                BOOL res = [db executeUpdate:sql, nameString, imgData];
                if (!res) {
                    NSLog(@"error to add db data");
                } else {
                    NSLog(@"succ to add db data");
                }
            }];
        }
    });
}

- (IBAction)readPic1:(UIButton *)sender {
    FMDatabase *db = [FMDatabase databaseWithPath:self.dbpath];
    if (![db open]) {
        NSLog(@"db open error:%@",[db lastErrorMessage]);
        return;
    }
    [db setKey:@"secretKey"];
    FMResultSet *s = [db executeQuery:@"select image from sqlmaster where name=?",@"Roundicons-19"];
    if ([s next]) {
        NSData *data = [s dataForColumnIndex:0];
        UIImage * img = [UIImage imageWithData:data];
        self.readImageView.image = img;
    }
    [db close];
}

- (IBAction)readPic2:(UIButton *)sender {
    FMDatabase *db = [FMDatabase databaseWithPath:self.dbpath];
    if (![db open]) {
        NSLog(@"db open error:%@",[db lastErrorMessage]);
        return;
    }
    [db setKey:@"secretKey"];
    FMResultSet *s = [db executeQuery:@"select image from sqlmaster where name=?",@"Roundicons-20"];
    if ([s next]) {
        NSData *data = [s dataForColumnIndex:0];
        UIImage * img = [UIImage imageWithData:data];
        self.readImageView.image = img;
    }
    [db close];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

typedef enum {
    DialogResultNone,
    DialogResultDone,
    DialogResultCancel
} DialogResult;

@interface FileDialogController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, retain) NSURL *location;
@property (nonatomic, retain) NSArray <NSString *> *filter;
@property (nonatomic) BOOL showHiddenFiles;
@property (nonatomic) BOOL darkColors;
@property (nonatomic) int defaultFilterIndex;
-(void)showDialog:(void (^)(DialogResult, NSURL *))completion;
-(void)loadFiles;
-(void)finish;
@end

@interface File : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSURL *path;
@property (nonatomic, retain) NSFileAttributeType type;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSDate *lastModified;
@property (nonatomic) BOOL hidden;
@property (nonatomic) BOOL isDir;
@end
#import "libfiledialog.h"

#define defaultManager NSFileManager.defaultManager

@implementation FileDialogController
{
    NSURL *selectedPath;
    void (^completionHandler)(DialogResult, NSURL *);

    UILabel *barLabel;
    UITableView *fileListView;
    UITextField *nameField;
    UIPickerView *filterPicker;
    UIView *container;

    NSArray <File *> *currentFiles;
    UIColor *darkGray, *lightGray;
    DialogResult result;
    CGSize screen;
}

-(instancetype)init
{
    if ((self = [super init]))
    {
        selectedPath = nil;
        self.location = [NSURL fileURLWithPath:@"/"];
        self.filter = @[ @"All files (*.*)|*.*", @"Text files (*.txt)|*.txt" ];
        self.showHiddenFiles = NO;
        self.darkColors = NO;
        self.defaultFilterIndex = 0;
    }

    return self;
}

-(void)loadView
{
    [super loadView];
    screen = UIScreen.mainScreen.bounds.size;
    result = DialogResultNone;

    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(receivedNotification:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(receivedNotification:) name:UIKeyboardWillHideNotification object:nil];

    darkGray = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1];
    lightGray = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1];

    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.width, screen.height)];
    self.view.backgroundColor = UIColor.whiteColor;

    UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.width, 70)];
    navBar.backgroundColor = self.darkColors ? UIColor.blackColor : UIColor.whiteColor;
    [self.view addSubview:navBar];

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    backButton.tag = 1;
    backButton.frame = CGRectMake(10, 30, 60, 30);
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [backButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:backButton];

    barLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, screen.width - 100, 50)];
    barLabel.font = [UIFont systemFontOfSize:20];   
    barLabel.text = [self.location lastPathComponent];
    barLabel.textColor = self.darkColors ? UIColor.whiteColor : UIColor.blackColor;
    barLabel.textAlignment = NSTextAlignmentCenter;
    [navBar addSubview:barLabel];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.tag = 2;
    cancelButton.frame = CGRectMake(screen.width - 80, 30, 60, 30);
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:cancelButton];

    fileListView = [[UITableView alloc] initWithFrame:CGRectMake(0, 70, screen.width, screen.height - 270)];
    fileListView.delegate = self;
    fileListView.dataSource = self;
    fileListView.backgroundColor = self.darkColors ? darkGray : lightGray;
    [self.view addSubview:fileListView];

    container = [[UIView alloc] initWithFrame:CGRectMake(0, screen.height - 200, screen.width, 200)];
    container.backgroundColor = self.darkColors ? UIColor.blackColor : UIColor.whiteColor;
    [self.view addSubview:container];

    nameField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, screen.width - 20, 40)];
    nameField.placeholder = @"File name";
    nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    nameField.borderStyle = UITextBorderStyleRoundedRect;
    nameField.returnKeyType = UIReturnKeySearch;
    nameField.clearButtonMode = UITextFieldViewModeAlways;
    nameField.layer.cornerRadius = 5;
    nameField.layer.masksToBounds = YES;
    [container addSubview:nameField];

    filterPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 50, screen.width - 20, 100)];
    filterPicker.backgroundColor = self.darkColors ? UIColor.blackColor : UIColor.whiteColor;
    filterPicker.dataSource = self;
    filterPicker.delegate = self;
    [container addSubview:filterPicker];
    [filterPicker selectRow:self.defaultFilterIndex inComponent:0 animated:NO];

    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    doneButton.backgroundColor = self.darkColors ? UIColor.blackColor : UIColor.whiteColor;
    doneButton.tag = 3;
    doneButton.frame = CGRectMake(10, 150, screen.width - 20, 40);
    doneButton.layer.borderColor = [UIColor colorWithRed:0.16f green:0.5f blue:1 alpha:1].CGColor;
    doneButton.layer.borderWidth = 1;
    doneButton.layer.cornerRadius = 5;
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    doneButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [doneButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:doneButton];

    [self loadFiles];
}

-(void)receivedNotification:(NSNotification *)sender
{
    int keyboardHeight = [sender.userInfo[UIKeyboardFrameBeginUserInfoKey] frame].size.height;

    if ([sender.name isEqual:UIKeyboardWillHideNotification])
    {
        fileListView.frame = CGRectMake(0, 70, screen.width, screen.height - 270);
        container.frame = CGRectMake(0, screen.height - 200, screen.width, 200);
    }
    else
    {
        fileListView.frame = CGRectMake(0, 70, screen.width, screen.height - 270 - keyboardHeight);
        container.frame = CGRectMake(0, screen.height - 200 - keyboardHeight, screen.width, 200);
    }
}

-(void)loadFiles
{
    [fileListView setContentOffset:CGPointZero animated:NO];

    NSMutableArray *files = [NSMutableArray array];
    NSError *error;
    NSArray *fileList = [defaultManager contentsOfDirectoryAtPath:self.location.path error:&error];

    if (error)
    {
        currentFiles = [NSArray array];
        return;
    }

    NSDictionary *fileInfo;
    NSString *path;
    File *file;
    BOOL dir;

    for (NSString *_file in fileList)
    {
        BOOL hidden = [_file hasPrefix:@"."];
        if (hidden && !self.showHiddenFiles)
            continue;

        file = [[File alloc] init];
        path = [self.location.path stringByAppendingPathComponent:_file];
        NSError *infoError;
        fileInfo = [defaultManager attributesOfItemAtPath:path error:&error];

        if (infoError)
            continue;

        file.name = _file;
        file.path = [NSURL fileURLWithPath:path];
        file.type = fileInfo[NSFileType];
        file.size = fileInfo[NSFileSize];
        file.lastModified = fileInfo[NSFileModificationDate];
        file.hidden = hidden;
        file.isDir = ([defaultManager fileExistsAtPath:path isDirectory:&dir] && dir);

        NSArray *extension = [[self.filter[self.defaultFilterIndex] componentsSeparatedByString:@"|"].lastObject componentsSeparatedByString:@"."];
        if (![extension[0] isEqual:@"*"] && ![extension[0] isEqual:_file.stringByDeletingPathExtension] && !file.isDir)
            continue;

        if (![extension[1] isEqual:@"*"] && ![extension[1] isEqual:_file.pathExtension] && !file.isDir)
            continue;

        [files addObject:file];
    }

    currentFiles = files.copy;
    barLabel.text = [self.location lastPathComponent];
    [fileListView reloadData];
}

-(void)buttonPressed:(UIControl *)sender
{
    switch (sender.tag)
    {
        case 1:
            nameField.text = nil;
            self.location = [self.location URLByDeletingLastPathComponent];
            [self loadFiles];
            break;

        case 2:
            selectedPath = nil;
            result = DialogResultCancel;
            [self finish];
            break;

        case 3:
            selectedPath = [self.location URLByAppendingPathComponent:nameField.text];
            result = DialogResultDone;
            [self finish];
            break;
    }
}

-(void)finish
{
    result = result ?: DialogResultNone;
    [self dismissViewControllerAnimated:YES completion:nil];
    completionHandler(result, selectedPath);
}

-(void)showDialog:(void (^)(DialogResult, NSURL *))completion
{
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:self animated:YES completion:nil];
    completionHandler = completion;
}

#pragma mark - Picker View Data Source

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.defaultFilterIndex = row;
    [self loadFiles];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{ 
    return self.filter.count;
}

-(NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [self.filter[row] substringToIndex:[self.filter[row] rangeOfString:@"|" options:NSBackwardsSearch].location];
    return [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:self.darkColors ? UIColor.whiteColor : UIColor.blackColor}];
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return currentFiles.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    
    if (!currentFiles || currentFiles.count == 0)
        return cell;

    File *file = currentFiles[indexPath.row];
    if (!file)
        return cell;

    cell.textLabel.text = file.name;
    cell.textLabel.textColor = [file.type isEqual:NSFileTypeSymbolicLink] ? [UIColor colorWithRed:0.16f green:0.5f blue:1 alpha:1] : (self.darkColors ? UIColor.whiteColor : UIColor.blackColor);
    
    cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:file.lastModified dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle] ?: @"modified unknown";
    cell.detailTextLabel.textColor = self.darkColors ? UIColor.whiteColor : UIColor.blackColor;

    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Application Support/libfiledialog/%@.png", file.isDir ? @"directory" : @"file"]];
    cell.contentView.backgroundColor = self.darkColors ? UIColor.blackColor : UIColor.whiteColor;

    cell.textLabel.alpha = file.hidden ? 0.5f : 1;
    cell.detailTextLabel.alpha = file.hidden ? 0.5f : 1;
    cell.imageView.alpha = file.hidden ? 0.5f : 1;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentFiles[indexPath.row].isDir)
    {
        nameField.text = nil;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.location = currentFiles[indexPath.row].path;
        [self loadFiles];
        return;
    }

    nameField.text = currentFiles[indexPath.row].name;
}
@end

@implementation File
@end
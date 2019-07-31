#import "libfiledialog.h"

@interface SBPowerDownController : UIViewController
@end

%hook SBPowerDownController
-(void)orderFront
{
    // initialize our dialog
    FileDialogController *dialog = [[FileDialogController alloc] init];

    // this means the dialog will start off in this directory. if blank, will be root by default.
    dialog.location = [NSURL fileURLWithPath:@"/var/mobile"];

    // see readme.md for information on how to use filter
    dialog.filter = @[ @"Text files (*.txt)|*.txt", @"Image files (*.png)|*.png", @"All files (*.*)|*.*" ];

    // showHiddenFiles defualts to NO
    dialog.showHiddenFiles = NO;

    // dark theme, defaults to NO
    dialog.darkColors = YES;

    // see readme.md for info about defaultFilterIndex
    dialog.defaultFilterIndex = 1;

    // show the dialog and pass a completion handler
    [dialog showDialog:^(DialogResult result, NSURL *selectedPath)
    {
        // DialogResult will be which button the user pressed, DialogResultDone or DialogResultCancel. if the result is DialogResultNone, then an error occured.
        // DialogResult is an enum defined in libfiledialog.h

        if (result == DialogResultDone)
        {
            // the selected path is in form of an NSURL, so we log it in string form
            NSLog(@"Finished with path: %@", selectedPath.path);
        }
        else if (result == DialogResultCancel)
        {
            // if the dialog result is not DialogResultDone, selectedPath will return nil.
            NSLog(@"The user pressed the cancel button, the operation was cancelled.");
        }
        else
        {
            NSLog(@"An error occurred, the operation was cancelled.");
        }
    }];
}
%end
# libfiledialog

Library for showing dialogs to chose files, based off of the OpenFileDialog from Windows.

# How to add to your project

Download `libfiledialog.h` from this project and place it in your project directory.

In your Makefile, simply add it to your libraries. Here is a sample Makefile:

```makefile
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SomeTweak
SomeTweak_FILES = Tweak.xm
SomeTweak_LIBRARIES = filedialog

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
    install.exec "killall -9 SpringBoard"
```
      
After you have done that, in your Tweak.xm or whichever file, add the line `#import "libfiledialog.h"` at the top.

You're done!

# How to use

See `ExampleTweak.xm` for information on how to use.

# Preview

libfiledialog has two themes, light and dark. Here are the previews:

![Light theme](https://raw.githubusercontent.com/qwertyuiop1379/libfiledialog/master/Assets/light.png) ![Dark theme](https://raw.githubusercontent.com/qwertyuiop1379/libfiledialog/master/Assets/dark.png)

# How to use the filter

The filter is based off OpenFileDialog. Each file type should be an item in an array. Let's break down this filter:
`dialog.filter = @[ @"All files (*.*)|*.*", @"Text files (*.txt)|*.txt" ];`
Each file type is a string in an array.

The `|` is the separator between two values. On the left of the separator is the text that will be displayed. In this case, the text "All files (*.*)" will be displayed. On the right side is the actual filter to apply. Since it's just *.*, every file will be shown.

You could do something like `@"This one file|somefile.mm"` and the dialog would only show files named "somefile.mm".

# defaultFilterIndex

This goes along with the filter. Setting this will choose which filter will be selected by default. Using the same example from above, if it were set to 0, it would be "All files", and if set to 1 would be "Text files". Quite simple.

# Need help setting it up?

No problem. Message me on discord: scoob#0049 or reddit /u/qwertyuiop1379

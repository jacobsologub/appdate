A simple class that calls Apple's search API service to get info for an 
Apple "app" ID and check if an App update is available. The Apple Id can be found on your iTunes Connect App's 
Information page.
 
The "version" that's used for comparison against the returned version to check if an application update is availbale  is from
from the main bundle's version, retrieved using the kCFBundleVersionKey.

Usage:
-----

### Using a Delegate

    - (void) foo
    {
        Appdate* appdate = [Appdate appdateWithAppleId: yourAppleAppID];
        appdate.delegate = self;
        [appdate checkNow];
    }
    
    - (void) appdateComplete: (NSDictionary*) appInfo updateAvailable: (BOOL) updateAvailable
    {
        // Show the user an alert, take them to the app store etc...
    }

    - (void) appdateFailed: (NSError*) error
    {
        
    }
    
### Using Blocks
    
    - (void) foo
    {
        Appdate* appdate = [Appdate appdateWithAppleId: yourAppleAppID];
        [appdate checkNowWithBlock: ^(NSError* error, NSDictionary* appInfo, BOOL updateAvailable) {
            if (!error)
            {
                // Show the user an alert, take them to the app store etc...
            }
        }];
    }

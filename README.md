A simple class that calls Apple's search API service to get info for an 
Apple "app" ID. The Apple Id can be found on your iTunes Connect App's 
Information page.
 
The version that's used for comparison against the returned version is from
the main bundle version retrieved using kCFBundleVersionKey.

Usage:
-----

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

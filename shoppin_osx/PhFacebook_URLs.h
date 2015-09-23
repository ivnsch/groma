//
//  PhFacebook_URLs.h
//  PhFacebook
//
//  URLs used by the Facebook Graph API
//
//  Created by Philippe on 10-08-28.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//


#define kFBAuthorizeURL @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&type=user_agent&display=popup"

#define kFBAuthorizeWithScopeURL @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=popup"

//#define kFBLoginSuccessURL @"https://www.facebook.com/connect/login_success.html"
// Important: when changing protocol to https change the start index in PhWebViewController, webView:didFinishLoadForFrame back to 8 (look for "Changed by Ivan")
#define kFBLoginSuccessURL @"http://localhost:9000"

#define kFBUIServerURL @"http://www.facebook.com/connect/uiserver.php"

#define kFBAccessToken @"access_token="
#define kFBExpiresIn   @"expires_in="
#define kFBErrorReason @"error_description="

#define kFBGraphApiGetURL @"https://graph.facebook.com/%@?access_token=%@"
#define kFBGraphApiGetURLWithParams @"https://graph.facebook.com/%@&access_token=%@"

#define kFBGraphApiPostURL @"https://graph.facebook.com/%@"

#define kFBGraphApiFqlURL @"https://api.facebook.com/method/fql.query?query=%@&access_token=%@&format=json"

#define kFBURL @"http://facebook.com"
#define kFBSecureURL @"https://facebook.com"

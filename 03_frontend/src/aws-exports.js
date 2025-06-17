const awsExports = {
  Auth: {
    Cognito: {
      userPoolId: process.env.REACT_APP_USER_POOL_ID,
      userPoolClientId: process.env.REACT_APP_USER_POOL_WEB_CLIENT_ID,
      region: process.env.REACT_APP_REGION,
      loginWith: {
        oauth: {
          domain: process.env.REACT_APP_AUTH_DOMAIN,
          scopes: ['openid', 'email', 'profile'],
          redirectSignIn: [process.env.REACT_APP_REDIRECT_SIGN_IN],
          redirectSignOut: [process.env.REACT_APP_REDIRECT_SIGN_OUT],
          responseType: process.env.REACT_APP_RESPONSE_TYPE || 'code'
        }
      }
    }
  }
};

export default awsExports;
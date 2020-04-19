#!/bin/sh
# Exit if any of the intermediate steps fail
set -e;

# To make our script work independently of where we invoke it from.
cd "$(dirname "$0")";

# Extract "foo" and "baz" arguments from the input into
# FOO and BAZ shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "REGION=\(.region) USERNAME=\(.username) PASSWORD=\(.password) USER_POOL_ID=\(.user_pool_id) CLIENT_ID=\(.client_id) IDENTITY_POOL_ID=\(.identity_pool_id) SESSION_DURATION=\(.session_duration)"')";

# We first retreive a JWT token from cognito user pool
JWT_ID_TOKEN=$(curl -s -X POST \
  -H 'Content-Type: application/x-amz-json-1.1' \
  -H 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
  --data '{"AuthParameters" : { "USERNAME" : "'${USERNAME}'", "PASSWORD" : "'${PASSWORD}'" }, "AuthFlow" : "USER_PASSWORD_AUTH", "ClientId" : "'${CLIENT_ID}'" }' \
  https://cognito-idp.eu-west-1.amazonaws.com/ | jq -r .AuthenticationResult.IdToken);
# echo "JWT_ID_TOKEN:" >> get_url.logs;
# echo $JWT_ID_TOKEN >> get_url.logs;
# echo "" > get_url.logs;

# We then get our account login id 
IDENTITY_ID=$(curl -s -X POST \
  -H 'Content-Type: application/x-amz-json-1.1' \
  -H 'X-Amz-Target: AWSCognitoIdentityService.GetId' \
  --data '{"IdentityPoolId" : "'${IDENTITY_POOL_ID}'", "Logins": {"cognito-idp.'${REGION}'.amazonaws.com/'${USER_POOL_ID}'": "'${JWT_ID_TOKEN}'"} }' \
  https://cognito-identity.eu-west-1.amazonaws.com/ | jq -r .IdentityId);
# echo "IDENTITY_ID:" >> get_url.logs;
# echo $IDENTITY_ID >> get_url.logs;
# echo "" >> get_url.logs;

# We retreive credentials from cognito
CREDS=$(curl -s -X POST \
  -H 'Content-Type:application/x-amz-json-1.1' \
  -H 'X-Amz-Target:AWSCognitoIdentityService.GetCredentialsForIdentity' \
  --data '{"IdentityId": "'${IDENTITY_ID}'", "Logins": {"cognito-idp.'${REGION}'.amazonaws.com/'${USER_POOL_ID}'": "'${JWT_ID_TOKEN}'"}}' \
  https://cognito-identity.${REGION}.amazonaws.com/);
# echo "CREDS:" >> get_url.logs;
# echo $CREDS >> get_url.logs;
# echo "" >> get_url.logs;

# We export session information
AWS_ACCESS_KEY_ID=`echo $CREDS| jq -r .Credentials.AccessKeyId`;
AWS_SECRET_ACCESS_KEY=`echo $CREDS| jq -r .Credentials.SecretKey`;
AWS_SESSION_TOKEN=`echo $CREDS| jq -r .Credentials.SessionToken`;

STRING_TO_BE_URL_ENCODED="{\"sessionId\":\"$AWS_ACCESS_KEY_ID\",\"sessionKey\":\"$AWS_SECRET_ACCESS_KEY\",\"sessionToken\":\"$AWS_SESSION_TOKEN\"}";
# echo "STRING_TO_BE_URL_ENCODED:" >> get_url.logs;
# echo $STRING_TO_BE_URL_ENCODED >> get_url.logs;
# echo "" >> get_url.logs;

URL_ENCODED_STRING=$(python urlencode.py -s $STRING_TO_BE_URL_ENCODED);
# echo "URL_ENCODED_STRING:" >> get_url.logs;
# echo $URL_ENCODED_STRING >> get_url.logs;
# echo "" >> get_url.logs;

# Building URL to retrieve the SigninToken
GET_SIGNIN_TOKEN_URL="https://signin.aws.amazon.com/federation?Action=getSigninToken&SessionDuration=$SESSION_DURATION&Session=$URL_ENCODED_STRING"
# echo "GET_SIGNIN_TOKEN_URL:" >> get_url.logs;
# echo $GET_SIGNIN_TOKEN_URL >> get_url.logs;
# echo "" >> get_url.logs;

# Get the SigninToken
GET_SIGNIN_TOKEN_ANSWER=$(curl ${GET_SIGNIN_TOKEN_URL})
# echo "GET_SIGNIN_TOKEN_ANSWER:" >> get_url.logs;
# echo $GET_SIGNIN_TOKEN_ANSWER >> get_url.logs;
# echo "" >> get_url.logs;


SIGNIN_TOKEN=`echo $GET_SIGNIN_TOKEN_ANSWER| jq -r .SigninToken`;

jq -n --arg signin_token "$SIGNIN_TOKEN" '{"signin_token":$signin_token}'
#!/bin/sh
# Exit if any of the intermediate steps fail
set -e;

# To make our script work independently of where we invoke it from.
cd "$(dirname "$0")";

# Extract "foo" and "baz" arguments from the input into
# FOO and BAZ shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "REGION=\(.region) USERNAME=\(.username) PASSWORD=\(.password) USER_POOL_ID=\(.user_pool_id) CLIENT_ID=\(.client_id) IDENTITY_POOL_ID=\(.identity_pool_id) SESSION_DURATION=\(.session_duration) INSTANCE_ID=\(.instance_id)"')";

# We first retreive a JWT token from cognito user pool
JWT_ID_TOKEN=$(curl -s -X POST \
  -H 'Content-Type: application/x-amz-json-1.1' \
  -H 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
  --data '{"AuthParameters" : { "USERNAME" : "'${USERNAME}'", "PASSWORD" : "'${PASSWORD}'" }, "AuthFlow" : "USER_PASSWORD_AUTH", "ClientId" : "'${CLIENT_ID}'" }' \
  https://cognito-idp.eu-west-1.amazonaws.com/ | jq -r .AuthenticationResult.IdToken);

# We then get our account login id 
IDENTITY_ID=$(curl -s -X POST \
  -H 'Content-Type: application/x-amz-json-1.1' \
  -H 'X-Amz-Target: AWSCognitoIdentityService.GetId' \
  --data '{"IdentityPoolId" : "'${IDENTITY_POOL_ID}'", "Logins": {"cognito-idp.'${REGION}'.amazonaws.com/'${USER_POOL_ID}'": "'${JWT_ID_TOKEN}'"} }' \
  https://cognito-identity.eu-west-1.amazonaws.com/ | jq -r .IdentityId);

# We retreive credentials from cognito
CREDS=$(curl -s -X POST \
  -H 'Content-Type:application/x-amz-json-1.1' \
  -H 'X-Amz-Target:AWSCognitoIdentityService.GetCredentialsForIdentity' \
  --data '{"IdentityId": "'${IDENTITY_ID}'", "Logins": {"cognito-idp.'${REGION}'.amazonaws.com/'${USER_POOL_ID}'": "'${JWT_ID_TOKEN}'"}}' \
  https://cognito-identity.${REGION}.amazonaws.com/);

# We export session information
AWS_ACCESS_KEY_ID=`echo $CREDS| jq -r .Credentials.AccessKeyId`;
AWS_SECRET_ACCESS_KEY=`echo $CREDS| jq -r .Credentials.SecretKey`;
AWS_SESSION_TOKEN=`echo $CREDS| jq -r .Credentials.SessionToken`;

STRING_TO_BE_URL_ENCODED="{\"sessionId\":\"$AWS_ACCESS_KEY_ID\",\"sessionKey\":\"$AWS_SECRET_ACCESS_KEY\",\"sessionToken\":\"$AWS_SESSION_TOKEN\"}";

URL_ENCODED_STRING=$(python urlencode.py -s $STRING_TO_BE_URL_ENCODED);

# Building URL to retrieve the SigninToken
GET_SIGNIN_TOKEN_URL="https://signin.aws.amazon.com/federation?Action=getSigninToken&SessionDuration=$SESSION_DURATION&Session=$URL_ENCODED_STRING"

# Get the SigninToken
GET_SIGNIN_TOKEN_ANSWER=$(curl ${GET_SIGNIN_TOKEN_URL})


SIGNIN_TOKEN=`echo $GET_SIGNIN_TOKEN_ANSWER| jq -r .SigninToken`;

# Building the final AWS Management Console url
AWS_SESSION_MANAGER_CONSOLE_URL="https://signin.aws.amazon.com/federation?Action=login&Destination=https://$REGION.console.aws.amazon.com/systems-manager/session-manager/$INSTANCE_ID?region=$REGION&SigninToken=$SIGNIN_TOKEN"


jq -n --arg aws_session_manager_console_url "$AWS_SESSION_MANAGER_CONSOLE_URL" '{"aws_session_manager_console_url":$aws_session_manager_console_url}'
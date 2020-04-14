#!/bin/sh
set -e;

# To make our script work independently of where we invoke it from.
cd "$(dirname "$0")";

if aws sts get-caller-identity --region $AWS_REGION_CODE --profile $AWS_CLI_PROFILE > cmd-output.tmp;
  then
    AWS_CLI_PROFILE_OPTION="--profile $AWS_CLI_PROFILE";
  else
    AWS_CLI_PROFILE_OPTION="";
fi

aws cognito-idp admin-create-user --user-pool-id $USER_POOL_ID --username $USER_NAME --user-attributes=Name=email,Value=$USER_EMAIL --temporary-password $USER_PASSWORD --message-action SUPPRESS --region $AWS_REGION_CODE $AWS_CLI_PROFILE_OPTION >> cmd-output.tmp;
aws cognito-idp admin-update-user-attributes --user-pool-id $USER_POOL_ID --username $USER_NAME --user-attributes=Name=email_verified,Value=True --region $AWS_REGION_CODE $AWS_CLI_PROFILE_OPTION >> cmd-output.tmp;
SESSION_TOKEN=$(aws cognito-idp admin-initiate-auth --user-pool-id $USER_POOL_ID --client-id $USER_POOL_CLIENT_ID --auth-flow ADMIN_NO_SRP_AUTH --auth-parameters USERNAME=$USER_NAME,PASSWORD=$USER_PASSWORD --region $AWS_REGION_CODE $AWS_CLI_PROFILE_OPTION | jq -r .Session);
aws cognito-idp admin-respond-to-auth-challenge --user-pool-id $USER_POOL_ID --client-id $USER_POOL_CLIENT_ID --challenge-name NEW_PASSWORD_REQUIRED --challenge-responses NEW_PASSWORD=$USER_PASSWORD,USERNAME=$USER_NAME --session $SESSION_TOKEN --region $AWS_REGION_CODE $AWS_CLI_PROFILE_OPTION >> cmd-output.tmp;

sleep 10

rm -f cmd-output.tmp;
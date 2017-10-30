#!/bin/bash

## Set Administrator Profiles
#Profile to account being accessed
export PROFILE1=$(grep PROFILE1 setup.conf | cut -d" " -f1 | cut -d"=" -f2)
#Profile of account which hosts identities that assume roles
export PROFILE2=$(grep PROFILE2 setup.conf | cut -d" " -f1 | cut -d"=" -f2)
#Set the Region
export REGION=$(grep REGION setup.conf | cut -d" " -f1 | cut -d"=" -f2)

## Set the Account Numbers
#Account being accessed
export ACCOUNT1=$(grep ACCOUNT1 setup.conf | cut -d" " -f1 | cut -d"=" -f2)
#Account which hosts identities that assume roles
export ACCOUNT2=$(grep ACCOUNT2 setup.conf | cut -d" " -f1 | cut -d"=" -f2)

# Clear Environmental Variables from Role Assumption
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_SESSION_TOKEN=""

# Create unique names for AWS Buckets
BUCKET1=$PROFILE1"-33333-access-logs"
BUCKET2=$PROFILE1"-33333-Secret-Data"

echo "==Empty Buckets"
aws s3 rm s3://$BUCKET1/ --recursive --profile $PROFILE1
aws s3 rm s3://$BUCKET2/ --recursive --profile $PROFILE1

echo "==Delete Buckets"
aws s3 rb s3://$BUCKET1 --profile $PROFILE1
aws s3 rb s3://$BUCKET2 --profile $PROFILE1

echo "==Detach Policies from Roles"
aws iam detach-role-policy --role-name Test-Role-access-log-data \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-log-data --profile $PROFILE1
aws iam detach-role-policy --role-name Test-Role-access-all-data \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-all-data --profile $PROFILE1

echo "==Delete Roles"
aws iam delete-role --role-name Test-Role-access-log-data --profile $PROFILE1
aws iam delete-role --role-name Test-Role-access-all-data --profile $PROFILE1

echo "==Delete Engineering1 Group from Account that is to be accessed"
aws iam remove-user-from-group --group-name Engineering1 --user-name Eng1 --profile $PROFILE1
aws iam detach-group-policy --group-name Engineering1 \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-log-data \
  --profile $PROFILE1
aws iam delete-group --group-name Engineering1 --profile $PROFILE1

echo "==Delete Operations1 Group from Account that is to be accessed"
aws iam remove-user-from-group --group-name Operations1 --user-name Ops1 --profile $PROFILE1
aws iam detach-group-policy --group-name Operations1 \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-all-data \
  --profile $PROFILE1
aws iam delete-group --group-name Operations1 --profile $PROFILE1

echo "==Delete Engineering2 from Account that assumes roles"
aws iam remove-user-from-group --group-name Engineering2 --user-name Eng2 --profile $PROFILE2
aws iam detach-group-policy --group-name Engineering2 \
  --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-log-data \
  --profile $PROFILE2
aws iam delete-group --group-name Engineering2 --profile $PROFILE2

echo "==Delete Operations2 from Account that assumes roles"
aws iam remove-user-from-group --group-name Operations2 --user-name Ops2 --profile $PROFILE2
aws iam detach-group-policy --group-name Operations2 \
  --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-log-data \
  --profile $PROFILE2
  aws iam detach-group-policy --group-name Operations2 \
  --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-all-data \
  --profile $PROFILE2
aws iam delete-group --group-name Operations2 --profile $PROFILE2

echo "==Deleting Policies for the account being accessed"
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-log-data \
  --profile $PROFILE1
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-all-data \
  --profile $PROFILE1

echo "==Deleting Policies for the account that assumes roles"
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-log-data \
  --profile $PROFILE2
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-all-data \
  --profile $PROFILE2

# Delete Users
function del_user {
  aws iam delete-login-profile --user-name $1 --profile $2
  KEYID=$(cat $1.key | cut -f2)
  aws iam delete-access-key --user $1 --access-key $KEYID --profile $2
  aws iam delete-user --user-name $1 --profile $2
}

echo "==Delete Users"
del_user Eng1 $PROFILE1
del_user Ops1 $PROFILE1
del_user Eng2 $PROFILE2
del_user Ops2 $PROFILE2

echo "==Restore Original Configuration files"
cp ~/.aws/config.bak ~/.aws/config
cp ~/.aws/credentials.bak ~/.aws/credentials

echo "==Clean up files"
rm temp/*.json
rm *.key
rm details.txt
rm secrets.txt
rm fake.log

echo "==Teardown complete"

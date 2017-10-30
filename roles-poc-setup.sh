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

# Backup AWS CLI Configuration files
cp ~/.aws/config ~/.aws/config.bak
cp ~/.aws/credentials ~/.aws/credentials.bak

# Create unique names for AWS Buckets
BUCKET1=$PROFILE1"-33333-access-logs"
BUCKET2=$PROFILE1"-33333-Secret-Data"

# Make buckets
printf "\n==Making Buckets\n"
aws s3 mb s3://$BUCKET1 --region $REGION --profile $PROFILE1
aws s3 mb s3://$BUCKET2 --region $REGION --profile $PROFILE1

echo "Here is some fake log data" > fake.log
aws s3 cp fake.log s3://$BUCKET1 --profile $PROFILE1

# Put Fake Secret Data into BUCKET2
echo "Here is some fake secret data" > secrets.txt
aws s3 cp secrets.txt s3://$BUCKET2 --profile $PROFILE1

# Create Policy JSON files
printf "\n==Making JSON Policy Files\n"
# Create policy1.json - allow full access to log buckets, block access  to secrets
cat << EOF > temp/policy1.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
       ],
      "Resource": "arn:aws:s3:::$BUCKET1"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::$BUCKET1/*"
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
       ],
      "Resource": "arn:aws:s3:::$BUCKET2"
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::$BUCKET2/*"
    }
  ]
}
EOF

# Create policy2.json - allow full access to both log & secrets buckets
cat << EOF > temp/policy2.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
       ],
      "Resource": "arn:aws:s3:::$BUCKET1"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::$BUCKET1/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
       ],
      "Resource": "arn:aws:s3:::$BUCKET2"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::$BUCKET2/*"
    }
  ]
}
EOF

# Create Trust Policy JSON for Role Assumption
cat << EOF > temp/trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": { "AWS": "arn:aws:iam::$ACCOUNT2:root" },
    "Action": "sts:AssumeRole"
  }
}
EOF

# Create policy3.json - Assume Role to allow full access to log buckets, block access  to secrets
cat << EOF > temp/policy3.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::$ACCOUNT1:role/Test-Role-access-log-data"
  }
}
EOF

# Create policy4.json - Assume Role to allow full access to both log & secrets buckets
cat << EOF > temp/policy4.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::$ACCOUNT1:role/Test-Role-access-all-data"
  }
}
EOF

# Create policies for the account being accessed
printf "\n==Creating Policies for the account being accessed\n"
aws iam create-policy --policy-name "access-log-data" --policy-document file://temp/policy1.json --profile $PROFILE1
aws iam create-policy --policy-name "access-all-data" --policy-document file://temp/policy2.json --profile $PROFILE1

# Create policies for the account that assumes roles
printf "\n==Creating Policies for the account that assumes roles\n"
aws iam create-policy --policy-name "assume-role-to-access-log-data" --policy-document file://temp/policy3.json --profile $PROFILE2
aws iam create-policy --policy-name "assume-role-to-access-all-data" --policy-document file://temp/policy4.json --profile $PROFILE2

# Create roles and attach policies for the account being accessed
printf "\n==Creating roles and attaching policies for the account being accessed\n"
aws iam create-role --role-name Test-Role-access-log-data \
  --assume-role-policy-document file://temp/trust-policy.json --profile $PROFILE1
aws iam attach-role-policy --role-name Test-Role-access-log-data \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-log-data --profile $PROFILE1
aws iam create-role --role-name Test-Role-access-all-data \
  --assume-role-policy-document file://temp/trust-policy.json --profile $PROFILE1
aws iam attach-role-policy --role-name Test-Role-access-all-data \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-all-data --profile $PROFILE1

# Define Functions
function update_configuration {
  KEYID=$(cat $1.key | cut -f2)
  KEY=$(cat $1.key | cut -f4)
  printf "[profile $1]\noutput = text\nregion = us-east-1\n" >> ~/.aws/config
  printf "[$1]\naws_access_key_id = $KEYID\naws_secret_access_key = $KEY\n" >> ~/.aws/credentials
}
function create_user {
aws iam create-user --user-name $1 --profile $2
aws iam create-login-profile --user-name $1 --password "$1-123456**" --no-password-reset-required \
 --profile $2
aws iam create-access-key --user $1 --profile $2 > $1.key
update_configuration $1
}
function test_access {
  echo "$1:"
  echo "aws s3 ls s3://$BUCKET1 --profile $1"
  aws s3 ls s3://$BUCKET1 --profile $1
  echo "aws s3 ls s3://$BUCKET2 --profile $1"
  aws s3 ls s3://$BUCKET2 --profile $1
  echo
}

printf "\n==Creating Users\n"
create_user Eng1 $PROFILE1
create_user Ops1 $PROFILE1
create_user Eng2 $PROFILE2
create_user Ops2 $PROFILE2

# Create Engineering1 Group & add User in Account that is to be accessed
printf "\n==Create Engineering1 Group & add User Eng1\n"
aws iam create-group --group-name Engineering1 --profile $PROFILE1
aws iam add-user-to-group --group-name Engineering1 --user-name Eng1 --profile $PROFILE1
aws iam attach-group-policy --group-name Engineering1 \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-log-data \
  --profile $PROFILE1

# Create Operations1 Group & add User in Account that is to be accessed
printf "\n==Create Operations1 Group & add User Ops1\n"
aws iam create-group --group-name Operations1 --profile $PROFILE1
aws iam add-user-to-group --group-name Operations1 --user-name Ops1  --profile $PROFILE1
aws iam attach-group-policy --group-name Operations1 \
  --policy-arn arn:aws:iam::$ACCOUNT1:policy/access-all-data \
  --profile $PROFILE1

# Create Engineering2 Group & add User in Account assumes roles
printf "\n==Create Engineering2 Group & add User Eng2\n"
aws iam create-group --group-name Engineering2 --profile $PROFILE2
aws iam add-user-to-group --group-name Engineering2 --user-name Eng2 --profile $PROFILE2
aws iam attach-group-policy --group-name Engineering2 \
    --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-log-data \
    --profile $PROFILE2

  # Create Operations2 Group & add User in Account that is to be accessed
printf "\n==Create Operations2 Group & add User Ops2\n"
aws iam create-group --group-name Operations2 --profile $PROFILE2
aws iam add-user-to-group --group-name Operations2 --user-name Ops2  --profile $PROFILE2
aws iam attach-group-policy --group-name Operations2 \
    --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-all-data \
    --profile $PROFILE2
aws iam attach-group-policy --group-name Operations2 \
    --policy-arn arn:aws:iam::$ACCOUNT2:policy/assume-role-to-access-log-data \
    --profile $PROFILE2

# Modify AWS CLI Config for New Roles
cat << EOF >> ~/.aws/config
[profile Eng2-log-access]
role_arn = arn:aws:iam::$ACCOUNT1:role/Test-Role-access-log-data
source_profile = Eng2
[profile Ops2-log-access]
role_arn = arn:aws:iam::$ACCOUNT1:role/Test-Role-access-log-data
source_profile = Ops2
[profile Ops2-all-access]
role_arn = arn:aws:iam::$ACCOUNT1:role/Test-Role-access-all-data
source_profile = Ops2
EOF

# Test User Access to S3 based on Profiles
# format is: test_access profile
sleep 30
printf "\n==Testing User Access\n"
test_access Eng1
test_access Ops1
test_access Eng2-log-access
test_access Ops2-log-access
test_access Ops2-all-access

# Display Access Information
printf "\n\n\nRoles POC Setup Complete\n\n" > details.txt
echo "Login Information for Account Being Accessed:" >> details.txt
echo "https://$ACCOUNT1.signin.aws.amazon.com/console" >> details.txt
echo "Account: "$ACCOUNT1 >> details.txt
echo "User Name: Eng1    Password:  Eng1-123456**" >> details.txt
echo "User Name: Ops1    Password:  Ops1-123456**" >> details.txt
echo "==========================================================" >> details.txt
echo >> details.txt
echo "Login Information for Account for Switching Roles:" >> details.txt
echo "https://$ACCOUNT2.signin.aws.amazon.com/console" >> details.txt
echo "Account: "$ACCOUNT2 >> details.txt
echo "User Name: Eng2    Password:  Eng2-123456**" >> details.txt
echo "User Name: Ops2    Password:  Ops2-123456**" >> details.txt
echo >> details.txt
echo "Roles:" >> details.txt
echo "https://signin.aws.amazon.com/switchrole?account=$ACCOUNT1&roleName=\
Test-Role-access-log-data&displayName=Test-Role-access-log-data" >> details.txt
echo "https://signin.aws.amazon.com/switchrole?account=$ACCOUNT1&roleName=\
Test-Role-access-all-data&displayName=Test-Role-access-all-data" >> details.txt
echo >> details.txt
echo "For CLI Access using a role, reference one of the following profiles:" >> details.txt
echo "   --profile Eng2-log-access" >> details.txt
echo "   --profile Ops2-log-access" >> details.txt
echo "   --profile Ops2-all-access" >> details.txt
echo >> details.txt
echo "For example:" >> details.txt
echo "aws s3 ls s3://$BUCKET1 --profile Eng2-log-access" >> details.txt
echo "aws s3 ls s3://$BUCKET1 --profile Ops2-log-access" >> details.txt
echo "aws s3 ls s3://$BUCKET1 --profile Ops2-all-access" >> details.txt
echo >> details.txt

cat details.txt

# Roles Assumption Proof of Concept
A demonstration of assuming roles in other AWS Accounts.  Set Up via the Command Line Interface

## Instructions
To use the demonstration environment in AWS, enter the following command:
```
./roles-poc-setup.sh # Set up the environment
```

To use it you must [configure your AWS Profile Parameters](../master/doc/configuration.md)
in **setup.conf**.

`./roles-poc-teardown.sh` will delete all S3 Buckers, custom roles and policies, and
other objects created during setup.

## Description
An AWS Account is at the organizational level, but it is quite common for an organization
to have multiple accounts for different purposes (such as development or production) and
different teams.  Accounts for individual users and other subject identities are managed
through an identity management service, called AWS Identity and Access Management (IAM).  
The IAM service allows for very granular role-based access control (RBAC).  AWS supports
the ability of a user with an IAM credential in one account to assume a "role" in another
AWS account by mapping a trust relationship.  This POC demonstrates that functionality.

There are two accounts used for this POC.  There are two user accounts set up in each
account. An "Eng" account can only access the logs bucket, but the "Ops" account can
access both the logs and the bucket with secret data.

An engineer logging in as Eng2 into ACCOUNT2 can assume a role (Eng2-log-access) in
ACCOUNT1 and have the same access as Eng1 who has a user account in ACCOUNT1.  The
Ops2 user can assume two different roles in ACCOUNT1.  One role "Ops2-log-access"
gives only access to the logs. The other role (Ops2-all-access) gives access to both
buckets.

This POC demonstrates how roles can be assumed from both the console and the command line.

## Script Output
The Script will output something similar to the following, depending on the setup.conf:

```
Roles POC Setup Complete

Login Information for Account Being Accessed:
https://999999999999.signin.aws.amazon.com/console
Account: 99999999999
User Name: Eng1    Password:  Eng1-123456**
User Name: Ops1    Password:  Ops1-123456**
==========================================================

Login Information for Account for Switching Roles:
https://88888888888.signin.aws.amazon.com/console
Account: 88888888888
User Name: Eng2    Password:  Eng2-123456**
User Name: Ops2    Password:  Ops2-123456**

Roles:
https://signin.aws.amazon.com/switchrole?account=99999999999&roleName=Test-Role-access-log-data&displayName=Test-Role-access-log-data
https://signin.aws.amazon.com/switchrole?account=99999999999&roleName=Test-Role-access-all-data&displayName=Test-Role-access-all-data

For CLI Access using a role, reference one of the following profiles:
   --profile Eng2-log-access
   --profile Ops2-log-access
   --profile Ops2-all-access

For example:
aws s3 ls s3://AAAAAAAAAAA-33333-access-logs --profile Eng2-log-access
aws s3 ls s3://AAAAAAAAAAA-33333-access-logs --profile Ops2-log-access
aws s3 ls s3://AAAAAAAAAAA-33333-access-logs --profile Ops2-all-access
```

## References
https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
https://aws.amazon.com/answers/account-management/aws-multi-account-security-strategy/

# Configure your AWS Profile Parameters

First, make a copy of **setup.example.conf** as **setup.conf** as follows:
```
$ cp setup.example.conf setup.conf
```

Next, edit **setup.conf** by replacing the characters to the right of the equal sign as appropriate for your environment.

```
# Set Administrator Profiles
PROFILE1=AAAAAAAAAAAAA                     #Profile to account being accessed
PROFILE2=BBBBBBBBBBBBB                     #Profile of account which hosts identities that assume roles
REGION=us-east-1

# Set the Account Numbers
ACCOUNT1=999999999999                    #Account being accessed
ACCOUNT2=888888888888                    #Account which hosts identities that assume roles
```

NOTE: Do not include quotes or use variables in setup.conf

For additional information see:

http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

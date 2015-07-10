CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")


# Declaring an IAM User Resource
  Resource("myuser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("LoginProfile", {
  "Password" => "myP@ssW0rd"
})
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "sqs:*"
          ],
          "Effect"   => "Allow",
          "Resource" => [
            FnGetAtt("myqueue", "Arn")
          ]
        },
        {
          "Action"      => [
            "sqs:*"
          ],
          "Effect"      => "Deny",
          "NotResource" => [
            FnGetAtt("myqueue", "Arn")
          ]
        }
      ],
      "Version"   => "2012-10-17"
    },
    "PolicyName"     => "giveaccesstoqueueonly"
  },
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "sns:*"
          ],
          "Effect"   => "Allow",
          "Resource" => [
            Ref("mytopic")
          ]
        },
        {
          "Action"      => [
            "sns:*"
          ],
          "Effect"      => "Deny",
          "NotResource" => [
            Ref("mytopic")
          ]
        }
      ],
      "Version"   => "2012-10-17"
    },
    "PolicyName"     => "giveaccesstotopiconly"
  }
])
  end

# Declaring an IAM Access Key Resource
#
# The myaccesskey resource creates an access key and assigns it to an IAM user that is declared as an AWS::IAM::User resource 
# in the template.
  Resource("myaccesskey") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("myuser"))
  end

  Resource("AccessKeyformyaccesskey") do
    Type("")
  end

  Resource("SecretKeyformyaccesskey") do
    Type("")
  end

  Resource("myinstance") do
    Type("AWS::EC2::Instance")
    Property("AvailabilityZone", "us-east-1a")
    Property("ImageId", "ami-20b65349")
    Property("UserData", FnBase64(FnJoin("", [
  "ACCESS_KEY=",
  Ref("myaccesskey"),
  "&",
  "SECRET_KEY=",
  FnGetAtt("myaccesskey", "SecretAccessKey")
])))
  end

# Declaring an IAM Group Resource
  Resource("mygroup") do
    Type("AWS::IAM::Group")
    Property("Path", "/myapplication/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "sqs:*"
          ],
          "Effect"   => "Allow",
          "Resource" => [
            FnGetAtt("myqueue", "Arn")
          ]
        },
        {
          "Action"      => [
            "sqs:*"
          ],
          "Effect"      => "Deny",
          "NotResource" => [
            FnGetAtt("myqueue", "Arn")
          ]
        }
      ],
      "Version"   => "2012-10-17"
    },
    "PolicyName"     => "myapppolicy"
  }
])
  end

# Adding Users to a Group
  Resource("addUserToGroup") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", "myexistinggroup2")
    Property("Users", [
  "existinguser1",
  Ref("myuser")
])
  end

# Declaring an IAM Policy
  Resource("mypolicy") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "mygrouppolicy")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect"   => "Allow",
      "Resource" => "arn:aws:s3:::myAWSBucket/*"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Groups", [
  "myexistinggroup1",
  Ref("mygroup")
])
  end

# Declaring an Amazon S3 Bucket Policy
  Resource("mybucketpolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "MyPolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:GetObject"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("user1", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("mybucket"),
  "/*"
]),
      "Sid"       => "ReadAccess"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Bucket", Ref("mybucket"))
  end

# Declaring an Amazon SNS Topic Policy
  Resource("mysnspolicy") do
    Type("AWS::SNS::TopicPolicy")
    Property("PolicyDocument", {
  "Id"        => "MyTopicPolicy",
  "Statement" => [
    {
      "Action"    => "sns:Publish",
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("myuser", "Arn")
      },
      "Resource"  => "*",
      "Sid"       => "My-statement-id"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Topics", [
  Ref("mytopic")
])
  end

# Declaring an Amazon SQS Policy
  Resource("mysqspolicy") do
    Type("AWS::SQS::QueuePolicy")
    Property("PolicyDocument", {
  "Id"        => "MyQueuePolicy",
  "Statement" => [
    {
      "Action"    => [
        "sqs:SendMessage"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => "arn:aws:iam::123456789012:user/myapp"
      },
      "Resource"  => "*",
      "Sid"       => "Allow-User-SendMessage"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Queues", [
  "https://sqs.us-east-1.amazonaws.com/123456789012/myexistingqueue",
  Ref("myqueue")
])
  end

# Example IAM Role with External Policy and Instance Profiles wired to an EC2 Instance
  Resource("myEC2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", "ami-205fba49")
    Property("InstanceType", "m1.small")
    Property("Monitoring", "true")
    Property("DisableApiTermination", "false")
    Property("IamInstanceProfile", Ref("RootInstanceProfile"))
  end

  Resource("RootRole") do
    Type("AWS::IAM::Role")
    Property("AssumeRolePolicyDocument", {
  "Statement" => [
    {
      "Action"    => [
        "sts:AssumeRole"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "Service" => [
          "ec2.amazonaws.com"
        ]
      }
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Path", "/")
  end

  Resource("RolePolicies") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "root")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => "*",
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Roles", [
  Ref("RootRole")
])
  end

  Resource("RootInstanceProfile") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("RootRole")
])
  end

  Resource("myLCOne") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Property("ImageId", "ami-205fba49")
    Property("InstanceType", "m1.small")
    Property("InstanceMonitoring", "true")
    Property("IamInstanceProfile", Ref("RootInstanceProfile"))
  end

# Example IAM Roles With External Policy And Instance Profiles Wired to an AutoScaling Group
  Resource("myASGrpOne") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", [
  "us-east-1a"
])
    Property("LaunchConfigurationName", Ref("myLCOne"))
    Property("MinSize", "0")
    Property("MaxSize", "0")
    Property("HealthCheckType", "EC2")
    Property("HealthCheckGracePeriod", "120")
  end

  Resource("RootRole2") do
    Type("AWS::IAM::Role")
    Property("AssumeRolePolicyDocument", {
  "Statement" => [
    {
      "Action"    => [
        "sts:AssumeRole"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "Service" => [
          "ec2.amazonaws.com"
        ]
      }
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Path", "/")
  end

  Resource("RolePolicies2") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "root")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => "*",
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ],
  "Version"   => "2012-10-17"
})
    Property("Roles", [
  Ref("RootRole2")
])
  end

  Resource("RootInstanceProfile2") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("RootRole2")
])
  end
end

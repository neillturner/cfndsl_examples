CloudFormation do
  Description("AWS CloudFormation Sample Template S3Bucket_Auth_1: Simple test template showing how to get a file from a private S3 bucket onto an EC2 instance using authenticated GetObject requests. In this template the credentials used to access the bucket are defined and attached in the AWS::CloudFormation::Authentication section. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
    AllowedPattern("[-_ a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("can contain only alphanumeric characters, spaces, dashes and underscores.")
  end

  Parameter("InstanceType") do
    Description("WebServer EC2 instance type")
    Type("String")
    Default("m1.small")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "m3.xlarge",
  "m3.2xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("BucketName") do
    Description("Name of bucket containing index.html")
    Type("String")
  end

  Parameter("SSHLocation") do
    Description(" The IP address range that can be used to SSH to the EC2 instances")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"   => {
    "Arch" => "32"
  },
  "c1.xlarge"   => {
    "Arch" => "64"
  },
  "cc1.4xlarge" => {
    "Arch" => "64"
  },
  "m1.large"    => {
    "Arch" => "64"
  },
  "m1.small"    => {
    "Arch" => "32"
  },
  "m1.xlarge"   => {
    "Arch" => "64"
  },
  "m2.2xlarge"  => {
    "Arch" => "64"
  },
  "m2.4xlarge"  => {
    "Arch" => "64"
  },
  "m2.xlarge"   => {
    "Arch" => "64"
  },
  "m3.2xlarge"  => {
    "Arch" => "64"
  },
  "m3.xlarge"   => {
    "Arch" => "64"
  },
  "t1.micro"    => {
    "Arch" => "32"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32" => "ami-dcfa4edd",
    "64" => "ami-e8fa4ee9"
  },
  "ap-southeast-1" => {
    "32" => "ami-74dda626",
    "64" => "ami-7edda62c"
  },
  "ap-southeast-2" => {
    "32" => "ami-b3990e89",
    "64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "32" => "ami-24506250",
    "64" => "ami-20506254"
  },
  "sa-east-1"      => {
    "32" => "ami-3e3be423",
    "64" => "ami-3c3be421"
  },
  "us-east-1"      => {
    "32" => "ami-7f418316",
    "64" => "ami-7341831a"
  },
  "us-west-1"      => {
    "32" => "ami-951945d0",
    "64" => "ami-971945d2"
  },
  "us-west-2"      => {
    "32" => "ami-16fd7026",
    "64" => "ami-10fd7020"
  }
})

  Resource("CfnUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "cloudformation:DescribeStackResource",
            "s3:GetObject"
          ],
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("CfnKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("CfnUser"))
  end

  Resource("BucketPolicy") do
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
        "AWS" => FnGetAtt("CfnUser", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("BucketName"),
  "/*"
]),
      "Sid"       => "ReadAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("BucketName"))
  end

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/var/www/html/index.html" => {
        "group"  => "apache",
        "mode"   => "000400",
        "owner"  => "apache",
        "source" => FnJoin("", [
  "http://",
  Ref("BucketName"),
  ".s3.amazonaws.com/index.html"
])
      }
    },
    "packages" => {
      "yum" => {
        "httpd" => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
      }
    }
  }
})
    Metadata("AWS::CloudFormation::Authentication", {
  "S3AccessCreds" => {
    "accessKeyId" => Ref("CfnKeys"),
    "buckets"     => [
      Ref("BucketName")
    ],
    "secretKey"   => FnGetAtt("CfnKeys", "SecretAccessKey"),
    "type"        => "S3"
  }
})
    DependsOn("BucketPolicy")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("WebServerSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Install application\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServer ",
  "    --region ",
  Ref("AWS::Region"),
  "\n",
  "# All is well so signal success\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("WaitHandle"),
  "'\n"
])))
  end

  Resource("WaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServer")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "300")
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  },
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Output("WebsiteURL") do
    Description("URL for newly created application")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName")
]))
  end
end

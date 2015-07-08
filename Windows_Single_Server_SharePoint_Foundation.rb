CloudFormation do
  Description("This template creates a single server installation of Microsoft SharePoint Foundation 2010. **WARNING** This template creates Amazon EC2 Windows instance and related resources. You will be billed for the AWS resources used if you create a stack from this template. Also, you are solely responsible for complying with the license terms for the software downloaded and installed by this template. By creating a stack from this template, you are agreeing to such terms.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyPairName") do
    Description("Name of an existing Amazon EC2 key pair for RDP access")
    Type("String")
  end

  Parameter("InstanceType") do
    Description("Amazon EC2 instance type")
    Type("String")
    Default("m1.large")
    AllowedValues([
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "c1.medium",
  "c1.xlarge"
])
  end

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"  => {
    "Arch" => "64"
  },
  "c1.xlarge"  => {
    "Arch" => "64"
  },
  "m1.large"   => {
    "Arch" => "64"
  },
  "m1.medium"  => {
    "Arch" => "64"
  },
  "m1.small"   => {
    "Arch" => "64"
  },
  "m1.xlarge"  => {
    "Arch" => "64"
  },
  "m2.2xlarge" => {
    "Arch" => "64"
  },
  "m2.4xlarge" => {
    "Arch" => "64"
  },
  "m2.xlarge"  => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "64" => "ami-2210a823"
  },
  "ap-southeast-1" => {
    "64" => "ami-b8f8bbea"
  },
  "ap-southeast-2" => {
    "64" => "ami-a740d79d"
  },
  "eu-west-1"      => {
    "64" => "ami-8e969bfa"
  },
  "sa-east-1"      => {
    "64" => "ami-9fc41c82"
  },
  "us-east-1"      => {
    "64" => "ami-5f42c036"
  },
  "us-west-1"      => {
    "64" => "ami-5eb7961b"
  },
  "us-west-2"      => {
    "64" => "ami-1679f126"
  }
})

  Resource("IAMUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => "CloudFormation:DescribeStackResource",
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("IAMUserAccessKey") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("IAMUser"))
  end

  Resource("SharePointFoundationSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP and RDP")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "3389",
    "IpProtocol" => "tcp",
    "ToPort"     => "3389"
  }
])
  end

  Resource("SharePointFoundationEIP") do
    Type("AWS::EC2::EIP")
    Property("InstanceId", Ref("SharePointFoundation"))
  end

  Resource("SharePointFoundation") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "commands" => {
      "1-extract" => {
        "command" => "C:\\SharePoint\\SharePointFoundation2010.exe /extract:C:\\SharePoint\\SPF2010 /quiet /log:C:\\SharePoint\\SharePointFoundation2010-extract.log"
      },
      "2-prereq"  => {
        "command" => "C:\\SharePoint\\SPF2010\\PrerequisiteInstaller.exe /unattended"
      },
      "3-install" => {
        "command" => "C:\\SharePoint\\SPF2010\\setup.exe /config C:\\SharePoint\\SPF2010\\Files\\SetupSilent\\config.xml"
      }
    },
    "files"    => {
      "C:\\SharePoint\\SharePointFoundation2010.exe" => {
        "source" => "http://d3adzpja92utk0.cloudfront.net/SharePointFoundation.exe"
      },
      "c:\\cfn\\cfn-credentials"                     => {
        "content" => FnJoin("", [
  "AWSAccessKeyId=",
  Ref("IAMUserAccessKey"),
  "\n",
  "AWSSecretKey=",
  FnGetAtt("IAMUserAccessKey", "SecretAccessKey"),
  "\n"
])
      },
      "c:\\cfn\\cfn-hup.conf"                        => {
        "content" => FnJoin("", [
  "[main]\n",
  "stack=",
  Ref("AWS::StackName"),
  "\n",
  "credential-file=c:\\cfn\\cfn-credentials\n",
  "region=",
  Ref("AWS::Region"),
  "\n"
])
      },
      "c:\\cfn\\hooks.d\\cfn-auto-reloader.conf"     => {
        "content" => FnJoin("", [
  "[cfn-auto-reloader-hook]\n",
  "triggers=post.update\n",
  "path=Resources.SharePointFoundation.Metadata.AWS::CloudFormation::Init\n",
  "action=cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r SharePointFoundation",
  " --credential-file c:\\cfn\\cfn-credentials",
  " --region ",
  Ref("AWS::Region"),
  "\n"
])
      }
    }
  }
})
    Property("InstanceType", Ref("InstanceType"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("SecurityGroups", [
  Ref("SharePointFoundationSecurityGroup")
])
    Property("KeyName", Ref("KeyPairName"))
    Property("UserData", FnBase64(FnJoin("", [
  "<script>\n",
  "cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r SharePointFoundation",
  " --access-key ",
  Ref("IAMUserAccessKey"),
  " --secret-key ",
  FnGetAtt("IAMUserAccessKey", "SecretAccessKey"),
  " --region ",
  Ref("AWS::Region"),
  "\n",
  "cfn-signal.exe -e %ERRORLEVEL% ",
  FnBase64(Ref("SharePointFoundationWaitHandle")),
  "\n",
  "SCHTASKS /Create /SC MINUTE /MO 10 /TN cfn-hup /RU SYSTEM /TR \"cfn-hup.exe -v --no-daemon\"",
  "\n",
  "</script>"
])))
  end

  Resource("SharePointFoundationWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("SharePointFoundationWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("SharePointFoundation")
    Property("Handle", Ref("SharePointFoundationWaitHandle"))
    Property("Timeout", "3600")
  end

  Output("SharePointFoundationURL") do
    Description("SharePoint Team Site URL. Please retrieve Administrator password of the instance and use it to access the URL")
    Value(FnJoin("", [
  "http://",
  Ref("SharePointFoundationEIP")
]))
  end
end

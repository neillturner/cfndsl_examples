CloudFormation do
  Description("This template creates a single server installation of Active Directory. Domain Administrator password will be the one retrieved from the instance. For adding members to the domain, ensure that they are launched in domain member security group created by this template and then configure them to use this instance's elastic IP as the DNS server. **WARNING** This template creates Amazon EC2 Windows instance and related resources. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("DomainDNSName") do
    Description("Fully qualified domain name (FQDN) of the forest root domain e.g. corp.example.com")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]+\\..+")
    MaxLength(25)
    MinLength(3)
  end

  Parameter("DomainNetBIOSName") do
    Description("NetBIOS name of the domain (upto 15 characters) for users of earlier versions of Windows e.g. CORP")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]+")
    MaxLength(15)
    MinLength(1)
  end

  Parameter("RestoreModePassword") do
    Description("Password for a separate Administrator account when the domain controller is in Restore Mode. Must be at least 8 characters containing letters, numbers and symbols")
    Type("String")
    AllowedPattern("(?=^.{6,255}$)((?=.*\\d)(?=.*[A-Z])(?=.*[a-z])|(?=.*\\d)(?=.*[^A-Za-z0-9])(?=.*[a-z])|(?=.*[^A-Za-z0-9])(?=.*[A-Z])(?=.*[a-z])|(?=.*\\d)(?=.*[A-Z])(?=.*[^A-Za-z0-9]))^.*")
    NoEcho(True)
    MaxLength(32)
    MinLength(8)
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

  Resource("DomainControllerEndpoint") do
    Type("AWS::EC2::EIP")
    Property("InstanceId", Ref("DomainController"))
  end

  Resource("DomainController") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "commands" => {
      "1-run-dcpromo"    => {
        "command"             => FnJoin("", [
  "C:\\cfn\\RunCommand.bat \"dcpromo /unattend  /ReplicaOrNewDomain:Domain  /NewDomain:Forest  /NewDomainDNSName:",
  Ref("DomainDNSName"),
  "  /ForestLevel:4 /DomainNetbiosName:",
  Ref("DomainNetBIOSName"),
  " /DomainLevel:4  /InstallDNS:Yes  /ConfirmGc:Yes  /CreateDNSDelegation:No  /DatabasePath:\"C:\\Windows\\NTDS\"  /LogPath:\"C:\\Windows\\NTDS\"  /SYSVOLPath:\"C:\\Windows\\SYSVOL\" /SafeModeAdminPassword=",
  Ref("RestoreModePassword"),
  " /RebootOnCompletion:Yes\""
]),
        "waitAfterCompletion" => "forever"
      },
      "2-signal-success" => {
        "command" => FnJoin("", [
  "cfn-signal.exe -e 0 \"",
  Ref("DomainControllerWaitHandle"),
  "\""
])
      }
    },
    "files"    => {
      "C:\\cfn\\RunCommand.bat"                  => {
        "content" => "%~1\nIF %ERRORLEVEL% GTR 10 ( exit /b 1 ) else ( exit /b 0 )"
      },
      "c:\\cfn\\cfn-credentials"                 => {
        "content" => FnJoin("", [
  "AWSAccessKeyId=",
  Ref("IAMUserAccessKey"),
  "\n",
  "AWSSecretKey=",
  FnGetAtt("IAMUserAccessKey", "SecretAccessKey"),
  "\n"
])
      },
      "c:\\cfn\\cfn-hup.conf"                    => {
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
      "c:\\cfn\\hooks.d\\cfn-auto-reloader.conf" => {
        "content" => FnJoin("", [
  "[cfn-auto-reloader-hook]\n",
  "triggers=post.update\n",
  "path=Resources.DomainController.Metadata.AWS::CloudFormation::Init\n",
  "action=cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r DomainController",
  " --credential-file c:\\cfn\\cfn-credentials",
  " --region ",
  Ref("AWS::Region"),
  "\n"
])
      }
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("DomainControllerSecurityGroup")
])
    Property("KeyName", Ref("KeyPairName"))
    Property("UserData", FnBase64(FnJoin("", [
  "<script>\n",
  "cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r DomainController ",
  " --access-key ",
  Ref("IAMUserAccessKey"),
  " --secret-key ",
  FnGetAtt("IAMUserAccessKey", "SecretAccessKey"),
  " --region ",
  Ref("AWS::Region"),
  "\n",
  "SCHTASKS /Create /SC MINUTE /MO 10 /TN cfn-hup /RU SYSTEM /TR \"cfn-hup.exe -v --no-daemon\"",
  "\n",
  "</script>"
])))
  end

  Resource("DomainControllerWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("DomainController")
    Property("Handle", Ref("DomainControllerWaitHandle"))
    Property("Timeout", "1200")
  end

  Resource("DomainControllerWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("DomainControllerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Domain Controller")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                => "123",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "123"
  },
  {
    "FromPort"                => "135",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "135"
  },
  {
    "FromPort"                => "138",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "138"
  },
  {
    "FromPort"                => "1024",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "65535"
  },
  {
    "FromPort"                => "389",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "389"
  },
  {
    "FromPort"                => "389",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "389"
  },
  {
    "FromPort"                => "636",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "636"
  },
  {
    "FromPort"                => "3268",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "3268"
  },
  {
    "FromPort"                => "3269",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "3269"
  },
  {
    "FromPort"                => "53",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "53"
  },
  {
    "FromPort"                => "53",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "53"
  },
  {
    "FromPort"                => "88",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "88"
  },
  {
    "FromPort"                => "88",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "88"
  },
  {
    "FromPort"                => "445",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "445"
  },
  {
    "FromPort"                => "445",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "445"
  },
  {
    "FromPort"                => "135",
    "IpProtocol"              => "udp",
    "SourceSecurityGroupName" => Ref("DomainMemberSecurityGroup"),
    "ToPort"                  => "135"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "3389",
    "IpProtocol" => "tcp",
    "ToPort"     => "3389"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "-1",
    "IpProtocol" => "icmp",
    "ToPort"     => "-1"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "53",
    "IpProtocol" => "udp",
    "ToPort"     => "53"
  }
])
  end

  Resource("DomainMemberSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Domain Members")
    Property("SecurityGroupIngress", [])
  end

  Resource("DomainMemberSecurityGroupIngress1") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "tcp")
    Property("FromPort", "49152")
    Property("ToPort", "65535")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress2") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "udp")
    Property("FromPort", "49152")
    Property("ToPort", "65535")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress3") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "tcp")
    Property("FromPort", "53")
    Property("ToPort", "53")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress4") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "udp")
    Property("FromPort", "53")
    Property("ToPort", "53")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress5") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "tcp")
    Property("FromPort", "1024")
    Property("ToPort", "65535")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress6") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "tcp")
    Property("FromPort", "135")
    Property("ToPort", "135")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Resource("DomainMemberSecurityGroupIngress7") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("DomainMemberSecurityGroup"))
    Property("IpProtocol", "udp")
    Property("FromPort", "135")
    Property("ToPort", "135")
    Property("SourceSecurityGroupName", Ref("DomainControllerSecurityGroup"))
  end

  Output("DomainControllerElasticIP") do
    Description("Elastic IP address of Active Directory server which is also a DNS server")
    Value(Ref("DomainControllerEndpoint"))
  end

  Output("DomainAdmin") do
    Description("Default domain administrator account")
    Value(FnJoin("", [
  Ref("DomainNetBIOSName"),
  "\\Administrator"
]))
  end

  Output("DomainAdminPassword") do
    Value("Please retrieve Administrator password of the instance")
  end
end

CloudFormation do
  Description("This template enables roles and features of Windows Server. **WARNING** This template creates Amazon EC2 Windows instance and related resources. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("Roles") do
    Description("A SPACE seperated list of roles that you want to enable on this instance. Valid values are AD-Certificate, AD-Domain-Services, ADLDS, DHCP, DNS, Fax, File-Services, NPAS, Print-Services, Web-Server, and WDS.")
    Type("String")
    Default("None")
    AllowedPattern("(((AD\\-Certificate)|(AD\\-Domain\\-Services)|(ADLDS)|(DHCP)|(DNS)|(Fax)|(File\\-Services)|(NPAS)|(Print\\-Services)|(Web\\-Server)|(WDS))( ((AD\\-Certificate)|(AD\\-Domain\\-Services)|(ADLDS)|(DHCP)|(DNS)|(Fax)|(File\\-Services)|(NPAS)|(Print\\-Services)|(Web\\-Server)|(WDS)))*)|(None)")
  end

  Parameter("Features") do
    Description("A SPACE seperated list of features that you want to enable on this instance. Valid values are NET-Framework, BITS, BitLocker, BranchCache, CMAK, Desktop-Experience, DAMC, Failover-Clustering, GPMC, Ink-Handwriting, Internet-Print-Client, ISNS, LPR-Port-Monitor, MSMQ, Multipath-IO, NLB, PNRP, qWave, Remote-Assistance, RDC, RPC-over-HTTP-Proxy, Simple-TCPIP, SMTP-Server, SNMP-Services, Storage-Mgr-SANS, Subsystem-UNIX-Apps, Telnet-Client, Telnet-Server, TFTP-Client, Biometric-Framework, Windows-Internal-DB, PowerShell-ISE, Backup-Features, Migration, WSRM, TIFF-IFilter, WinRM-IIS-Ext, WINS-Server, Wireless-Networking, and XPS-Viewer.")
    Type("String")
    Default("None")
    AllowedPattern("(((NET\\-Framework)|(BITS)|(BitLocker)|(BranchCache)|(CMAK)|(Desktop\\-Experience)|(DAMC)|(Failover\\-Clustering)|(GPMC)|(Ink\\-Handwriting)|(Internet\\-Print\\-Client)|(ISNS)|(LPR\\-Port\\-Monitor)|(MSMQ)|(Multipath\\-IO)|(NLB)|(PNRP)|(qWave)|(Remote\\-Assistance)|(RDC)|(RPC\\-over\\-HTTP\\-Proxy)|(Simple\\-TCPIP)|(SMTP\\-Server)|(SNMP\\-Services)|(Storage\\-Mgr\\-SANS)|(Subsystem\\-UNIX\\-Apps)|(Telnet\\-Client)|(Telnet\\-Server)|(TFTP\\-Client)|(Biometric\\-Framework)|(Windows\\-Internal\\-DB)|(PowerShell\\-ISE)|(Backup\\-Features)|(Migration)|(WSRM)|(TIFF\\-IFilter)|(WinRM\\-IIS\\-Ext)|(WINS\\-Server)|(Wireless\\-Networking)|(XPS\\-Viewer))( ((NET\\-Framework)|(BITS)|(BitLocker)|(BranchCache)|(CMAK)|(Desktop\\-Experience)|(DAMC)|(Failover\\-Clustering)|(GPMC)|(Ink\\-Handwriting)|(Internet\\-Print\\-Client)|(ISNS)|(LPR\\-Port\\-Monitor)|(MSMQ)|(Multipath\\-IO)|(NLB)|(PNRP)|(qWave)|(Remote\\-Assistance)|(RDC)|(RPC\\-over\\-HTTP\\-Proxy)|(Simple\\-TCPIP)|(SMTP\\-Server)|(SNMP\\-Services)|(Storage\\-Mgr\\-SANS)|(Subsystem\\-UNIX\\-Apps)|(Telnet\\-Client)|(Telnet\\-Server)|(TFTP\\-Client)|(Biometric\\-Framework)|(Windows\\-Internal\\-DB)|(PowerShell\\-ISE)|(Backup\\-Features)|(Migration)|(WSRM)|(TIFF\\-IFilter)|(WinRM\\-IIS\\-Ext)|(WINS\\-Server)|(Wireless\\-Networking)|(XPS\\-Viewer)))*( )*)|(None)")
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

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable RDP")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "3389",
    "IpProtocol" => "tcp",
    "ToPort"     => "3389"
  }
])
  end

  Resource("WindowsServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "commands" => {
      "1-install-roles"    => {
        "command" => FnJoin("", [
  "if not \"None\" EQU \"",
  Ref("Roles"),
  "\" (servermanagercmd -install ",
  Ref("Roles"),
  " -restart)"
])
      },
      "2-install-features" => {
        "command" => FnJoin("", [
  "if not \"None\" EQU \"",
  Ref("Features"),
  "\" (servermanagercmd -install ",
  Ref("Features"),
  " -restart)"
])
      },
      "3-signal-success"   => {
        "command" => FnJoin("", [
  "cfn-signal.exe -e %ERRORLEVEL% \"",
  Ref("WindowsServerWaitHandle"),
  "\""
])
      }
    },
    "files"    => {
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
  "path=Resources.WindowsServer.Metadata.AWS::CloudFormation::Init\n",
  "action=cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r WindowsServer",
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
  Ref("InstanceSecurityGroup")
])
    Property("KeyName", Ref("KeyPairName"))
    Property("UserData", FnBase64(FnJoin("", [
  "<script>\n",
  "cfn-init.exe -v -s ",
  Ref("AWS::StackName"),
  " -r WindowsServer",
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

  Resource("WindowsServerWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WindowsServerWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WindowsServer")
    Property("Handle", Ref("WindowsServerWaitHandle"))
    Property("Timeout", "1800")
  end

  Output("RolesEnabled") do
    Description("Roles enabled on this instance.")
    Value(Ref("Roles"))
  end

  Output("FeaturesEnabled") do
    Description("Features enabled on this instance.")
    Value(Ref("Features"))
  end
end

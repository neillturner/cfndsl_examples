CloudFormation do
  Description("Sample template to bring up WordPress using the Puppet client to install server roles. A WaitCondition is used to hold up the stack creation until the application is deployed. **WARNING** This template creates one or more Amazon EC2 instances and CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
    Type("String")
  end

  Parameter("PuppetClientSecurityGroup") do
    Description("The EC2 security group for the instances")
    Type("String")
  end

  Parameter("PuppetMasterDNSName") do
    Description("The PuppetMaster DNS name")
    Type("String")
  end

  Parameter("InstanceType") do
    Description("WebServer EC2 instance type")
    Type("String")
    Default("m1.small")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "m3.xlarge",
  "m3.2xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge",
  "cc2.8xlarge",
  "cg1.4xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("DatabaseType") do
    Description("The database instance type")
    Type("String")
    Default("db.m1.small")
    AllowedValues([
  "db.m1.small",
  "db.m1.large",
  "db.m1.xlarge",
  "db.m2.xlarge",
  "db.m2.2xlarge",
  "db.m2.4xlarge"
])
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DatabaseUser") do
    Description("Test database admin account name")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DatabasePassword") do
    Description("Test database admin account password")
    Type("String")
    Default("password")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
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
    "Arch" => "64"
  },
  "c1.xlarge"   => {
    "Arch" => "64"
  },
  "cc1.4xlarge" => {
    "Arch" => "64HVM"
  },
  "cc2.8xlarge" => {
    "Arch" => "64HVM"
  },
  "cg1.4xlarge" => {
    "Arch" => "64HVM"
  },
  "m1.large"    => {
    "Arch" => "64"
  },
  "m1.medium"   => {
    "Arch" => "64"
  },
  "m1.small"    => {
    "Arch" => "64"
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
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32"    => "ami-0644f007",
    "64"    => "ami-0a44f00b",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-1" => {
    "32"    => "ami-b4b0cae6",
    "64"    => "ami-beb0caec",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-2" => {
    "32"    => "ami-b3990e89",
    "64"    => "ami-bd990e87",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "eu-west-1"      => {
    "32"    => "ami-973b06e3",
    "64"    => "ami-953b06e1",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "sa-east-1"      => {
    "32"    => "ami-3e3be423",
    "64"    => "ami-3c3be421",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-east-1"      => {
    "32"    => "ami-31814f58",
    "64"    => "ami-1b814f72",
    "64HVM" => "ami-0da96764"
  },
  "us-west-1"      => {
    "32"    => "ami-11d68a54",
    "64"    => "ami-1bd68a5e",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-west-2"      => {
    "32"    => "ami-38fe7308",
    "64"    => "ami-30fe7300",
    "64HVM" => "NOT_YET_SUPPORTED"
  }
})

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/puppet/puppet.conf"    => {
        "content" => FnJoin("", [
  "[main]\n",
  "   logdir=/var/log/puppet\n",
  "   rundir=/var/run/puppet\n",
  "   ssldir=$vardir/ssl\n",
  "   pluginsync=true\n",
  "[agent]\n",
  "   classfile=$vardir/classes.txt\n",
  "   localconfig=$vardir/localconfig\n",
  "   server=",
  Ref("PuppetMasterDNSName"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/yum.repos.d/epel.repo" => {
        "group"  => "root",
        "mode"   => "000644",
        "owner"  => "root",
        "source" => "https://s3.amazonaws.com/cloudformation-examples/enable-epel-on-amazon-linux-ami"
      }
    },
    "packages" => {
      "rubygems" => {
        "json" => []
      },
      "yum"      => {
        "gcc"        => [],
        "make"       => [],
        "puppet"     => [],
        "ruby-devel" => [],
        "rubygems"   => []
      }
    },
    "services" => {
      "sysvinit" => {
        "puppet" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
      }
    }
  }
})
    Metadata("Puppet", {
  "database" => "WordPressDB",
  "host"     => FnGetAtt("WordPressDatabase", "Endpoint.Address"),
  "password" => Ref("DatabasePassword"),
  "roles"    => [
    "wordpress"
  ],
  "user"     => Ref("DatabaseUser")
})
    Property("SecurityGroups", [
  Ref("PuppetClientSecurityGroup"),
  Ref("EC2SecurityGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init --region ",
  Ref("AWS::Region"),
  "    -s ",
  Ref("AWS::StackId"),
  " -r WebServer",
  "\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("ApplicationWaitHandle"),
  "'\n"
])))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("EC2SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access for Wordpress plus SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  }
])
  end

  Resource("ApplicationWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("ApplicationWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServer")
    Property("Handle", Ref("ApplicationWaitHandle"))
    Property("Timeout", "600")
  end

  Resource("WordPressDatabase") do
    Type("AWS::RDS::DBInstance")
    Property("AllocatedStorage", "5")
    Property("DBName", "WordPressDB")
    Property("Engine", "MySQL")
    Property("DBInstanceClass", Ref("DatabaseType"))
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("MasterUsername", Ref("DatabaseUser"))
    Property("MasterUserPassword", Ref("DatabasePassword"))
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => Ref("EC2SecurityGroup")
})
    Property("GroupDescription", "database access")
  end

  Output("WebsiteURL") do
    Description("URL of the WordPress website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName"),
  "/wordpress"
]))
  end

  Output("InstallURL") do
    Description("URL to install WordPress")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName"),
  "/wordpress/wp-admin/install.php"
]))
  end
end

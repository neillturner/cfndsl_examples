CloudFormation do
  Description("Install a WordPress deployment using an Amazon RDS database instance for storage. This template demonstrates using the AWS CloudFormation bootstrap scripts to install Chef Solo and then Chef Solo is used to install a simple WordPress recipe. **WARNING** This template creates an Amazon EC2 instance and an RDS database. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
  end

  Parameter("FrontendType") do
    Description("Frontend EC2 instance type")
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

  Parameter("GroupSize") do
    Description("The default number of EC2 instances for the frontend cluster")
    Type("Number")
    Default("1")
  end

  Parameter("MaxSize") do
    Description("The maximum number of EC2 instances for the frontend")
    Type("Number")
    Default("1")
  end

  Parameter("DBClass") do
    Description("Database instance class")
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
    ConstraintDescription("must select a valid database instance type.")
  end

  Parameter("DBName") do
    Description("The WordPress database name")
    Type("String")
    Default("wordpress")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUser") do
    Description("The WordPress database admin account username")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("The WordPress database admin account password")
    Type("String")
    Default("password")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("MultiAZDatabase") do
    Description("If true, creates a Multi-AZ deployment of the RDS database")
    Type("String")
    Default("false")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be either true or false.")
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

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("Listeners", [
  {
    "InstancePort"     => 80,
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "2",
  "Interval"           => "10",
  "Target"             => "HTTP:80/wp-admin/install.php",
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
    Property("AvailabilityZones", FnGetAZs(Ref("AWS::Region")))
  end

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("AvailabilityZones", FnGetAZs(Ref("AWS::Region")))
    Property("MinSize", "0")
    Property("MaxSize", Ref("MaxSize"))
    Property("DesiredCapacity", Ref("GroupSize"))
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("AWS::CloudFormation::Init", {
  "chefversion" => {
    "files"    => {
      "/etc/chef/node.json" => {
        "content" => {
          "run_list"  => [
            "recipe[wordpress]"
          ],
          "wordpress" => {
            "db" => {
              "database" => Ref("DBName"),
              "host"     => FnGetAtt("DBInstance", "Endpoint.Address"),
              "password" => Ref("DBPassword"),
              "user"     => Ref("DBUser")
            }
          }
        },
        "group"   => "wheel",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/chef/solo.rb"   => {
        "content" => FnJoin("
", [
  "log_level :info",
  "log_location STDOUT",
  "file_cache_path \"/var/chef-solo\"",
  "cookbook_path \"/var/chef-solo/cookbooks\"",
  "json_attribs \"/etc/chef/node.json\"",
  "recipe_url \"https://s3.amazonaws.com/cloudformation-examples/wordpress.tar.gz\""
]),
        "group"   => "wheel",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "rubygems" => {
        "chef" => [
          "10.18.2"
        ]
      },
      "yum"      => {
        "autoconf"   => [],
        "automake"   => [],
        "gcc-c++"    => [],
        "make"       => [],
        "ruby-devel" => [],
        "rubygems"   => []
      }
    }
  },
  "configSets"  => {
    "order" => [
      "gems",
      "chefversion"
    ]
  },
  "gems"        => {
    "packages" => {
      "rubygems" => {
        "net-ssh"         => [
          "2.2.2"
        ],
        "net-ssh-gateway" => [
          "1.1.0"
        ]
      }
    }
  }
})
    Property("InstanceType", Ref("FrontendType"))
    Property("SecurityGroups", [
  Ref("SSHGroup"),
  Ref("FrontendGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("FrontendType"), "Arch")))
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r LaunchConfig ",
  "         --region ",
  Ref("AWS::Region"),
  " && ",
  "chef-solo\n",
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
    DependsOn("WebServerGroup")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "600")
  end

  Resource("DBInstance") do
    Type("AWS::RDS::DBInstance")
    Property("Engine", "MySQL")
    Property("DBName", Ref("DBName"))
    Property("Port", "3306")
    Property("MultiAZ", Ref("MultiAZDatabase"))
    Property("MasterUsername", Ref("DBUser"))
    Property("DBInstanceClass", Ref("DBClass"))
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("AllocatedStorage", "5")
    Property("MasterUserPassword", Ref("DBPassword"))
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => Ref("FrontendGroup")
})
    Property("GroupDescription", "Frontend Access")
  end

  Resource("SSHGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("FrontendGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => "80",
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => "80"
  }
])
  end

  Output("WebsiteURL") do
    Description("URL to install WordPress")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName"),
  "/"
]))
  end

  Output("InstallURL") do
    Description("URL to install WordPress")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName"),
  "/wp-admin/install.php"
]))
  end
end

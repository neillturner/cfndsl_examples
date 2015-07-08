CloudFormation do
  Description("AWS CloudFormation Sample Template Rails_Multi_AZ: Create a highly available, scalable Ruby on Rails stack with a multi-AZ MySQL Amazon RDS database instance for the backend data store. This template demonstrates using the AWS CloudFormation bootstrap scripts to install the packages and files necessary to deploy the packages and files at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an Elastic Load Balancer and an Amazon RDS DB instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
    AllowedPattern("[-_ a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("can contain only alphanumeric characters, spaces, dashes and underscores.")
  end

  Parameter("DBName") do
    Description("MySQL database name")
    Type("String")
    Default("MyDatabase")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUsername") do
    Description("Username for MySQL database access")
    Type("String")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("Password for MySQL database access")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBAllocatedStorage") do
    Description("The size of the database (Gb)")
    Type("Number")
    Default("5")
    MaxValue(1024)
    MinValue(5)
    ConstraintDescription("must be between 5 and 1024Gb.")
  end

  Parameter("DBInstanceClass") do
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
    ConstraintDescription("must select a valid database instance type.")
  end

  Parameter("MultiAZDatabase") do
    Description("Create a multi-AZ MySQL Amazon RDS database instance")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be either true or false.")
  end

  Parameter("WebServerCapacity") do
    Description("The initial number of WebServer instances")
    Type("Number")
    Default("2")
    MaxValue(5)
    MinValue(1)
    ConstraintDescription("must be between 1 and 5 EC2 instances.")
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
    Metadata("Comment", "Configure the Load Balancer with a simple health check and cookie-based stickiness")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LBCookieStickinessPolicy", [
  {
    "CookieExpirationPeriod" => "30",
    "PolicyName"             => "CookieBasedPolicy"
  }
])
    Property("Listeners", [
  {
    "InstancePort"     => "3000",
    "LoadBalancerPort" => "80",
    "PolicyNames"      => [
      "CookieBasedPolicy"
    ],
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "2",
  "Interval"           => "10",
  "Target"             => "HTTP:3000/",
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
  end

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", "1")
    Property("MaxSize", "5")
    Property("DesiredCapacity", Ref("WebServerCapacity"))
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("Comment1", "Configure the bootstrap helpers to install the Rails")
    Metadata("Comment2", "The application is downloaded from the CloudFormationRailsSample.zip file")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/home/ec2-user/sample/config/database.yml" => {
        "content" => FnJoin("", [
  "development:\n",
  "  adapter: mysql2\n",
  "  encoding: utf8\n",
  "  reconnect: false\n",
  "  pool: 5\n",
  "  database: ",
  Ref("DBName"),
  "\n",
  "  username: ",
  Ref("DBUsername"),
  "\n",
  "  password: ",
  Ref("DBPassword"),
  "\n",
  "  host: ",
  FnGetAtt("MySQLDatabase", "Endpoint.Address"),
  "\n",
  "  port: ",
  FnGetAtt("MySQLDatabase", "Endpoint.Port"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "rubygems" => {
        "execjs"       => [],
        "rack"         => [
          "1.3.6"
        ],
        "rails"        => [
          "3.2.14"
        ],
        "therubyracer" => []
      },
      "yum"      => {
        "gcc-c++"     => [],
        "make"        => [],
        "mysql"       => [],
        "mysql-devel" => [],
        "mysql-libs"  => [],
        "ruby-devel"  => [],
        "rubygems"    => []
      }
    },
    "sources"  => {
      "/home/ec2-user/sample" => "https://s3.amazonaws.com/cloudformation-examples/CloudFormationRailsSample.zip"
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("WebServerSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Helper function\n",
  "function error_exit\n",
  "{\n",
  "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
  Ref("WaitHandle"),
  "'\n",
  "  exit 1\n",
  "}\n",
  "# Install Rails packages\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r LaunchConfig ",
  "    --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Install anu other Gems, create the database and run a migration\n",
  "cd /home/ec2-user/sample\n",
  "bundle install  || error_exit 'Failed to install bundle'\n",
  "rake db:migrate || error_exit 'Failed to execute database migration'\n",
  "# Startup the rails server\n",
  "rails server -d\n",
  "echo \"cd /home/ec2-user/sample\" >> /etc/rc.local\n",
  "echo \"rails server -d\" >> /etc/rc.local\n",
  "# All is well so signal success\n",
  "/opt/aws/bin/cfn-signal -e 0 -r \"Rails application setup complete\" '",
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
    Property("Timeout", "1500")
    Property("Count", Ref("WebServerCapacity"))
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 3000 locked down to the load balancer + SSH access")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => "3000",
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => "3000"
  },
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("GroupDescription", "Grant database access to web server")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => Ref("WebServerSecurityGroup")
})
  end

  Resource("MySQLDatabase") do
    Type("AWS::RDS::DBInstance")
    Property("Engine", "MySQL")
    Property("DBName", Ref("DBName"))
    Property("MultiAZ", Ref("MultiAZDatabase"))
    Property("MasterUsername", Ref("DBUsername"))
    Property("MasterUserPassword", Ref("DBPassword"))
    Property("DBInstanceClass", Ref("DBInstanceClass"))
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("AllocatedStorage", Ref("DBAllocatedStorage"))
  end

  Output("WebsiteURL") do
    Description("URL for newly created Rails application")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

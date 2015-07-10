CloudFormation do
  Description("AWS CloudFormation Sample Template Redmine_Multi_AZ: Redmine is a  flexible project management web application which includes a gantt chart, calendar, wiki, forums, multiple roles, and email notification. This template installs a highly-available, scalable Redmine deployment using a multi-az Amazon RDS database instance for storage. It demonstrates using the AWS CloudFormation bootstrap scripts to install the packages and files necessary to deploy the Redmine, Rails, MySQL and all dependent packages at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an Amazon RDS database instance and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.")
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
    Default("redmine")
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
    Description("Password MySQL database access")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
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

  Parameter("DBAllocatedStorage") do
    Description("The size of the database (Gb)")
    Type("Number")
    Default("5")
    MaxValue(1024)
    MinValue(5)
    ConstraintDescription("must be between 5 and 1024Gb.")
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
    "InstancePort"     => "80",
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
  "Target"             => "HTTP:80/",
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
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/home/ec2-user/redmine/redmine-2.0.2/config/database.yml" => {
        "content" => FnJoin("", [
  "production:\n",
  "  adapter: mysql\n",
  "  database: ",
  Ref("DBName"),
  "\n",
  "  host: ",
  FnGetAtt("DBInstance", "Endpoint.Address"),
  "\n",
  "  username: ",
  Ref("DBUsername"),
  "\n",
  "  password: ",
  Ref("DBPassword"),
  "\n",
  "  timeout: 5000\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/home/ec2-user/run_redmine"                               => {
        "content" => FnJoin("", [
  "#!/bin/bash -v\n",
  "#Install and run Redmine\n",
  "cd /home/ec2-user/redmine/redmine-2.0.2\n",
  "bundle install --without development test postgresql sqlite\n",
  "rake generate_secret_token\n",
  "RAILS_ENV=production rake db:migrate\n",
  "RAILS_ENV=production rake redmine:load_default_data << EOF\n",
  "en\n",
  "EOF\n",
  "ruby script/rails server webrick -e production --port=80 &\n"
]),
        "group"   => "root",
        "mode"    => "000755",
        "owner"   => "root"
      }
    },
    "packages" => {
      "rubygems" => {
        "bundle" => []
      },
      "yum"      => {
        "ImageMagick-devel" => [],
        "freetype-devel"    => [],
        "gcc-c++"           => [],
        "ghostscript-devel" => [],
        "git"               => [],
        "libjpeg-devel"     => [],
        "libpng-devel"      => [],
        "libtiff-devel"     => [],
        "make"              => [],
        "mysql"             => [],
        "mysql-devel"       => [],
        "ruby-devel"        => [],
        "ruby-rdoc"         => [],
        "rubygems"          => []
      }
    },
    "sources"  => {
      "/home/ec2-user/redmine" => "http://rubyforge.org/frs/download.php/76189/redmine-2.0.2.tar.gz"
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
  "# Install packages\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r LaunchConfig ",
  "    --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Startup Redmine\n",
  "/home/ec2-user/run_redmine\n",
  "# All is well so signal success\n",
  "/opt/aws/bin/cfn-signal -e $? -r \"Redmine setup complete\" '",
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
    Property("Timeout", "900")
  end

  Resource("DBInstance") do
    Type("AWS::RDS::DBInstance")
    Property("DBName", Ref("DBName"))
    Property("Engine", "MySQL")
    Property("MasterUsername", Ref("DBUsername"))
    Property("DBInstanceClass", Ref("DBClass"))
    Property("MultiAZ", Ref("MultiAZDatabase"))
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("AllocatedStorage", Ref("DBAllocatedStorage"))
    Property("MasterUserPassword", Ref("DBPassword"))
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => Ref("WebServerSecurityGroup")
})
    Property("GroupDescription", "Frontend Access")
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80, the indexer port plus SSH access")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => "80",
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => "80"
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
    Description("URL for Redmine")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template Insoshi_Multi_AZ: Insoshi is an open source social networking platform in Ruby on Rails. This template installs a highly-available, scalable Insoshi deployment using a multi-az Amazon RDS database instance for storage and using an S3 bucket for photos and thumbnails. It demonstrates using the AWS CloudFormation bootstrap scripts to install the packages and files necessary to deploy Insoshi, Rails, MySQL and all dependent packages at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an S3 bucket, and Amazon RDS database instance and other AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
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
    Default("insoshi")
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
    Description("The IP address range that can be used to SSH to the EC2 instances")
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

  Resource("S3User") do
    Type("AWS::IAM::User")
  end

  Resource("S3Keys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("S3User"))
  end

  Resource("S3Content") do
    Type("AWS::S3::Bucket")
    Property("AccessControl", "PublicRead")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "WriteContentPolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectACL"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("S3User", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("S3Content"),
  "/*"
]),
      "Sid"       => "WriteAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("S3Content"))
  end

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
  "configSets"      => {
    "full_install" => [
      "install_prereqs",
      "setup_rubygems",
      "install_insoshi"
    ]
  },
  "install_insoshi" => {
    "commands" => {
      "01_build_sphinx"      => {
        "command" => "/home/ec2-user/build_sphinx &> /var/log/build_sphinx.log",
        "cwd"     => "/home/ec2-user/sphinx/sphinx-2.0.6-release"
      },
      "02_configure_insoshi" => {
        "command" => "/home/ec2-user/configure_insoshi &> /var/log/configure_insoshi.log",
        "cwd"     => "/home/ec2-user/insoshi"
      },
      "03_cleanup"           => {
        "command" => "rm -Rf build_sphinx configure_insoshi sphinx",
        "cwd"     => "/home/ec2-user"
      }
    },
    "files"    => {
      "/home/ec2-user/build_sphinx"                 => {
        "content" => FnJoin("", [
  "# Build search indexer\n",
  "./configure\n",
  "make\n",
  "make install\n"
]),
        "group"   => "root",
        "mode"    => "000700",
        "owner"   => "root"
      },
      "/home/ec2-user/configure_insoshi"            => {
        "content" => FnJoin("", [
  "# Install Insoshi with search indexer configured\n",
  "export PATH=$PATH:/usr/local/bin\n",
  "script/install\n",
  "rake ultrasphinx:configure\n",
  "rake ultrasphinx:index\n",
  "rake ultrasphinx:daemon:start\n",
  "# Fixup configuration to use S3 for photos and thumbnails\n",
  "sed -i 's/file_system/s3/' app/models/photo.rb\n",
  "sed -i 's/file_system/s3/' app/models/thumbnail.rb\n",
  "script/server -d -p 80\n"
]),
        "group"   => "root",
        "mode"    => "000700",
        "owner"   => "root"
      },
      "/home/ec2-user/insoshi/config/amazon_s3.yml" => {
        "content" => FnJoin("", [
  "development:\n",
  "  bucket_name: ",
  Ref("S3Content"),
  "\n",
  "  access_key_id: ",
  Ref("S3Keys"),
  "\n",
  "  secret_access_key: ",
  FnGetAtt("S3Keys", "SecretAccessKey"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000600",
        "owner"   => "root"
      },
      "/home/ec2-user/insoshi/config/database.yml"  => {
        "content" => FnJoin("", [
  "development:\n",
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
        "mode"    => "000600",
        "owner"   => "root"
      }
    },
    "packages" => {
      "rubygems" => {
        "aws-s3"    => [],
        "chronic"   => [
          "0.9.1"
        ],
        "mysql"     => [
          "2.9.1"
        ],
        "rails"     => [
          "2.3.15"
        ],
        "rake"      => [
          "0.8.7"
        ],
        "rdiscount" => [
          "2.0.7.3"
        ],
        "rmagick"   => [
          "2.13.2"
        ]
      }
    },
    "sources"  => {
      "/home/ec2-user/insoshi" => "http://github.com/insoshi/insoshi/tarball/master",
      "/home/ec2-user/sphinx"  => "http://sphinxsearch.com/files/sphinx-2.0.6-release.tar.gz"
    }
  },
  "install_prereqs" => {
    "packages" => {
      "yum" => {
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
        "mysql-libs"        => [],
        "ruby-devel"        => [],
        "ruby-rdoc"         => [],
        "rubygems"          => []
      }
    }
  },
  "setup_rubygems"  => {
    "commands" => {
      "01_install_version_142" => {
        "command" => "gem update --system 1.4.2 &> /var/log/gem_update.log"
      }
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
  "# Install packages\n",
  "/opt/aws/bin/cfn-init --stack ",
  Ref("AWS::StackId"),
  "                      --resource LaunchConfig ",
  "                      --configsets full_install ",
  "                      --region ",
  Ref("AWS::Region"),
  "\n",
  "# Signal completion\n",
  "/opt/aws/bin/cfn-signal -e $? -r \"Insoshi setup complete\" '",
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
  end

  Resource("DBInstance") do
    Type("AWS::RDS::DBInstance")
    Property("DBName", Ref("DBName"))
    Property("Engine", "MySQL")
    Property("MasterUsername", Ref("DBUsername"))
    Property("MultiAZ", Ref("MultiAZDatabase"))
    Property("DBInstanceClass", Ref("DBClass"))
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
    Description("URL for Insoshi")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template Insoshi_Single_Instance: Insoshi is an open source social networking platform in Ruby on Rails. This template creates a Insoshi stack using a single EC2 instance and a local MySQL database for storage. It demonstrates using the AWS CloudFormation bootstrap scripts to install the packages and files necessary to deploy the Insoshi, Rails, MySQL and all dependent packages at instance launch time. **WARNING** This template creates an Amazon EC2 instance and other AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
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
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBRootPassword") do
    Description("Root password for MySQL")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
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

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "configSets"      => {
    "full_install" => [
      "install_prereqs",
      "setup_mysql",
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
      "/home/ec2-user/build_sphinx"                => {
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
      "/home/ec2-user/configure_insoshi"           => {
        "content" => FnJoin("", [
  "# Install Insoshi with search indexer configured\n",
  "export PATH=$PATH:/usr/local/bin\n",
  "script/install\n",
  "rake ultrasphinx:configure\n",
  "rake ultrasphinx:index\n",
  "rake ultrasphinx:daemon:start\n",
  "script/server -d -p 80\n"
]),
        "group"   => "root",
        "mode"    => "000700",
        "owner"   => "root"
      },
      "/home/ec2-user/insoshi/config/database.yml" => {
        "content" => FnJoin("", [
  "development:\n",
  "  adapter: mysql\n",
  "  database: ",
  Ref("DBName"),
  "\n",
  "  host: localhost\n",
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
        "mysql-server"      => [],
        "ruby-devel"        => [],
        "ruby-rdoc"         => [],
        "rubygems"          => []
      }
    },
    "services" => {
      "sysvinit" => {
        "mysqld" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
      }
    }
  },
  "setup_mysql"     => {
    "commands" => {
      "01_create_accounts" => {
        "command" => "/tmp/setup_mysql &> /var/log/setup_mysql.log"
      },
      "02_cleanup"         => {
        "command" => "rm /tmp/setup_mysql /tmp/setup.mysql"
      }
    },
    "files"    => {
      "/tmp/setup.mysql" => {
        "content" => FnJoin("", [
  "GRANT ALL ON ",
  Ref("DBName"),
  ".* TO '",
  Ref("DBUsername"),
  "'@'localhost' IDENTIFIED BY '",
  Ref("DBPassword"),
  "';\n"
]),
        "group"   => "root",
        "mode"    => "000600",
        "owner"   => "root"
      },
      "/tmp/setup_mysql" => {
        "content" => FnJoin("", [
  "# Setup MySQL root password and create a user\n",
  "mysqladmin -u root password '",
  Ref("DBRootPassword"),
  "'\n",
  "mysql -u root --password='",
  Ref("DBRootPassword"),
  "' < /tmp/setup.mysql\n"
]),
        "group"   => "root",
        "mode"    => "000700",
        "owner"   => "root"
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
  "                      --resource WebServer ",
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
    DependsOn("WebServer")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "1500")
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80, the indexer port plus SSH access")
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
    Description("URL for Insoshi")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName")
]))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template Rails_Simple: Create a Ruby on Rails stack using a single EC2 instance with a local MySQL database for storage. This template demonstrates using the AWS CloudFormation bootstrap scripts to install the packages and files necessary to deploy the packages and files at instance launch time. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("DBRootPassword") do
    Description("Root password for MySQL")
    Type("String")
    Default("admin")
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
      "/home/ec2-user/sample/config/database.yml" => {
        "content" => FnJoin("", [
  "development:\n",
  "  adapter: mysql2\n",
  "  encoding: utf8\n",
  "  reconnect: false\n",
  "  pool: 5\n",
  "  database: railsdb\n",
  "  username: root\n",
  "  password: ",
  Ref("DBRootPassword"),
  "\n",
  "  socket: /var/lib/mysql/mysql.sock\n"
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
        "gcc-c++"      => [],
        "make"         => [],
        "mysql"        => [],
        "mysql-devel"  => [],
        "mysql-libs"   => [],
        "mysql-server" => [],
        "ruby-devel"   => [],
        "rubygems"     => []
      }
    },
    "services" => {
      "sysvinit" => {
        "mysqld" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
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
  Ref("FrontendGroup")
])
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
  " -r WebServer ",
  "    --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Setup MySQL root password and create a user\n",
  "mysqladmin -u root password '",
  Ref("DBRootPassword"),
  "' || error_exit 'Failed to initialize root password'\n",
  "# Install anu other Gems, create the database and run a migration\n",
  "cd /home/ec2-user/sample\n",
  "bundle install  || error_exit 'Failed to install bundle'\n",
  "rake db:create  || error_exit 'Failed to create database'\n",
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
    DependsOn("WebServer")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "1500")
  end

  Resource("FrontendGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 3000")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "3000",
    "IpProtocol" => "tcp",
    "ToPort"     => "3000"
  }
])
  end

  Output("WebsiteURL") do
    Description("URL for newly created Rails application")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName"),
  ":3000"
]))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template Joomla!_Single_Instance: Joomla! is a free, open-source content management system (CMS) and application framework. This template installs a single-instance Joomla! deployment using a local MySQL database to store the data. It demonstrates using the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
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

  Parameter("AdminPassword") do
    Description("The Joomla! admin account password")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBName") do
    Description("The Joomla! database name")
    Type("String")
    Default("joomladb")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUsername") do
    Description("The Joomla! database admin account username")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("The Joomla! database admin account password")
    Type("String")
    Default("admin")
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
    "32"    => "ami-2a19aa2b",
    "64"    => "ami-2819aa29",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-1" => {
    "32"    => "ami-220b4a70",
    "64"    => "ami-3c0b4a6e",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-2" => {
    "32"    => "ami-b3990e89",
    "64"    => "ami-bd990e87",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "eu-west-1"      => {
    "32"    => "ami-61555115",
    "64"    => "ami-6d555119",
    "64HVM" => "ami-67555113"
  },
  "sa-east-1"      => {
    "32"    => "ami-f836e8e5",
    "64"    => "ami-fe36e8e3",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-east-1"      => {
    "32"    => "ami-a0cd60c9",
    "64"    => "ami-aecd60c7",
    "64HVM" => "ami-a8cd60c1"
  },
  "us-west-1"      => {
    "32"    => "ami-7d4c6938",
    "64"    => "ami-734c6936",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-west-2"      => {
    "32"    => "ami-46da5576",
    "64"    => "ami-48da5578",
    "64HVM" => "NOT_YET_SUPPORTED"
  }
})

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/tmp/create_accounts.mysql" => {
        "content" => FnJoin("", [
  "INSERT INTO `jos_users` VALUES (62, 'Administrator', 'admin', 'nobody@amazon.com', MD5('",
  Ref("AdminPassword"),
  "'), 'Super Administrator', 0, 1, '2011-01-01 00:00:00', '2011-01-01 00:00:00', '', '');\n",
  "INSERT INTO `jos_user_usergroup_map` (`user_id`, `group_id`) VALUES (62,8);\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/tmp/setup.mysql"           => {
        "content" => FnJoin("", [
  "CREATE DATABASE ",
  Ref("DBName"),
  ";\n",
  "CREATE USER '",
  Ref("DBUsername"),
  "'@'localhost' IDENTIFIED BY '",
  Ref("DBPassword"),
  "';\n",
  "GRANT ALL ON ",
  Ref("DBName"),
  ".* TO '",
  Ref("DBUsername"),
  "'@'localhost';\n",
  "FLUSH PRIVILEGES;\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "yum" => {
        "httpd"        => [],
        "mysql"        => [],
        "mysql-server" => [],
        "php"          => [],
        "php-mysql"    => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd"    => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        },
        "mysqld"   => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        },
        "sendmail" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
      }
    },
    "sources"  => {
      "/var/www/html" => "http://joomlacode.org/gf/download/frsrelease/15900/68956/Joomla_1.7.2-Stable-Full_Package.zip"
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
  "# Install Apache Web Server, MySQL, PHP and Joomla!\n",
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
  "mysql --user=root --password='",
  Ref("DBRootPassword"),
  "' < /tmp/setup.mysql || error_exit 'Failed to create database user'\n",
  "# Setup Joomla! database\n",
  "sed -e 's/#__/jos_/g' < /var/www/html/installation/sql/mysql/joomla.sql > /var/www/html/joomla.sql\n",
  "mysql ",
  Ref("DBName"),
  " --user=",
  Ref("DBUsername"),
  " --password=",
  Ref("DBPassword"),
  "< /var/www/html/joomla.sql\n",
  "mysql ",
  Ref("DBName"),
  " --user=",
  Ref("DBUsername"),
  " --password=",
  Ref("DBPassword"),
  "< /tmp/create_accounts.mysql\n",
  "# Fixup configuration\n",
  "sed -e \"s/\\$user = ''/\\$user = '",
  Ref("DBUsername"),
  "'/g\"",
  "    -e \"s/\\$password = ''/\\$password = '",
  Ref("DBPassword"),
  "'/g\"",
  "    -e \"s/\\$db = ''/\\$db = '",
  Ref("DBName"),
  "'/g\"",
  "    < /var/www/html/installation/configuration.php-dist > /var/www/html/configuration.php\n",
  "# Cleanup installation\n",
  "rm /tmp/setup.mysql\n",
  "rm /tmp/create_accounts.mysql\n",
  "rm /var/www/html/joomla.sql\n",
  "rm -Rf /var/www/html/installation\n",
  "# All is well so signal success\n",
  "/opt/aws/bin/cfn-signal -e 0 -r \"Joomla setup complete\" '",
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
    Property("Timeout", "300")
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80 and SSH access")
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
    Description("Joomla! Website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName")
]))
  end

  Output("AdminURL") do
    Description("Joomla! Administration Website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName"),
  "/administrator"
]))
  end
end

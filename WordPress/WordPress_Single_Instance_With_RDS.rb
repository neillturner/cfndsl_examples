CloudFormation do
  Description("AWS CloudFormation Sample Template WordPress_Single_Instance_With_RDS: WordPress is web software you can use to create a beautiful website or blog. This template installs a single-instance WordPress deployment using an Amazon RDS database instance for storage. It demonstrates using the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates an Amazon EC2 instance and an Amazon RDS database instance. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("DBUsername") do
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

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/var/www/html/wordpress/wp-config.php" => {
        "content" => FnJoin("", [
  "<?php\n",
  "define('DB_NAME',          '",
  Ref("DBName"),
  "');\n",
  "define('DB_USER',          '",
  Ref("DBUsername"),
  "');\n",
  "define('DB_PASSWORD',      '",
  Ref("DBPassword"),
  "');\n",
  "define('DB_HOST',          '",
  FnGetAtt("DBInstance", "Endpoint.Address"),
  "');\n",
  "define('DB_CHARSET',       'utf8');\n",
  "define('DB_COLLATE',       '');\n",
  "define('AUTH_KEY',         'f@A17vs{ mO0}:&I,6SB.QzV`E?!`/tN5:~GZX%=@ZA%!_T0-]9>g]4ll6~,6G|R');\n",
  "define('SECURE_AUTH_KEY',  'gTFTI|~rYHY)|mlu:Cv7RN]GQ^3ngyUbw;L0o!12]0c-ispR<-yt3qj]xjquz^&9');\n",
  "define('LOGGED_IN_KEY',    'Jd:HG9M)1p5t2<v~+R-vd{p-Q*|*RB^&PUI{vIrydAEEiV!{HS{jN:nErCmLv`p}');\n",
  "define('NONCE_KEY',        '4aMj4KZV;,Gu7(B|qOCve[c5?*J5x1+x93i:Ey6hh/6jXh+V_{V4+hw!qE^d*U,-');\n",
  "define('AUTH_SALT',        '_Y_&8m)FH)Cns)8}Yb8b88KDSn:p1#p(qBa<~VW&Y1v}P.*9/8S8@P`{mkNxV lC');\n",
  "define('SECURE_AUTH_SALT', '%nG3Ag41^Lew5c86,#zbN:yPFs.GA5a)z5*:Oce1>v6uF~D`,.o1pzS)F8[bM9i[');\n",
  "define('LOGGED_IN_SALT',   '~K<y+Ly+_Ww1~dtq>;rSQ^+{P5/k|=!]k%RXAF-Y@XMY6GSp+wJ5{(|rCzaWjZ%/');\n",
  "define('NONCE_SALT',       ',Bs_*Y9:b/1Z:apVLHtz35uim|okkA,b|Jt[-&Nla=T{<l_#D?~6Tj-.2.]FonI~');\n",
  "define('WPLANG'            , '');\n",
  "define('WP_DEBUG'          , false);\n",
  "$table_prefix  = 'wp_';\n",
  "if ( !defined('ABSPATH') )\n",
  "    define('ABSPATH', dirname(__FILE__) . '/');\n",
  "require_once(ABSPATH . 'wp-settings.php');\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "yum" => {
        "httpd"     => [],
        "php"       => [],
        "php-mysql" => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd"    => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        },
        "sendmail" => {
          "enabled"       => "false",
          "ensureRunning" => "false"
        }
      }
    },
    "sources"  => {
      "/var/www/html" => "http://wordpress.org/latest.tar.gz"
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
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServer ",
  "         --region ",
  Ref("AWS::Region"),
  "\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("WaitHandle"),
  "'\n",
  "# Setup correct file ownership\n",
  "chown -R apache:apache /var/www/html/wordpress\n"
])))
  end

  Resource("WaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServer")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "600")
  end

  Resource("DBInstance") do
    Type("AWS::RDS::DBInstance")
    Property("DBName", Ref("DBName"))
    Property("Engine", "MySQL")
    Property("MasterUsername", Ref("DBUsername"))
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
    Description("WordPress Website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName"),
  "/wordpress"
]))
  end
end

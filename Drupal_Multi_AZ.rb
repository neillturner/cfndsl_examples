CloudFormation do
  Description("AWS CloudFormation Sample Template Drupal_Multi_AZ. Drupal is an open source content management platform powering millions of websites and applications. This template installs a highly-available, scalable Drupal deployment using a multi-az Amazon RDS database instance for storage. It uses the AWS CloudFormation bootstrap scripts to install packages and files at instance launch time. **WARNING** This template creates one or more Amazon EC2 instances, an Elastic Load Balancer and an Amazon RDS database. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
  end

  Parameter("InstanceType") do
    Description("WebServer EC2 instance type")
    Type("String")
    Default("m1.small")
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("SiteName") do
    Description("The name of the Drupal Site")
    Type("String")
    Default("My Site")
  end

  Parameter("SiteEMail") do
    Description("EMail for site adminitrator")
    Type("String")
  end

  Parameter("SiteAdmin") do
    Description("The Drupal site admin account username")
    Type("String")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("SitePassword") do
    Description("The Drupal site admin account password")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBName") do
    Description("The Drupal database name")
    Type("String")
    Default("drupaldb")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUsername") do
    Description("The Drupal database admin account username")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("The Drupal database admin account password")
    Type("String")
    Default("password")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
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
    "32"    => "ami-8f990eb5",
    "64"    => "ami-95990eaf",
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

  Resource("S3Bucket") do
    Type("AWS::S3::Bucket")
    DeletionPolicy("Retain")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "UploadPolicy",
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
  Ref("S3Bucket"),
  "/*"
]),
      "Sid"       => "EnableReadWrite"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("S3Bucket"))
  end

  Resource("S3User") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => "s3:*",
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("S3Keys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("S3User"))
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
  "config" => {
    "files"    => {
      "/etc/passwd-s3fs"            => {
        "content" => FnJoin("", [
  Ref("S3Keys"),
  ":",
  FnGetAtt("S3Keys", "SecretAccessKey"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000400",
        "owner"   => "root"
      },
      "/home/ec2-user/settings.php" => {
        "content" => FnJoin("", [
  "<?php\n",
  "\n",
  "$databases = array (\n",
  "  'default' =>\n",
  "  array (\n",
  "    'default' =>\n",
  "    array (\n",
  "      'database' => '",
  Ref("DBName"),
  "',\n",
  "      'username' => '",
  Ref("DBUsername"),
  "',\n",
  "      'password' => '",
  Ref("DBPassword"),
  "',\n",
  "      'host' => '",
  FnGetAtt("DBInstance", "Endpoint.Address"),
  "',\n",
  "      'port' => '",
  FnGetAtt("DBInstance", "Endpoint.Port"),
  "',\n",
  "      'driver' => 'mysql',\n",
  "      'prefix' => 'drupal_',\n",
  "    ),\n",
  "  ),\n",
  ");\n",
  "\n",
  "$update_free_access = FALSE;\n",
  "\n",
  "$drupal_hash_salt = '0c3R8noNALe3shsioQr5hK1dMHdwRfikLoSfqn0_xpA';\n",
  "\n",
  "ini_set('session.gc_probability', 1);\n",
  "ini_set('session.gc_divisor', 100);\n",
  "ini_set('session.gc_maxlifetime', 200000);\n",
  "ini_set('session.cookie_lifetime', 2000000);\n"
]),
        "group"   => "root",
        "mode"    => "000400",
        "owner"   => "root"
      }
    },
    "packages" => {
      "yum" => {
        "fuse"            => [],
        "fuse-devel"      => [],
        "gcc"             => [],
        "gcc-c++"         => [],
        "httpd"           => [],
        "libcurl-devel"   => [],
        "libstdc++-devel" => [],
        "libxml2-devel"   => [],
        "mailcap"         => [],
        "make"            => [],
        "mysql"           => [],
        "openssl-devel"   => [],
        "php"             => [],
        "php-gd"          => [],
        "php-mbstring"    => [],
        "php-mysql"       => [],
        "php-xml"         => []
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
      "/home/ec2-user"      => "http://ftp.drupal.org/files/projects/drush-7.x-4.5.tar.gz",
      "/home/ec2-user/s3fs" => "http://s3fs.googlecode.com/files/s3fs-1.61.tar.gz",
      "/var/www/html"       => "http://ftp.drupal.org/files/projects/drupal-7.8.tar.gz"
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
  "# Install Apache Web Server, MySQL and Drupal\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r LaunchConfig ",
  "    --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Install s3fs\n",
  "cd /home/ec2-user/s3fs/s3fs-1.61\n",
  "./configure --prefix=/usr\n",
  "make\n",
  "make install\n",
  "# Move the website files to the top level\n",
  "mv /var/www/html/drupal-7.8/* /var/www/html\n",
  "mv /var/www/html/drupal-7.8/.htaccess /var/www/html\n",
  "rm -Rf /var/www/html/drupal-7.8\n",
  "# Mount the S3 bucket\n",
  "mv /var/www/html/sites/default/files /var/www/html/sites/default/files_original\n",
  "mkdir -p /var/www/html/sites/default/files\n",
  "s3fs -o allow_other -o use_cache=/tmp ",
  Ref("S3Bucket"),
  " /var/www/html/sites/default/files || error_exit 'Failed to mount the S3 bucket'\n",
  "echo `hostname` >> /var/www/html/sites/default/files/hosts\n",
  "# Make changes to Apache Web Server configuration\n",
  "sed -i 's/AllowOverride None/AllowOverride All/g'  /etc/httpd/conf/httpd.conf\n",
  "service httpd restart\n",
  "# Only execute the site install if we are the first host up - otherwise we'll end up losing all the data\n",
  "read first < /var/www/html/sites/default/files/hosts\n",
  "if [ `hostname` = $first ]\n",
  "then\n",
  "  # Create the site in Drupal\n",
  "  cd /var/www/html\n",
  "  ~ec2-user/drush/drush site-install standard --yes",
  "     --site-name='",
  Ref("SiteName"),
  "' --site-mail=",
  Ref("SiteEMail"),
  "     --account-name=",
  Ref("SiteAdmin"),
  " --account-pass=",
  Ref("SitePassword"),
  "     --db-url=mysql://",
  Ref("DBUsername"),
  ":",
  Ref("DBPassword"),
  "@",
  FnGetAtt("DBInstance", "Endpoint.Address"),
  ":",
  FnGetAtt("DBInstance", "Endpoint.Port"),
  "/",
  Ref("DBName"),
  "     --db-prefix=drupal_\n",
  "  # use the S3 bucket for shared file storage\n",
  "  cp -R sites/default/files_original/* sites/default/files\n",
  "  cp -R sites/default/files_original/.htaccess sites/default/files\n",
  "else\n",
  "  # Copy settings.php file since everything else is configured\n",
  "  cp /home/ec2-user/settings.php /var/www/html/sites/default\n",
  "fi\n",
  "rm /home/ec2-user/settings.php\n",
  "# All is well so signal success\n",
  "/opt/aws/bin/cfn-signal -e 0 -r \"Drupal setup complete\" '",
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
    Property("DBName", Ref("DBName"))
    Property("Engine", "MySQL")
    Property("MultiAZ", Ref("MultiAZDatabase"))
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
    Property("GroupDescription", "Enable HTTP access via port 80, locked down to requests from the load balancer only and SSH access")
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
    Description("Drupal Website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

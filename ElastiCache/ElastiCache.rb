CloudFormation do
  Description("AWS CloudFormation Sample Template ElastiCache: Sample template showing how to create an Amazon ElastiCache Cache Cluster with Auto Discovery and access it from a very simple PHP application. **WARNING** This template creates an Amazon Ec2 Instance and an Amazon ElastiCache Cluster. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing Amazon EC2 KeyPair for SSH access to the Web Server")
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
  "m3.xlarge",
  "m3.2xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge",
  "cc2.8xlarge",
  "cg1.4xlarge",
  "hi1.4xlarge",
  "hs1.8xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("CacheNodeType") do
    Description("The compute and memory capacity of the nodes in the Cache Cluster")
    Type("String")
    Default("cache.m1.small")
    AllowedValues([
  "cache.m1.small",
  "cache.m1.large",
  "cache.m1.xlarge",
  "cache.m2.xlarge",
  "cache.m2.2xlarge",
  "cache.m2.4xlarge",
  "cache.c1.xlarge"
])
    ConstraintDescription("must select a valid Cache Node type.")
  end

  Parameter("NumberOfCacheNodes") do
    Description("The number of Cache Nodes the Cache Cluster should have")
    Type("Number")
    Default("1")
    MaxValue(10)
    MinValue(1)
    ConstraintDescription("must be between 5 and 10.")
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
    "Arch" => "PV64"
  },
  "c1.xlarge"   => {
    "Arch" => "PV64"
  },
  "cc1.4xlarge" => {
    "Arch" => "CLU64"
  },
  "cc2.8xlarge" => {
    "Arch" => "CLU64"
  },
  "cg1.4xlarge" => {
    "Arch" => "GPU64"
  },
  "hi1.4xlarge" => {
    "Arch" => "PV64"
  },
  "hs1.8xlarge" => {
    "Arch" => "PV64"
  },
  "m1.large"    => {
    "Arch" => "PV64"
  },
  "m1.medium"   => {
    "Arch" => "PV64"
  },
  "m1.small"    => {
    "Arch" => "PV64"
  },
  "m1.xlarge"   => {
    "Arch" => "PV64"
  },
  "m2.2xlarge"  => {
    "Arch" => "PV64"
  },
  "m2.4xlarge"  => {
    "Arch" => "PV64"
  },
  "m2.xlarge"   => {
    "Arch" => "PV64"
  },
  "m3.2xlarge"  => {
    "Arch" => "PV64"
  },
  "m3.xlarge"   => {
    "Arch" => "PV64"
  },
  "t1.micro"    => {
    "Arch" => "PV64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-4e6cd34f"
  },
  "ap-southeast-1" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-a6a7e7f4"
  },
  "ap-southeast-2" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "CLU64" => "ami-d97474ad",
    "GPU64" => "ami-1b02026f",
    "PV64"  => "ami-c37474b7"
  },
  "sa-east-1"      => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-1e08d103"
  },
  "us-east-1"      => {
    "CLU64" => "ami-08249861",
    "GPU64" => "ami-02f54a6b",
    "PV64"  => "ami-1624987f"
  },
  "us-west-1"      => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-1bf9de5e"
  },
  "us-west-2"      => {
    "CLU64" => "ami-2431bf14",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-2a31bf1a"
  }
})

  Resource("CacheCluster") do
    Type("AWS::ElastiCache::CacheCluster")
    Property("CacheNodeType", Ref("CacheNodeType"))
    Property("CacheSecurityGroupNames", [
  Ref("CacheSecurityGroup")
])
    Property("Engine", "memcached")
    Property("NumCacheNodes", Ref("NumberOfCacheNodes"))
  end

  Resource("CacheSecurityGroup") do
    Type("AWS::ElastiCache::SecurityGroup")
    Property("Description", "Lock cache down to Web Server access only")
  end

  Resource("CacheSecurityGroupIngress") do
    Type("AWS::ElastiCache::SecurityGroupIngress")
    Property("CacheSecurityGroupName", Ref("CacheSecurityGroup"))
    Property("EC2SecurityGroupName", Ref("WebServerSecurityGroup"))
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP and SSH access")
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

  Resource("WebServerHost") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "commands" => {
      "00_install_memcached_client" => {
        "command" => "pecl install https://s3.amazonaws.com/elasticache-downloads/ClusterClient/PHP/latest-64bit"
      },
      "01_enable_auto_discovery"    => {
        "command" => "echo 'extension=amazon-elasticache-cluster-client.so' > /etc/php.d/memcached.ini"
      }
    },
    "files"    => {
      "/var/www/html/index.php" => {
        "content" => FnJoin("", [
  "<?php\n",
  "echo '<h1>AWS CloudFormation sample application for Amazon ElastiCache</h1>';\n",
  "\n",
  "$server_endpoint = '",
  FnGetAtt("CacheCluster", "ConfigurationEndpoint.Address"),
  "';\n",
  "$server_port = ",
  FnGetAtt("CacheCluster", "ConfigurationEndpoint.Port"),
  ";\n",
  "\n",
  "/**\n",
  " * The following will initialize a Memcached client to utilize the Auto Discovery feature.\n",
  " * \n",
  " * By configuring the client with the Dynamic client mode with single endpoint, the\n",
  " * client will periodically use the configuration endpoint to retrieve the current cache\n",
  " * cluster configuration. This allows scaling the cache cluster up or down in number of nodes\n",
  " * without requiring any changes to the PHP application. \n",
  " */\n",
  "\n",
  "$dynamic_client = new Memcached();\n",
  "$dynamic_client->setOption(Memcached::OPT_CLIENT_MODE, Memcached::DYNAMIC_CLIENT_MODE);\n",
  "$dynamic_client->addServer($server_endpoint, $server_port);\n",
  "\n",
  "$tmp_object = new stdClass;\n",
  "$tmp_object->str_attr = 'test';\n",
  "$tmp_object->int_attr = 123;\n",
  "\n",
  "$dynamic_client->set('key', $tmp_object, 10) or die ('Failed to save data to the cache');\n",
  "echo '<p>Store data in the cache (data will expire in 10 seconds)</p>';\n",
  "\n",
  "$get_result = $dynamic_client->get('key');\n",
  "echo '<p>Data from the cache:<br/>';\n",
  "\n",
  "var_dump($get_result);\n",
  "\n",
  "echo '</p>';\n",
  "?>\n"
]),
        "group"   => "apache",
        "mode"    => "000644",
        "owner"   => "apache"
      }
    },
    "packages" => {
      "yum" => {
        "gcc-c++"  => [],
        "httpd"    => [],
        "php"      => [],
        "php-pear" => []
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
  "# Setup the PHP sample application\n",
  "/opt/aws/bin/cfn-init ",
  "         --stack ",
  Ref("AWS::StackName"),
  "         --resource WebServerHost ",
  "         --region ",
  Ref("AWS::Region"),
  "\n",
  "# Signal the status of cfn-init\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("WebServerWaitHandle"),
  "'\n"
])))
  end

  Resource("WebServerWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WebServerWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServerHost")
    Property("Handle", Ref("WebServerWaitHandle"))
    Property("Timeout", "300")
  end

  Output("WebsiteURL") do
    Description("Application URL")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServerHost", "PublicDnsName")
]))
  end
end

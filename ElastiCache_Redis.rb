CloudFormation do
  Description("AWS CloudFormation Sample Template ElastiCache_Redis: Sample template showing how to create an Amazon ElastiCache Cache Redis Cluster. **WARNING** This template creates an Amazon Ec2 Instance and an Amazon ElastiCache Cluster. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("ClusterNodeType") do
    Description("The compute and memory capacity of the nodes in the  Redis Cluster")
    Type("String")
    Default("cache.m1.small")
    AllowedValues([
  "cache.t1.micro",
  "cache.m1.small",
  "cache.m1.medium",
  "cache.m1.large",
  "cache.m1.xlarge",
  "cache.m2.xlarge",
  "cache.m2.2xlarge",
  "cache.m2.4xlarge",
  "cache.m3.xlarge",
  "cache.m3.2xlarge",
  "cache.c1.xlarge"
])
    ConstraintDescription("must select a valid Cache Node type.")
  end

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
    "CLU64" => "ami-2db33c2c",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-39b23d38"
  },
  "ap-southeast-1" => {
    "CLU64" => "ami-18de914a",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-fade91a8"
  },
  "ap-southeast-2" => {
    "CLU64" => "ami-876bfbbd",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-d16bfbeb"
  },
  "eu-west-1"      => {
    "CLU64" => "ami-d1c0d6a5",
    "GPU64" => "ami-45c0d631",
    "PV64"  => "ami-c7c0d6b3"
  },
  "sa-east-1"      => {
    "CLU64" => "ami-38538925",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-5253894f"
  },
  "us-east-1"      => {
    "CLU64" => "ami-a73758ce",
    "GPU64" => "ami-cf3758a6",
    "PV64"  => "ami-05355a6c"
  },
  "us-west-1"      => {
    "CLU64" => "ami-47fed102",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-3ffed17a"
  },
  "us-west-2"      => {
    "CLU64" => "ami-d75bcde7",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-0358ce33"
  }
})

  Resource("RedisCluster") do
    Type("AWS::ElastiCache::CacheCluster")
    Property("CacheNodeType", Ref("ClusterNodeType"))
    Property("CacheSecurityGroupNames", [
  Ref("RedisClusterSecurityGroup")
])
    Property("Engine", "redis")
    Property("NumCacheNodes", "1")
  end

  Resource("RedisClusterSecurityGroup") do
    Type("AWS::ElastiCache::SecurityGroup")
    Property("Description", "Lock the cluster down")
  end

  Resource("RedisClusterSecurityGroupIngress") do
    Type("AWS::ElastiCache::SecurityGroupIngress")
    Property("CacheSecurityGroupName", Ref("RedisClusterSecurityGroup"))
    Property("EC2SecurityGroupName", Ref("WebServerSecurityGroup"))
  end

  Resource("WebServerRole") do
    Type("AWS::IAM::Role")
    Property("AssumeRolePolicyDocument", {
  "Statement" => [
    {
      "Action"    => [
        "sts:AssumeRole"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "Service" => [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
})
    Property("Path", "/")
  end

  Resource("WebServerRolePolicy") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "WebServerRole")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => "*",
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Roles", [
  Ref("WebServerRole")
])
  end

  Resource("WebServerInstanceProfile") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("WebServerRole")
])
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
      "00-uninstall-default-cli" => {
        "command" => "yum remove -y aws-cli"
      },
      "01-install-aws-cli"       => {
        "command" => "easy_install awscli"
      },
      "02-install_phpredis"      => {
        "command" => "/usr/local/bin/install_phpredis"
      },
      "03-get-cluster-config"    => {
        "command" => "/usr/local/bin/get_cluster_config"
      }
    },
    "files"    => {
      "/etc/cron.d/get_cluster_config"    => {
        "content" => "*/5 * * * * root /usr/local/bin/get_cluster_config",
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/usr/local/bin/get_cluster_config" => {
        "content" => FnJoin("", [
  "#! /bin/bash\n",
  "aws elasticache describe-cache-clusters ",
  "         --cache-cluster-id ",
  Ref("RedisCluster"),
  "         --show-cache-node-info --region ",
  Ref("AWS::Region"),
  " > /tmp/cacheclusterconfig\n"
]),
        "group"   => "root",
        "mode"    => "000755",
        "owner"   => "root"
      },
      "/usr/local/bin/install_phpredis"   => {
        "content" => FnJoin("", [
  "#! /bin/bash\n",
  "cd /tmp\n",
  "wget https://github.com/nicolasff/phpredis/zipball/master -O phpredis.zip\n",
  "unzip phpredis.zip\n",
  "cd nicolasff-phpredis-*\n",
  "phpize\n",
  "./configure\n",
  "make && make install\n",
  "touch /etc/php.d/redis.ini\n",
  "echo extension=redis.so > /etc/php.d/redis.ini\n"
]),
        "group"   => "root",
        "mode"    => "000755",
        "owner"   => "root"
      },
      "/var/www/html/index.php"           => {
        "content" => FnJoin("", [
  "<?php\n",
  "echo \"<h1>AWS CloudFormation sample application for Amazon ElastiCache Redis Cluster</h1>\";\n",
  "\n",
  "$cluster_config = json_decode(file_get_contents('/tmp/cacheclusterconfig'), true);\n",
  "$endpoint = $cluster_config['CacheClusters'][0]['CacheNodes'][0]['Endpoint']['Address'];\n",
  "$port = $cluster_config['CacheClusters'][0]['CacheNodes'][0]['Endpoint']['Port'];\n",
  "\n",
  "echo \"<p>Connecting to Redis Cache Cluster node '{$endpoint}' on port {$port}</p>\";\n",
  "\n",
  "$redis=new Redis();\n",
  "$redis->connect($endpoint, $port);\n",
  "$redis->set('testkey', 'Hello World!');\n",
  "$return = $redis->get('testkey');\n",
  "\n",
  "echo \"<p>Retrieved value: $return</p>\";\n",
  "?>\n"
]),
        "group"   => "apache",
        "mode"    => "000644",
        "owner"   => "apache"
      }
    },
    "packages" => {
      "yum" => {
        "gcc"       => [],
        "httpd"     => [],
        "make"      => [],
        "php"       => [],
        "php-devel" => []
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
    Property("IamInstanceProfile", Ref("WebServerInstanceProfile"))
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
    Property("Timeout", "600")
  end

  Output("WebsiteURL") do
    Description("Application URL")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServerHost", "PublicDnsName")
]))
  end
end

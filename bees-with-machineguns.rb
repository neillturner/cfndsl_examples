CloudFormation do
  Description("Create a spot-priced AutoScaling group and a Bees With Machine Guns controller; execute the load test against the AutoScaling group and store the results in S3. Run /home/ec2-user/run-bees to execute load tests manually.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
  end

  Parameter("BeesControllerInstanceType") do
    Description("Type of EC2 instance to launch")
    Type("String")
    Default("c1.medium")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge"
])
    ConstraintDescription("Must be a valid EC2 instance type.")
  end

  Parameter("TotalConnections") do
    Description("Total connections per load tester")
    Type("Number")
    Default("200000")
  end

  Parameter("SpotPrice") do
    Description("Spot price for application AutoScaling Group")
    Type("Number")
    MinValue(0)
  end

  Parameter("ConcurrentConnections") do
    Description("Number of concurrent requests per load tester")
    Type("Number")
    Default("1000")
  end

  Parameter("BeeCount") do
    Description("Number of EC2 instances to launch as the load generators (bees)")
    Type("Number")
    Default("2")
  end

  Parameter("AppInstanceType") do
    Description("Type of EC2 instant for application AutoScaling Group")
    Type("String")
    Default("c1.medium")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("AppInstanceCountMin") do
    Description("Minimum number of EC2 instances to launch for application AutoScaling Group")
    Type("Number")
    Default("2")
  end

  Parameter("AppInstanceCountMax") do
    Description("Maximum number of EC2 instances to launch for application AutoScaling Group")
    Type("Number")
    Default("2")
  end

  Parameter("AppInstanceCountDesired") do
    Description("Desired number of EC2 instances to launch for application AutoScaling Group")
    Type("Number")
    Default("2")
  end

  Parameter("RunTests") do
    Description("Enter 'true' to run tests immediately. WARNING: CreateStack will not finish until test executes if this is set to 'true'")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("Must be 'true' or 'false'.")
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

  Mapping("AWSRegionPlatform2AMI", {
  "ap-northeast-1" => {
    "amzn" => "ami-e47acbe5",
    "bee"  => "ami-16ac1f17"
  },
  "ap-southeast-1" => {
    "amzn" => "ami-be3374ec",
    "bee"  => "ami-38bef86a"
  },
  "eu-west-1"      => {
    "amzn" => "ami-f9231b8d",
    "bee"  => "ami-67212413"
  },
  "sa-east-1"      => {
    "amzn" => "ami-a6855bbb",
    "bee"  => "ami-5a12cc47"
  },
  "us-east-1"      => {
    "amzn" => "ami-e565ba8c",
    "bee"  => "ami-e661c18f"
  },
  "us-west-1"      => {
    "amzn" => "ami-e78cd4a2",
    "bee"  => "ami-93b5efd6"
  },
  "us-west-2"      => {
    "amzn" => "ami-3ac64a0a",
    "bee"  => "ami-bc05898c"
  }
})

  Resource("CfnUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => "cloudformation:DescribeStackResource",
          "Effect"   => "Allow",
          "Resource" => "*"
        },
        {
          "Action"   => "elasticloadbalancing:DescribeInstanceHealth",
          "Effect"   => "Allow",
          "Resource" => "*"
        },
        {
          "Action"   => "ec2:*",
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("CfnKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("CfnUser"))
  end

  Resource("ResultBucket") do
    Type("AWS::S3::Bucket")
    DeletionPolicy("Retain")
    Property("AccessControl", "Private")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "MyPolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:*"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("CfnUser", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("ResultBucket"),
  "/*"
]),
      "Sid"       => "AllAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("ResultBucket"))
  end

  Resource("BeeController") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "commands" => {
      "00install_aws" => {
        "command" => [
          "perl",
          "/home/ec2-user/tools/aws",
          "--install"
        ]
      },
      "01run_bees"    => {
        "command" => [
          "su",
          "ec2-user",
          "-c",
          "./run-bees"
        ],
        "cwd"     => "/home/ec2-user",
        "test"    => [
          "test",
          "true",
          "=",
          Ref("RunTests")
        ]
      }
    },
    "files"    => {
      "/home/ec2-user/.awssecret"     => {
        "content" => FnJoin("", [
  Ref("CfnKeys"),
  "\n",
  FnGetAtt("CfnKeys", "SecretAccessKey")
]),
        "group"   => "ec2-user",
        "mode"    => "000600",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/.boto"          => {
        "content" => FnJoin("", [
  "[Credentials]\n",
  "aws_access_key_id = ",
  Ref("CfnKeys"),
  "\n",
  "aws_secret_access_key = ",
  FnGetAtt("CfnKeys", "SecretAccessKey"),
  "\n",
  "[Boto]\n",
  "ec2_region_name = ",
  Ref("AWS::Region"),
  "\n",
  "ec2_region_endpoint = ec2.",
  Ref("AWS::Region"),
  ".amazonaws.com\n",
  "elb_region_name = ",
  Ref("AWS::Region"),
  "\n",
  "elb_region_endpoint = elasticloadbalancing.",
  Ref("AWS::Region"),
  ".amazonaws.com\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000600",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/create-keypair" => {
        "content" => FnJoin("", [
  "#!/usr/bin/python\n",
  "import string\n",
  "import random\n",
  "import boto.ec2\n",
  "kp_name = ''.join(random.choice(string.letters) for i in xrange(16))\n",
  "ec2 = boto.ec2.connect_to_region('",
  Ref("AWS::Region"),
  "')\n",
  "keypair = ec2.create_key_pair(kp_name)\n",
  "keypair.save('/home/ec2-user/.ssh/')\n",
  "with file('/home/ec2-user/bees_keypair.txt', 'w') as f:\n",
  "     f.write(kp_name)\n",
  "print 'Created keypair: %s' % kp_name\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000750",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/create-swarm"   => {
        "content" => FnJoin("", [
  "#!/bin/bash\n",
  "/usr/bin/bees up -k `cat /home/ec2-user/bees_keypair.txt` -s ",
  Ref("BeeCount"),
  " -z ",
  FnSelect(1, [
  FnGetAZs("")
]),
  " -g ",
  Ref("BeeSecurityGroup"),
  " --instance ",
  FnFindInMap("AWSRegionPlatform2AMI", Ref("AWS::Region"), "bee"),
  " --login ec2-user\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/delete-keypair" => {
        "content" => FnJoin("", [
  "#!/usr/bin/python\n",
  "import string\n",
  "import random\n",
  "import boto.ec2\n",
  "import os\n",
  "import sys\n",
  "if not os.path.exists('/home/ec2-user/bees_keypair.txt'):\n",
  "     print >> sys.stderr, 'bees_keypair.txt does not exist'\n",
  "     sys.exit(-1)\n",
  "with file('/home/ec2-user/bees_keypair.txt', 'r') as f:\n",
  "     kp_name = f.read().strip()\n",
  "ec2 = boto.ec2.connect_to_region('",
  Ref("AWS::Region"),
  "')\n",
  "ec2.delete_key_pair(kp_name)\n",
  "os.remove('/home/ec2-user/bees_keypair.txt')\n",
  "os.remove('/home/ec2-user/.ssh/%s.pem' % kp_name)\n",
  "print 'Deleted keypair: %s' % kp_name\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000750",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/kill-swarm"     => {
        "content" => FnJoin("", [
  "#!/bin/bash\n",
  "/usr/bin/bees down\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/run-bees"       => {
        "content" => FnJoin("", [
  "#!/bin/bash\n\n",
  "/home/ec2-user/wait-for-elb\n",
  "if [ $? -eq 0 ]\n",
  "then\n",
  "  mkdir /home/ec2-user/swarm-results\n",
  "  /home/ec2-user/create-keypair > /home/ec2-user/swarm-results/create-keypair.log 2>&1\n",
  "  bash /home/ec2-user/create-swarm > /home/ec2-user/swarm-results/create-swarm.log 2>&1\n",
  "  sleep 45 # Allow EC2 instances to fully come up\n",
  "  bash /home/ec2-user/start-swarm > /home/ec2-user/swarm-results/start-swarm.log 2>&1\n",
  "  bash /home/ec2-user/kill-swarm > /home/ec2-user/swarm-results/kill-swarm.log 2>&1\n",
  "  /home/ec2-user/delete-keypair > /home/ec2-user/swarm-results/delete-keypair.log 2>&1\n",
  "  tar cvf /home/ec2-user/swarm-results.tar.gz /home/ec2-user/swarm-results/*\n",
  "  chown ec2-user:ec2-user -R /home/ec2-user/swarm-results\n",
  "  chown ec2-user:ec2-user /home/ec2-user/swarm-results.tar.gz\n",
  "  aws put ",
  Ref("ResultBucket"),
  "/swarm-results.tar.gz /home/ec2-user/swarm-results.tar.gz\n",
  "else\n",
  "  exit 1\n",
  "fi\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/start-swarm"    => {
        "content" => FnJoin("", [
  "#!/bin/bash\n",
  "/usr/bin/bees attack --url http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName"),
  "/",
  " -n ",
  Ref("TotalConnections"),
  " --concurrent ",
  Ref("ConcurrentConnections")
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/tools/aws"      => {
        "group"  => "ec2-user",
        "mode"   => "000755",
        "owner"  => "ec2-user",
        "source" => "https://raw.github.com/timkay/aws/master/aws"
      },
      "/home/ec2-user/wait-for-elb"   => {
        "content" => FnJoin("", [
  "#!/usr/bin/python\n",
  "import boto.ec2.elb\n",
  "import sys\n",
  "import time\n",
  "elb = boto.ec2.elb.ELBConnection()\n",
  "for i in range(120):\n",
  "   if i > 0:\n",
  "      time.sleep(5)\n",
  "   health=elb.describe_instance_health('",
  Ref("ElasticLoadBalancer"),
  "')\n",
  "   healthy_instances = [i for i in health if i.state == 'InService']\n",
  "   if len(healthy_instances) == ",
  Ref("AppInstanceCountDesired"),
  ":\n",
  "      break\n",
  "else:\n",
  "   print >> sys.stderr, 'Gave up waiting for ",
  Ref("AppInstanceCountDesired"),
  "instances.'\n",
  "   sys.exit(1)\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000750",
        "owner"   => "ec2-user"
      },
      "/root/.awssecret"              => {
        "content" => FnJoin("", [
  Ref("CfnKeys"),
  "\n",
  FnGetAtt("CfnKeys", "SecretAccessKey")
]),
        "group"   => "root",
        "mode"    => "000600",
        "owner"   => "root"
      }
    },
    "packages" => {
      "python" => {
        "beeswithmachineguns" => []
      },
      "yum"    => {
        "gcc"             => [],
        "gcc-c++"         => [],
        "gmp-devel"       => [],
        "httpd"           => [],
        "make"            => [],
        "openssl-devel"   => [],
        "python-paramiko" => [],
        "python26-devel"  => []
      }
    }
  }
})
    DependsOn("AppGroup")
    Property("SecurityGroups", [
  Ref("ControllerSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("AWSRegionPlatform2AMI", Ref("AWS::Region"), "amzn"))
    Property("InstanceType", Ref("BeesControllerInstanceType"))
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "bees-controller"
  }
])
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init -v -s ",
  Ref("AWS::StackName"),
  " -r BeeController --access-key ",
  Ref("CfnKeys"),
  " --secret-key ",
  FnGetAtt("CfnKeys", "SecretAccessKey"),
  " --region ",
  Ref("AWS::Region"),
  "\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("ControllerHandle"),
  "'\n"
])))
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "InstanceProtocol" => "HTTP",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "2",
  "Interval"           => "30",
  "Target"             => "HTTP:80/",
  "Timeout"            => "5",
  "UnhealthyThreshold" => "10"
})
  end

  Resource("AppGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", Ref("AppInstanceCountMin"))
    Property("MaxSize", Ref("AppInstanceCountMax"))
    Property("DesiredCapacity", Ref("AppInstanceCountDesired"))
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "packages" => {
      "yum" => {
        "nginx" => []
      }
    },
    "services" => {
      "sysvinit" => {
        "nginx" => {
          "enabled"       => "true",
          "ensureRunning" => "true",
          "packages"      => {
            "yum" => [
              "nginx"
            ]
          }
        }
      }
    }
  }
})
    Property("SpotPrice", Ref("SpotPrice"))
    Property("ImageId", FnFindInMap("AWSRegionPlatform2AMI", Ref("AWS::Region"), "amzn"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init -v -s ",
  Ref("AWS::StackName"),
  " -r LaunchConfig --access-key ",
  Ref("CfnKeys"),
  " --secret-key ",
  FnGetAtt("CfnKeys", "SecretAccessKey"),
  " --region ",
  Ref("AWS::Region"),
  "\n"
])))
    Property("SecurityGroups", [
  Ref("AppSecurityGroup")
])
    Property("InstanceType", Ref("AppInstanceType"))
    Property("KeyName", Ref("KeyName"))
  end

  Resource("ControllerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("BeeSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access and HTTP access on the inbound port")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                => "22",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("ControllerSecurityGroup"),
    "ToPort"                  => "22"
  }
])
  end

  Resource("AppSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable tcp access on the inbound port for ELB and SSH from outside")
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

  Resource("ControllerHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("ControllerCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("BeeController")
    Property("Handle", Ref("ControllerHandle"))
    Property("Timeout", "900")
  end

  Output("WebsiteURL") do
    Description("URL of website under test")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end

  Output("BeeControllerAddress") do
    Description("Public address of the bees controller")
    Value(FnGetAtt("BeeController", "PublicDnsName"))
  end

  Output("TestResultsURL") do
    Description("URL of Results file")
    Value(FnJoin("", [
  "https://",
  FnGetAtt("ResultBucket", "DomainName"),
  "/swarm-results.tar.gz"
]))
  end
end

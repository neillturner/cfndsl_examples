CloudFormation do
  Description("Sample template to bring up an Auto Scaling group running an application deployed via Opscode Chef solo. This template is a building block template, designed to be called from a parent template. A WaitCondition is used to hold up the stack creation until the application is deployed. **WARNING** This template creates one or more Amazon EC2 instances and CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
    Type("String")
  end

  Parameter("RecipeURL") do
    Description("The location of the recipe tarball")
    Type("String")
  end

  Parameter("EC2SecurityGroup") do
    Description("The EC2 security group that contains instances that need access to the database")
    Type("String")
    Default("default")
  end

  Parameter("StackNameOrId") do
    Description("The StackName or StackId containing the resource with the Chef configuration metadata")
    Type("String")
    MaxLength(128)
    MinLength(1)
  end

  Parameter("ResourceName") do
    Description("The Logical Resource Name in the stack defined by StackName containing the resource with the Chef configuration metadata")
    Type("String")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(128)
    MinLength(1)
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

  Parameter("WebServerPort") do
    Description("Port for web servers to listen on")
    Type("Number")
    Default("8888")
  end

  Parameter("AlarmTopic") do
    Description("SNS topic to notify if there are operational issues")
    Type("String")
  end

  Parameter("DesiredCapacity") do
    Description("Port for web servers to listen on")
    Type("Number")
    Default("1")
    MaxValue(6)
    MinValue(1)
  end

  Parameter("HealthCheckPath") do
    Description("Elastic Load Balancing HealthCheck path")
    Type("String")
    Default("/")
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
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("Listeners", [
  {
    "InstancePort"     => Ref("WebServerPort"),
    "LoadBalancerPort" => "80",
    "PolicyNames"      => [
      "p1"
    ],
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "2",
  "Interval"           => "10",
  "Target"             => FnJoin("", [
  "HTTP:",
  Ref("WebServerPort"),
  Ref("HealthCheckPath")
]),
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
    Property("AvailabilityZones", FnGetAZs(Ref("AWS::Region")))
    Property("LBCookieStickinessPolicy", [
  {
    "CookieExpirationPeriod" => "30",
    "PolicyName"             => "p1"
  }
])
  end

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("AvailabilityZones", FnGetAZs(Ref("AWS::Region")))
    Property("MinSize", "1")
    Property("MaxSize", "6")
    Property("DesiredCapacity", Ref("DesiredCapacity"))
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("AWS::CloudFormation::Init", {
  "chefversion" => {
    "files"    => {
      "/etc/chef/solo.rb" => {
        "content" => FnJoin("", [
  "log_level :info\n",
  "log_location STDOUT\n",
  "file_cache_path \"/var/chef-solo\"\n",
  "cookbook_path \"/var/chef-solo/cookbooks\"\n",
  "json_attribs \"/etc/chef/node.json\"\n",
  "recipe_url \"",
  Ref("RecipeURL"),
  "\"\n"
]),
        "group"   => "wheel",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "rubygems" => {
        "chef" => [
          "10.18.2"
        ]
      },
      "yum"      => {
        "autoconf"   => [],
        "automake"   => [],
        "gcc-c++"    => [],
        "make"       => [],
        "ruby-devel" => [],
        "rubygems"   => []
      }
    }
  },
  "configSets"  => {
    "orderby" => [
      "gems",
      "chefversion"
    ]
  },
  "gems"        => {
    "packages" => {
      "rubygems" => {
        "net-ssh"         => [
          "2.2.2"
        ],
        "net-ssh-gateway" => [
          "1.1.0"
        ]
      }
    }
  }
})
    Property("SecurityGroups", [
  Ref("EC2SecurityGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "function error_exit\n",
  "{\n",
  "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
  Ref("WaitHandle"),
  "'\n",
  "  exit 1\n",
  "}\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r LaunchConfig ",
  " -c order ",
  "         --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to initialize Chef Solo'\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r ",
  Ref("ResourceName"),
  "         --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to configure the application'\n",
  "chef-solo\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("WaitHandle"),
  "'\n"
])))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("WaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServerGroup")
    Property("Handle", Ref("WaitHandle"))
    Property("Count", Ref("DesiredCapacity"))
    Property("Timeout", "600")
  end

  Resource("LockInstancesDown") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("EC2SecurityGroup"))
    Property("IpProtocol", "tcp")
    Property("FromPort", Ref("WebServerPort"))
    Property("ToPort", Ref("WebServerPort"))
    Property("SourceSecurityGroupOwnerId", FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"))
    Property("SourceSecurityGroupName", FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"))
  end

  Resource("CPUAlarmHigh") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if aggregate CPU too high ie. > 90% for 5 minutes")
    Property("Namespace", "AWS/EC2")
    Property("MetricName", "CPUUtilization")
    Property("Statistic", "Average")
    Property("Dimensions", [
  {
    "Name"  => "AutoScalingGroupName",
    "Value" => Ref("WebServerGroup")
  }
])
    Property("Period", "60")
    Property("Threshold", "90")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("EvaluationPeriods", "1")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
  end

  Resource("TooManyUnhealthyHostsAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if there are any unhealthy hosts.")
    Property("Namespace", "AWS/ELB")
    Property("MetricName", "UnHealthyHostCount")
    Property("Statistic", "Average")
    Property("Dimensions", [
  {
    "Name"  => "LoadBalancerName",
    "Value" => Ref("ElasticLoadBalancer")
  }
])
    Property("Period", "300")
    Property("EvaluationPeriods", "1")
    Property("Threshold", "0")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
  end

  Resource("RequestLatencyAlarmHigh") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if request latency > ")
    Property("Namespace", "AWS/ELB")
    Property("MetricName", "Latency")
    Property("Dimensions", [
  {
    "Name"  => "LoadBalancerName",
    "Value" => Ref("ElasticLoadBalancer")
  }
])
    Property("Statistic", "Average")
    Property("Period", "300")
    Property("EvaluationPeriods", "1")
    Property("Threshold", "1")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
  end

  Output("URL") do
    Description("Website URL")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName"),
  "/"
]))
  end
end

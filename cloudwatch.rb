CloudFormation do
  Description("AWS CloudFormation Sample Template for CloudWatch Logs.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("AWS::EC2::KeyPair::KeyName")
    ConstraintDescription("must be the name of an existing EC2 KeyPair.")
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

  Parameter("OperatorEmail") do
    Description("Email address to notify if there are any scaling operations")
    Type("String")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI" => "ami-c9562fc8"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-b40d5ee6"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-3b4bd301"
  },
  "eu-central-1"   => {
    "AMI" => "ami-a03503bd"
  },
  "eu-west-1"      => {
    "AMI" => "ami-2918e35e"
  },
  "sa-east-1"      => {
    "AMI" => "ami-215dff3c"
  },
  "us-east-1"      => {
    "AMI" => "ami-fb8e9292"
  },
  "us-west-1"      => {
    "AMI" => "ami-7aba833f"
  },
  "us-west-2"      => {
    "AMI" => "ami-043a5034"
  }
})

  Resource("LogRole") do
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
  ],
  "Version"   => "2012-10-17"
})
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "logs:*",
            "s3:GetObject"
          ],
          "Effect"   => "Allow",
          "Resource" => [
            "arn:aws:logs:*:*:*",
            "arn:aws:s3:::*"
          ]
        }
      ],
      "Version"   => "2012-10-17"
    },
    "PolicyName"     => "LogRolePolicy"
  }
])
  end

  Resource("LogRoleInstanceProfile") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("LogRole")
])
  end

  Resource("WebServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access via port 80 and SSH access via port 22")
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

  Resource("WebServerHost") do
    Type("AWS::EC2::Instance")
    CreationPolicy("ResourceSignal", {
  "Timeout" => "PT5M"
})
    Metadata("Comment", "Install a simple PHP application")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/cfn/cfn-hup.conf"                   => {
        "content" => FnJoin("", [
  "[main]\n",
  "stack=",
  Ref("AWS::StackId"),
  "\n",
  "region=",
  Ref("AWS::Region"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000400",
        "owner"   => "root"
      },
      "/etc/cfn/hooks.d/cfn-auto-reloader.conf" => {
        "content" => FnJoin("", [
  "[cfn-auto-reloader-hook]\n",
  "triggers=post.update\n",
  "path=Resources.WebServerHost.Metadata.AWS::CloudFormation::Init\n",
  "action=/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServerHost ",
  " --region     ",
  Ref("AWS::Region"),
  "\n",
  "runas=root\n"
])
      },
      "/tmp/cwlogs/apacheaccess.conf"           => {
        "content" => FnJoin("", [
  "[general]\n",
  "state_file= /var/awslogs/agent-state\n",
  "[/var/log/httpd/access_log]\n",
  "file = /var/log/httpd/access_log\n",
  "log_group_name = ",
  Ref("WebServerLogGroup"),
  "\n",
  "log_stream_name = {instance_id}/apache.log\n",
  "datetime_format = %d/%b/%Y:%H:%M:%S"
]),
        "group"   => "apache",
        "mode"    => "000400",
        "owner"   => "apache"
      },
      "/var/www/html/index.php"                 => {
        "content" => FnJoin("", [
  "<?php\n",
  "echo '<h1>AWS CloudFormation sample PHP application</h1>';\n",
  "?>\n"
]),
        "group"   => "apache",
        "mode"    => "000644",
        "owner"   => "apache"
      }
    },
    "packages" => {
      "yum" => {
        "httpd" => [],
        "php"   => []
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
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", "t1.micro")
    Property("SecurityGroups", [
  Ref("WebServerSecurityGroup")
])
    Property("IamInstanceProfile", Ref("LogRoleInstanceProfile"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -xe\n",
  "# Get the latest CloudFormation package\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Start cfn-init\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServerHost ",
  " --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Start up the cfn-hup daemon to listen for changes to the EC2 instance metadata\n",
  "/opt/aws/bin/cfn-hup || error_exit 'Failed to start cfn-hup'\n",
  "# Get the CloudWatch Logs agent\n",
  "wget https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py\n",
  "# Install the CloudWatch Logs agent\n",
  "python awslogs-agent-setup.py -n -r ",
  Ref("AWS::Region"),
  " -c /tmp/cwlogs/apacheaccess.conf || error_exit 'Failed to run CloudWatch Logs agent setup'\n",
  "# All done so signal success\n",
  "/opt/aws/bin/cfn-signal -e $? ",
  "         --stack ",
  Ref("AWS::StackName"),
  "         --resource WebServerHost ",
  "         --region ",
  Ref("AWS::Region"),
  "\n"
])))
  end

  Resource("WebServerLogGroup") do
    Type("AWS::Logs::LogGroup")
    Property("RetentionInDays", 7)
  end

  Resource("404MetricFilter") do
    Type("AWS::Logs::MetricFilter")
    Property("LogGroupName", Ref("WebServerLogGroup"))
    Property("FilterPattern", "[ip, identity, user_id, timestamp, request, status_code = 404, size, ...]")
    Property("MetricTransformations", [
  {
    "MetricName"      => "test404Count",
    "MetricNamespace" => "test/404s",
    "MetricValue"     => "1"
  }
])
  end

  Resource("BytesTransferredMetricFilter") do
    Type("AWS::Logs::MetricFilter")
    Property("LogGroupName", Ref("WebServerLogGroup"))
    Property("FilterPattern", "[ip, identity, user_id, timestamp, request, status_code, size, ...]")
    Property("MetricTransformations", [
  {
    "MetricName"      => "testBytesTransferred",
    "MetricNamespace" => "test/BytesTransferred",
    "MetricValue"     => "$size"
  }
])
  end

  Resource("404Alarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "The number of 404s is greater than 2 over 2 minutes")
    Property("MetricName", "test404Count")
    Property("Namespace", "test/404s")
    Property("Statistic", "Sum")
    Property("Period", "60")
    Property("EvaluationPeriods", "2")
    Property("Threshold", "2")
    Property("AlarmActions", [
  Ref("AlarmNotificationTopic")
])
    Property("Unit", "Count")
    Property("ComparisonOperator", "GreaterThanThreshold")
  end

  Resource("BandwidthAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "The average volume of traffic is greater 3500 KB over 10 minutes")
    Property("MetricName", "testBytesTransferred")
    Property("Namespace", "test/BytesTransferred")
    Property("Statistic", "Average")
    Property("Period", "300")
    Property("EvaluationPeriods", "2")
    Property("Threshold", "3500")
    Property("AlarmActions", [
  Ref("AlarmNotificationTopic")
])
    Property("Unit", "Kilobytes")
    Property("ComparisonOperator", "GreaterThanThreshold")
  end

  Resource("AlarmNotificationTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => Ref("OperatorEmail"),
    "Protocol" => "email"
  }
])
  end

  Output("InstanceId") do
    Description("The instance ID of the web server")
    Value(Ref("WebServerHost"))
  end

  Output("WebsiteURL") do
    Description("URL for newly created LAMP stack")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServerHost", "PublicDnsName")
]))
  end

  Output("PublicIP") do
    Description("Public IP address of the web server")
    Value(FnGetAtt("WebServerHost", "PublicIp"))
  end

  Output("CloudWatchLogGroupName") do
    Description("The name of the CloudWatch log group")
    Value(Ref("WebServerLogGroup"))
  end
end

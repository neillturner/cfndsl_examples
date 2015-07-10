CloudFormation do
  Description("AWS CloudFormation Sample Template WorkerRole: Create a multi-az, Auto Scaled worker that pulls command messages from a queue and execs the command. Each message contains a command/script to run, an input file location and an output location for the results. The application is Auto-Scaled based on the amount of work in the queue. **WARNING** This template creates one or more Amazon EC2 instances and an Amazon SQS queue. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("InstanceType") do
    Description("Worker EC2 instance type")
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

  Parameter("KeyName") do
    Description("The EC2 Key Pair to allow SSH access to the instances")
    Type("String")
  end

  Parameter("MinInstances") do
    Description("The minimum number of Workers")
    Type("Number")
    Default("0")
    MinValue(0)
    ConstraintDescription("Enter a number >=0")
  end

  Parameter("MaxInstances") do
    Description("The maximum number of Workers")
    Type("Number")
    Default("1")
    MinValue(1)
    ConstraintDescription("Enter a number >1")
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

  Resource("WorkerUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "cloudformation:DescribeStackResource",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sns:Publish"
          ],
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("InputQueue") do
    Type("AWS::SQS::Queue")
  end

  Resource("InputQueuePolicy") do
    Type("AWS::SQS::QueuePolicy")
    DependsOn("LaunchConfig")
    Property("Queues", [
  Ref("InputQueue")
])
    Property("PolicyDocument", {
  "Id"        => "ReadFromQueuePolicy",
  "Statement" => [
    {
      "Action"    => [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("WorkerUser", "Arn")
      },
      "Resource"  => FnGetAtt("InputQueue", "Arn"),
      "Sid"       => "ConsumeMessages"
    }
  ],
  "Version"   => "2008-10-17"
})
  end

  Resource("InstanceSecurityGroup") do
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

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("Comment", "Install a simple PHP application")
    Metadata("AWS::CloudFormation::Init", {
  "AmazonLibraries" => {
    "sources" => {
      "/home/ec2-user/sqs" => "http://s3.amazonaws.com/awscode/amazon-queue/2009-02-01/perl/library/amazon-queue-2009-02-01-perl-library.zip"
    }
  },
  "LWP"             => {
    "packages" => {
      "yum" => {
        "perl-Time-HiRes" => []
      }
    }
  },
  "Time"            => {
    "packages" => {
      "yum" => {
        "perl-LWP-Protocol-https" => []
      }
    }
  },
  "WorkerRole"      => {
    "files" => {
      "/etc/cron.d/worker.cron"  => {
        "content" => "*/1 * * * * ec2-user /home/ec2-user/worker.pl &> /home/ec2-user/worker.log\n",
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/home/ec2-user/worker.pl" => {
        "content" => FnJoin("", [
  "#!/usr/bin/perl -w\n",
  "#\n",
  "use strict;\n",
  "use Carp qw( croak );\n",
  "use lib qw(/home/ec2-user/sqs/amazon-queue-2009-02-01-perl-library/src);  \n",
  "use LWP::Simple qw( getstore );\n",
  "\n",
  "my $QUEUE_NAME            = \"",
  Ref("InputQueue"),
  "\";\n",
  "my $COMMAND_FILE          = \"/home/ec2-user/command\";\n",
  "\n",
  "eval {\n",
  "\n",
  "  use Amazon::SQS::Client; \n",
  "  my $service = Amazon::SQS::Client->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);\n",
  " \n",
  "  my $response = $service->receiveMessage({QueueUrl=>$QUEUE_NAME, MaxNumberOfMessages=>1});\n",
  "  if ($response->isSetReceiveMessageResult) {\n",
  "    my $result = $response->getReceiveMessageResult();\n",
  "    if ($result->isSetMessage) {\n",
  "      my $messageList = $response->getReceiveMessageResult()->getMessage();\n",
  "      foreach(@$messageList) {\n",
  "        my $message = $_;\n",
  "        my $messageHandle = 0;\n",
  "        if ($message->isSetReceiptHandle()) {\n",
  "          $messageHandle = $message->getReceiptHandle();\n",
  "        } else {\n",
  "          croak \"Couldn't get message Id from message\";\n",
  "        }\n",
  "        if ($message->isSetBody()) {\n",
  "          my %parameters = split(/[=;]/, $message->getBody());\n",
  "          if (defined($parameters{\"Input\"}) && defined($parameters{\"Output\"}) && defined($parameters{\"Command\"})) {\n",
  "            getstore($parameters{\"Command\"}, $COMMAND_FILE);\n",
  "            chmod(0755, $COMMAND_FILE);\n",
  "            my $command = $COMMAND_FILE . \" \" . $parameters{\"Input\"} . \" \" . $parameters{\"Output\"};\n",
  "            my $result = `$command`;\n",
  "            print \"Result = \" . $result . \"\\n\";\n",
  "          } else {\n",
  "            croak \"Invalid message\";\n",
  "          }\n",
  "        } else {\n",
  "          croak \"Couldn't get message body from message\";\n",
  "        }\n",
  "        my $response = $service->deleteMessage({QueueUrl=>$QUEUE_NAME, ReceiptHandle=>$messageHandle});\n",
  "      }\n",
  "    } else {\n",
  "      printf \"Empty Poll\\n\";\n",
  "    }\n",
  "  } else {\n",
  "    croak \"Call failed\";\n",
  "  }\n",
  "}; \n",
  "\n",
  "my $ex = $@;\n",
  "if ($ex) {\n",
  "  require Amazon::SQS::Exception;\n",
  "  if (ref $ex eq \"Amazon::SQS::Exception\") {\n",
  "    print(\"Caught Exception: \" . $ex->getMessage() . \"\\n\");\n",
  "  } else {\n",
  "    croak $@;\n",
  "  }\n",
  "}\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      }
    }
  },
  "XML"             => {
    "packages" => {
      "yum" => {
        "perl-XML-Simple" => []
      }
    }
  },
  "configSets"      => {
    "ALL" => [
      "XML",
      "Time",
      "LWP",
      "AmazonLibraries",
      "WorkerRole"
    ]
  }
})
    Property("KeyName", Ref("KeyName"))
    Property("SpotPrice", "0.05")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", Ref("InstanceType"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Install the Worker application\n",
  "/opt/aws/bin/cfn-init ",
  "         --stack ",
  Ref("AWS::StackId"),
  "         --resource LaunchConfig ",
  "         --configset ALL",
  "         --region ",
  Ref("AWS::Region"),
  "\n"
])))
  end

  Resource("WorkerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", Ref("MinInstances"))
    Property("MaxSize", Ref("MaxInstances"))
  end

  Resource("WorkerScaleUpPolicy") do
    Type("AWS::AutoScaling::ScalingPolicy")
    Property("AdjustmentType", "ChangeInCapacity")
    Property("AutoScalingGroupName", Ref("WorkerGroup"))
    Property("Cooldown", "60")
    Property("ScalingAdjustment", "1")
  end

  Resource("WorkerScaleDownPolicy") do
    Type("AWS::AutoScaling::ScalingPolicy")
    Property("AdjustmentType", "ChangeInCapacity")
    Property("AutoScalingGroupName", Ref("WorkerGroup"))
    Property("Cooldown", "60")
    Property("ScalingAdjustment", "-1")
  end

  Resource("TooManyMessagesAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Scale-Up if queue depth grows beyond 10 messages")
    Property("Namespace", "AWS/SQS")
    Property("MetricName", "ApproximateNumberOfMessagesVisible")
    Property("Dimensions", [
  {
    "Name"  => "QueueName",
    "Value" => FnGetAtt("InputQueue", "QueueName")
  }
])
    Property("Statistic", "Sum")
    Property("Period", "60")
    Property("EvaluationPeriods", "3")
    Property("Threshold", "1")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("WorkerScaleUpPolicy")
])
  end

  Resource("NotEnoughMessagesAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Scale-down if there are too many empty polls, indicating there is not enough work")
    Property("Namespace", "AWS/SQS")
    Property("MetricName", "NumberOfEmptyReceives")
    Property("Dimensions", [
  {
    "Name"  => "QueueName",
    "Value" => FnGetAtt("InputQueue", "QueueName")
  }
])
    Property("Statistic", "Sum")
    Property("Period", "60")
    Property("EvaluationPeriods", "10")
    Property("Threshold", "3")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("WorkerScaleDownPolicy")
])
  end

  Output("QueueURL") do
    Description("URL of input queue")
    Value(Ref("InputQueue"))
  end
end

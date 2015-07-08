CloudFormation do
  Description("Single EC2 m1.large producer-consumer processing (single operation API) 1K messages for the specified duration")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("DurationMinutes") do
    Description("Run duration in minutes (max 60)")
    Type("Number")
    Default("20")
    MaxValue(60)
    MinValue(1)
    ConstraintDescription("must be number >= 1 and <= 60.")
  end

  Parameter("TerminateEC2Inst") do
    Description("Terminate the producer-consumer EC2 instance once the run is complete?")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be either true or false")
  end

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the producer-consumer instance")
    Type("String")
    AllowedPattern("[-_ a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("can contain only alphanumeric characters, spaces, dashes and underscores.")
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
    "Arch" => "32"
  },
  "c1.xlarge"   => {
    "Arch" => "64"
  },
  "cc1.4xlarge" => {
    "Arch" => "64"
  },
  "m1.large"    => {
    "Arch" => "64"
  },
  "m1.small"    => {
    "Arch" => "32"
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
    "Arch" => "32"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32" => "ami-2a19aa2b",
    "64" => "ami-2819aa29"
  },
  "ap-southeast-1" => {
    "32" => "ami-220b4a70",
    "64" => "ami-3c0b4a6e"
  },
  "ap-southeast-2" => {
    "32" => "ami-b3990e89",
    "64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "32" => "ami-61555115",
    "64" => "ami-6d555119"
  },
  "sa-east-1"      => {
    "32" => "ami-f836e8e5",
    "64" => "ami-fe36e8e3"
  },
  "us-east-1"      => {
    "32" => "ami-a0cd60c9",
    "64" => "ami-aecd60c7"
  },
  "us-west-1"      => {
    "32" => "ami-7d4c6938",
    "64" => "ami-734c6936"
  },
  "us-west-2"      => {
    "32" => "ami-46da5576",
    "64" => "ami-48da5578"
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
          "Action"   => "SQS:*",
          "Effect"   => "Allow",
          "Resource" => FnGetAtt("SqsQueue", "Arn")
        },
        {
          "Action"   => "EC2:TerminateInstances",
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("HostKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("CfnUser"))
  end

  Resource("SqsQueue") do
    Type("AWS::SQS::Queue")
  end

  Resource("SqsPerfSecurityGroup") do
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

  Resource("ProducerConsumer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "sources" => {
      "/tmp/sqs-producer-consumer-sample" => "https://s3.amazonaws.com/cloudformation-examples/sqs-producer-consumer-sample.tar"
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", "m1.large", "Arch")))
    Property("InstanceType", "m1.large")
    Property("SecurityGroups", [
  Ref("SqsPerfSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "# Install the perf sample\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r ProducerConsumer ",
  "    --region ",
  Ref("AWS::Region"),
  "\n",
  "mkdir /cgi-bin",
  "\n",
  "cp /tmp/sqs-producer-consumer-sample/scripts/log.sh /cgi-bin",
  "\n",
  "chmod a+x /cgi-bin/log.sh",
  "\n",
  "echo /tmp/sqs-producer-consumer-sample/scripts/run.sh ",
  Ref("HostKeys"),
  " ",
  FnGetAtt("HostKeys", "SecretAccessKey"),
  " ",
  Ref("AWS::Region"),
  " ",
  FnGetAtt("SqsQueue", "QueueName"),
  " ",
  Ref("DurationMinutes"),
  " > /tmp/sqs-producer-consumer-sample/command.log 2>&1 &",
  "\n",
  "nohup /tmp/sqs-producer-consumer-sample/scripts/run.sh ",
  Ref("HostKeys"),
  " ",
  FnGetAtt("HostKeys", "SecretAccessKey"),
  " ",
  Ref("AWS::Region"),
  " ",
  FnGetAtt("SqsQueue", "QueueName"),
  " ",
  Ref("DurationMinutes"),
  " ",
  Ref("TerminateEC2Inst"),
  " > /tmp/sqs-producer-consumer-sample/output.log 2>&1 &",
  "\n"
])))
  end

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("ProducerConsumer"))
  end

  Output("AZ") do
    Description("Availability Zone of the newly created EC2 instance")
    Value(FnGetAtt("ProducerConsumer", "AvailabilityZone"))
  end

  Output("PublicIP") do
    Description("Public IP address of the newly created EC2 instance")
    Value(FnGetAtt("ProducerConsumer", "PublicIp"))
  end

  Output("PrivateIP") do
    Description("Private IP address of the newly created EC2 instance")
    Value(FnGetAtt("ProducerConsumer", "PrivateIp"))
  end
end

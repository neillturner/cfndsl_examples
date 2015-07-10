CloudFormation do
  Description("AWS CloudFormation Sample Template MonitorEC2AndEBS: Create an EC2 instance running the Amazon Linux AMI with a new EBS volume attached. The Instance is configured for detailed monitoring. Both the instance and the volume have CloudWatch alarms configured to notify an email address of an operational issues. The AMI is chosen based on the region in which the stack is run. You will get a notification to the email address you specify indicating that a new email subscription has been created. **WARNING** This template creates an Amazon EC2 instance and one or more Amazon CloudWatch Alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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

  Parameter("OperatorEmail") do
    Description("EMail address to notify if there are any operational issues")
    Type("String")
    Default("nobody@amazon.com")
  end

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instance")
    Type("String")
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

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("Monitoring", "true")
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

  Resource("NewVolume") do
    Type("AWS::EC2::Volume")
    Property("Size", "100")
    Property("AvailabilityZone", FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end

  Resource("MountPoint") do
    Type("AWS::EC2::VolumeAttachment")
    Property("InstanceId", Ref("Ec2Instance"))
    Property("VolumeId", Ref("NewVolume"))
    Property("Device", "/dev/sdk")
  end

  Resource("CPUAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if CPU too high or metric disappears indicating instance is down")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
    Property("InsufficientDataActions", [
  Ref("AlarmTopic")
])
    Property("MetricName", "CPUUtilization")
    Property("Namespace", "AWS/EC2")
    Property("Statistic", "Average")
    Property("Period", "60")
    Property("EvaluationPeriods", "3")
    Property("Threshold", "90")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("Dimensions", [
  {
    "Name"  => "InstanceId",
    "Value" => Ref("Ec2Instance")
  }
])
  end

  Resource("DiskIOBoundAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if disk is running at IO capacity")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
    Property("InsufficientDataActions", [
  Ref("AlarmTopic")
])
    Property("MetricName", "VolumeIdleTime")
    Property("Namespace", "AWS/EBS")
    Property("Statistic", "Average")
    Property("Period", "60")
    Property("EvaluationPeriods", "3")
    Property("Threshold", "5")
    Property("ComparisonOperator", "LessThanOrEqualToThreshold")
    Property("Dimensions", [
  {
    "Name"  => "VolumeId",
    "Value" => Ref("NewVolume")
  }
])
  end

  Resource("AlarmTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => Ref("OperatorEmail"),
    "Protocol" => "email"
  }
])
  end

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("Ec2Instance"))
  end

  Output("PublicIP") do
    Description("Public IP address of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicIp"))
  end

  Output("PublicDNS") do
    Description("Public DNSName of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicDnsName"))
  end
end

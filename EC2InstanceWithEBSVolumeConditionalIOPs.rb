CloudFormation do
  Description("AWS CloudFormation Sample Template EC2InstanceWithEBSVolumeConditionalIOPs: Example to show how to create an EC2 instance with an optionally attached volume. The instance is EBS Optimized and the volume is a PIOPs volume if the EC2 instance type supports it. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
    Type("String")
  end

  Parameter("SSHFrom") do
    Description("Lockdown SSH access to the bastion host (default can be accessed from anywhere)")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid CIDR range of the form x.x.x.x/x.")
  end

  Parameter("EBSVolumeDeviceName") do
    Description("Device name to attach an EBS volume (Default no EBS volume attached)")
    Type("String")
    Default("No Volume")
  end

  Parameter("VolumeSize") do
    Description("Size of the EBS volume if attached")
    Type("Number")
    Default("100")
    MaxValue(1000)
    MinValue(1)
  end

  Parameter("IOPs") do
    Description("Provisioned IOPs for EBS volume if supported by the instance type")
    Type("Number")
    Default("100")
    MaxValue(30000)
    MinValue(1)
  end

  Mapping("InstanceConfig", {
  "c1.medium"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "c1.xlarge"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "cc2.8xlarge" => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "cg1.4xlarge" => {
    "Arch"         => "GPU64",
    "EBSOptimized" => "false"
  },
  "cr1.8xlarge" => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "g2.2xlarge"  => {
    "Arch"         => "GPU64",
    "EBSOptimized" => "true"
  },
  "hi1.4xlarge" => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "hs1.8xlarge" => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "m1.large"    => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "m1.medium"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "m1.small"    => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "m1.xlarge"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "m2.2xlarge"  => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "m2.4xlarge"  => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "m2.xlarge"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  },
  "m3.2xlarge"  => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "m3.xlarge"   => {
    "Arch"         => "PV64",
    "EBSOptimized" => "true"
  },
  "t1.micro"    => {
    "Arch"         => "PV64",
    "EBSOptimized" => "false"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-0961fe08",
    "PV64"  => "ami-3561fe34"
  },
  "ap-southeast-1" => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-6af2b938",
    "PV64"  => "ami-14f2b946"
  },
  "ap-southeast-2" => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-a948d593",
    "PV64"  => "ami-a148d59b"
  },
  "eu-west-1"      => {
    "GPU64" => "ami-2c9f785b",
    "HVM64" => "ami-209f7857",
    "PV64"  => "ami-149f7863"
  },
  "sa-east-1"      => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-9d6ec980",
    "PV64"  => "ami-9f6ec982"
  },
  "us-east-1"      => {
    "GPU64" => "ami-7f792c16",
    "HVM64" => "ami-69792c00",
    "PV64"  => "ami-35792c5c"
  },
  "us-gov-west-1"  => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-cfef8bec",
    "PV64"  => "ami-cdef8bee"
  },
  "us-west-1"      => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-4e7b4f0b",
    "PV64"  => "ami-687b4f2d"
  },
  "us-west-2"      => {
    "GPU64" => "NOT_YET_SUPPORTED",
    "HVM64" => "ami-e43ea1d4",
    "PV64"  => "ami-d03ea1e0"
  }
})

  Condition("IsEBSOptimized", FnEquals(FnFindInMap("InstanceConfig", Ref("InstanceType"), "EBSOptimized"), "true"))

  Condition("AttachVolume", FnNot([
  FnEquals(Ref("EBSVolumeDeviceName"), "No Volume")
]))

  Resource("EC2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("InstanceConfig", Ref("InstanceType"), "Arch")))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("Ec2SecurityGroup")
])
    Property("EbsOptimized", FnIf("IsEBSOptimized", "true", "false"))
  end

  Resource("Ec2SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "HTTP and SSH access")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHFrom"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("EBSVolume") do
    Type("AWS::EC2::Volume")
    Condition("AttachVolume")
    Property("Size", Ref("VolumeSize"))
    Property("AvailabilityZone", FnGetAtt("EC2Instance", "AvailabilityZone"))
    Property("VolumeType", FnIf("IsEBSOptimized", "io1", Ref("AWS::NoValue")))
    Property("Iops", FnIf("IsEBSOptimized", Ref("IOPs"), Ref("AWS::NoValue")))
  end

  Resource("EBSVolumeAttachment") do
    Type("AWS::EC2::VolumeAttachment")
    Condition("AttachVolume")
    Property("Device", Ref("EBSVolumeDeviceName"))
    Property("InstanceId", Ref("EC2Instance"))
    Property("VolumeId", Ref("EBSVolume"))
  end

  Output("Instance") do
    Description("DNS Name of the newly created EC2 instance")
    Value(FnGetAtt("EC2Instance", "PublicDnsName"))
  end

  Output("Device") do
    Condition("AttachVolume")
    Description("Device name for the attached volume")
    Value(Ref("EBSVolumeDeviceName"))
  end

  Output("EBSOptimized") do
    Condition("AttachVolume")
    Description("Is the attached volume a PIOPs volume")
    Value(FnFindInMap("InstanceConfig", Ref("InstanceType"), "EBSOptimized"))
  end

  Output("IOPs") do
    Condition("IsEBSOptimized")
    Description("IOPs configured for attached volume")
    Value(Ref("IOPs"))
  end
end

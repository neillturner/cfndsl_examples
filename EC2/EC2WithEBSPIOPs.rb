CloudFormation do
  Description("AWS CloudFormation Sample Template EC2WithEBSPIOPs: Create an Amazon EC2 instance running the Amazon Linux AMI with a new EBS volume attached that has provisioned IOPs. The instance and the volume are pinned to the same availability zone. We recommend that you do untargeted launches rather than pinning instances this way.The AMI is chosen based on the region in which the stack is run. **WARNING** This template creates an Amazon EC2 instance and an EBS Volume. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instance")
    Type("String")
  end

  Parameter("SSHFrom") do
    Description("Lockdown SSH access (default can be accessed from anywhere)")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid CIDR range of the form x.x.x.x/x.")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI" => "ami-2819aa29"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-3c0b4a6e"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "AMI" => "ami-6d555119"
  },
  "sa-east-1"      => {
    "AMI" => "ami-fe36e8e3"
  },
  "us-east-1"      => {
    "AMI" => "ami-aecd60c7"
  },
  "us-west-1"      => {
    "AMI" => "ami-734c6936"
  },
  "us-west-2"      => {
    "AMI" => "ami-48da5578"
  }
})

  Resource("EC2Instance") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", "m1.large")
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("EbsOptimized", "true")
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHFrom"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("MountPoint") do
    Type("AWS::EC2::VolumeAttachment")
    Property("InstanceId", Ref("EC2Instance"))
    Property("VolumeId", Ref("NewVolume"))
    Property("Device", "/dev/sdh")
  end

  Resource("NewVolume") do
    Type("AWS::EC2::Volume")
    Property("Size", "100")
    Property("VolumeType", "io1")
    Property("Iops", "100")
    Property("AvailabilityZone", FnGetAtt("EC2Instance", "AvailabilityZone"))
  end

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("EC2Instance"))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template EC2WithEBSSample: Create an Amazon EC2 instance running the Amazon Linux AMI with a new EBS volume attached. The instance and the volume are pinned to the same availability zone. We recommend that you do untargeted launches rather than pinning instances this way.The AMI is chosen based on the region in which the stack is run. **WARNING** This template creates an Amazon EC2 instance and an EBS Volume. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instance")
    Type("String")
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

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI"    => "ami-dcfa4edd",
    "TestAz" => "ap-northeast-1a"
  },
  "ap-southeast-1" => {
    "AMI"    => "ami-74dda626",
    "TestAz" => "ap-southeast-1a"
  },
  "ap-southeast-2" => {
    "AMI"    => "ami-b3990e89",
    "TestAz" => "ap-southeast-2a"
  },
  "eu-west-1"      => {
    "AMI"    => "ami-24506250",
    "TestAz" => "eu-west-1a"
  },
  "sa-east-1"      => {
    "AMI"    => "ami-3e3be423",
    "TestAz" => "sa-east-1a"
  },
  "us-east-1"      => {
    "AMI"    => "ami-7f418316",
    "TestAz" => "us-east-1a"
  },
  "us-west-1"      => {
    "AMI"    => "ami-951945d0",
    "TestAz" => "us-west-1a"
  },
  "us-west-2"      => {
    "AMI"    => "ami-16fd7026",
    "TestAz" => "us-west-2a"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("AvailabilityZone", FnFindInMap("RegionMap", Ref("AWS::Region"), "TestAz"))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("Volumes", [
  {
    "Device"   => "/dev/sdk",
    "VolumeId" => Ref("NewVolume")
  }
])
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access via port 22")
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
    Property("AvailabilityZone", FnFindInMap("RegionMap", Ref("AWS::Region"), "TestAz"))
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

CloudFormation do
  Description("AWS CloudFormation Sample Template EC2_Untargeted_Launch_with_EBS_Volume: Create an Amazon EC2 instance running the Amazon Linux AMI with a new EBS volume attached. The samples shows how to do an untargeted EC2 launch and create an EBS volume in the same availability zone as the EC2 instance. The AMI is chosen based on the region in which the stack is run. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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
    "AMI" => "ami-dcfa4edd"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-74dda626"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-b3990e89"
  },
  "eu-west-1"      => {
    "AMI" => "ami-24506250"
  },
  "sa-east-1"      => {
    "AMI" => "ami-3e3be423"
  },
  "us-east-1"      => {
    "AMI" => "ami-7f418316"
  },
  "us-west-1"      => {
    "AMI" => "ami-951945d0"
  },
  "us-west-2"      => {
    "AMI" => "ami-16fd7026"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("Tags", [
  {
    "Key"   => "MyTag",
    "Value" => "TagValue"
  }
])
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
    Property("Tags", [
  {
    "Key"   => "MyTag",
    "Value" => "TagValue"
  }
])
  end

  Resource("MountPoint") do
    Type("AWS::EC2::VolumeAttachment")
    Property("InstanceId", Ref("Ec2Instance"))
    Property("VolumeId", Ref("NewVolume"))
    Property("Device", "/dev/sdh")
  end

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("Ec2Instance"))
  end

  Output("VolumeId") do
    Description("VolumeId of the newly created EBS Volume")
    Value(Ref("NewVolume"))
  end

  Output("AvailabilityZone") do
    Description("The Availability Zone in which the newly created EC2 instance was launched")
    Value(FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end
end

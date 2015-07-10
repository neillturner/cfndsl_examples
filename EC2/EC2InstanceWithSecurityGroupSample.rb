CloudFormation do
  Description("AWS CloudFormation Sample Template EC2InstanceWithSecurityGroupSample: Create an Amazon EC2 instance running the Amazon Linux AMI. The AMI is chosen based on the region in which the stack is run. This example creates an EC2 security group for the instance to give you SSH access. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of and existing EC2 KeyPair to enable SSH access to the instance")
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
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
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

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("Ec2Instance"))
  end

  Output("AZ") do
    Description("Availability Zone of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end

  Output("PublicDNS") do
    Description("Public DNSName of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicDnsName"))
  end

  Output("PublicIP") do
    Description("Public IP address of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicIp"))
  end
end

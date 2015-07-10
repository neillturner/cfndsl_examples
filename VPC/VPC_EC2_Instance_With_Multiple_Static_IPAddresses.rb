CloudFormation do
  Description("AWS CloudFormation Sample Template VPC_EC2_Instance_With_Multiple_Static_IPAddresses.template: Sample template showing how to create an instance with a single network interface and multiple static IP addresses in an existing VPC. It assumes you have already created a VPC. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of and existing EC2 KeyPair to enable SSH access to the instance")
    Type("String")
  end

  Parameter("VpcId") do
    Description("VpcId of your existing Virtual Private Cloud (VPC)")
    Type("String")
  end

  Parameter("SubnetId") do
    Description("SubnetId of an existing subnet (for the primary network) in your Virtual Private Cloud (VPC)")
    Type("String")
  end

  Parameter("PrimaryIPAddress") do
    Description("Primary private IP. This must be a valid IP address for Subnet")
    Type("String")
  end

  Parameter("SecondaryIPAddress") do
    Description("Secondary private IP. This must be a valid IP address for Subnet")
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

  Resource("EIP1") do
    Type("AWS::EC2::EIP")
    Property("Domain", "vpc")
  end

  Resource("EIPAssoc1") do
    Type("AWS::EC2::EIPAssociation")
    Property("NetworkInterfaceId", Ref("Eth0"))
    Property("AllocationId", FnGetAtt("EIP1", "AllocationId"))
  end

  Resource("SSHSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("VpcId", Ref("VpcId"))
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

  Resource("EC2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("KeyName", Ref("KeyName"))
    Property("NetworkInterfaces", [
  {
    "DeviceIndex"        => "0",
    "NetworkInterfaceId" => Ref("Eth0")
  }
])
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "MyInstance"
  }
])
  end

  Resource("Eth0") do
    Type("AWS::EC2::NetworkInterface")
    Property("Description", "eth0")
    Property("GroupSet", [
  Ref("SSHSecurityGroup")
])
    Property("PrivateIpAddresses", [
  {
    "Primary"          => "true",
    "PrivateIpAddress" => Ref("PrimaryIPAddress")
  },
  {
    "Primary"          => "false",
    "PrivateIpAddress" => Ref("SecondaryIPAddress")
  }
])
    Property("SourceDestCheck", "true")
    Property("SubnetId", Ref("SubnetId"))
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "Interface 0"
  },
  {
    "Key"   => "Interface",
    "Value" => "eth0"
  }
])
  end

  Output("InstanceId") do
    Description("Instance Id of newly created instance")
    Value(Ref("EC2Instance"))
  end

  Output("EIP1") do
    Description("Primary public IP of Eth0")
    Value(FnJoin(" ", [
  "IP address",
  Ref("EIP1"),
  "on subnet",
  Ref("SubnetId")
]))
  end

  Output("PrimaryPrivateIPAddress") do
    Description("Primary private IP address of Eth0")
    Value(FnJoin(" ", [
  "IP address",
  FnGetAtt("Eth0", "PrimaryPrivateIpAddress"),
  "on subnet",
  Ref("SubnetId")
]))
  end

  Output("SecondaryPrivateIPAddresses") do
    Description("Secondary private IP address of Eth0")
    Value(FnJoin(" ", [
  "IP address",
  FnSelect(0, [
  FnGetAtt("Eth0", "SecondaryPrivateIpAddresses")
]),
  "on subnet",
  Ref("SubnetId")
]))
  end
end

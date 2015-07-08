CloudFormation do
  Description("AWS CloudFormation Sample Template EC2_Instance_With_Ephemeral_Drives: Example to show how to attach ephemeral drives using EC2 block device mappings. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "PV64" => "ami-4e6cd34f"
  },
  "ap-southeast-1" => {
    "PV64" => "ami-a6a7e7f4"
  },
  "ap-southeast-2" => {
    "PV64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "PV64" => "ami-c37474b7"
  },
  "sa-east-1"      => {
    "PV64" => "ami-1e08d103"
  },
  "us-east-1"      => {
    "PV64" => "ami-1624987f"
  },
  "us-west-1"      => {
    "PV64" => "ami-1bf9de5e"
  },
  "us-west-2"      => {
    "PV64" => "ami-2a31bf1a"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), "PV64"))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", "m1.small")
    Property("SecurityGroups", [
  Ref("Ec2SecurityGroup")
])
    Property("BlockDeviceMappings", [
  {
    "DeviceName"  => "/dev/sdc",
    "VirtualName" => "ephemeral0"
  }
])
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

  Output("Instance") do
    Description("DNS Name of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicDnsName"))
  end
end

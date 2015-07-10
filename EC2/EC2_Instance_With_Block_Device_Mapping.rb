CloudFormation do
  Description("AWS CloudFormation Sample Template EC2_Instance_With_Block_Device_Mapping: Example to show how to attach EBS volumes and modify the root device using EC2 block device mappings. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"   => {
    "Arch" => "PV64"
  },
  "c1.xlarge"   => {
    "Arch" => "PV64"
  },
  "cc1.4xlarge" => {
    "Arch" => "CLU64"
  },
  "cc2.8xlarge" => {
    "Arch" => "CLU64"
  },
  "cg1.4xlarge" => {
    "Arch" => "GPU64"
  },
  "hi1.4xlarge" => {
    "Arch" => "PV64"
  },
  "hs1.8xlarge" => {
    "Arch" => "PV64"
  },
  "m1.large"    => {
    "Arch" => "PV64"
  },
  "m1.medium"   => {
    "Arch" => "PV64"
  },
  "m1.small"    => {
    "Arch" => "PV64"
  },
  "m1.xlarge"   => {
    "Arch" => "PV64"
  },
  "m2.2xlarge"  => {
    "Arch" => "PV64"
  },
  "m2.4xlarge"  => {
    "Arch" => "PV64"
  },
  "m2.xlarge"   => {
    "Arch" => "PV64"
  },
  "m3.2xlarge"  => {
    "Arch" => "PV64"
  },
  "m3.xlarge"   => {
    "Arch" => "PV64"
  },
  "t1.micro"    => {
    "Arch" => "PV64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-4e6cd34f"
  },
  "ap-southeast-1" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-a6a7e7f4"
  },
  "ap-southeast-2" => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "CLU64" => "ami-d97474ad",
    "GPU64" => "ami-1b02026f",
    "PV64"  => "ami-c37474b7"
  },
  "sa-east-1"      => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-1e08d103"
  },
  "us-east-1"      => {
    "CLU64" => "ami-08249861",
    "GPU64" => "ami-02f54a6b",
    "PV64"  => "ami-1624987f"
  },
  "us-west-1"      => {
    "CLU64" => "NOT_YET_SUPPORTED",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-1bf9de5e"
  },
  "us-west-2"      => {
    "CLU64" => "ami-2431bf14",
    "GPU64" => "NOT_YET_SUPPORTED",
    "PV64"  => "ami-2a31bf1a"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("Ec2SecurityGroup")
])
    Property("BlockDeviceMappings", [
  {
    "DeviceName" => "/dev/sda1",
    "Ebs"        => {
      "VolumeSize" => "50"
    }
  },
  {
    "DeviceName" => "/dev/sdm",
    "Ebs"        => {
      "VolumeSize" => "100"
    }
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

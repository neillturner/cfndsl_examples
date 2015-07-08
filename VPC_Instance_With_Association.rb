CloudFormation do
  Description("AWS CloudFormation Sample Template VPC_Instance_With_Association: Sample template showing how to create an instance in a VPC and associate is with an existing VPC-based Elastic IP Address and VPC-based security group. It assumes you already have a VPC with an EIP and a Security Group associated with the VPC. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("AllocationId") do
    Description("AllocationId of existing Elastic IP (EIP) in your Virtual Private Cloud (VPC)")
    Type("String")
  end

  Parameter("SubnetId") do
    Description("SubnetId of an existing subnet in your Virtual Private Cloud (VPC)")
    Type("String")
  end

  Parameter("SecurityGroupId") do
    Description("The SecurityGroupId of an existing EC2 SecurityGroup in your Virtual Private Cloud (VPC)")
    Type("String")
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
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("SecurityGroupIds", [
  Ref("SecurityGroupId")
])
    Property("SubnetId", Ref("SubnetId"))
  end

  Resource("IPAssoc") do
    Type("AWS::EC2::EIPAssociation")
    Property("InstanceId", Ref("Ec2Instance"))
    Property("AllocationId", Ref("AllocationId"))
  end

  Output("InstanceId") do
    Description("Instance Id of newly created instance")
    Value(Ref("Ec2Instance"))
  end

  Output("InstanceIPAddress") do
    Description("Public IP address of instance")
    Value(FnGetAtt("Ec2Instance", "PublicIp"))
  end
end

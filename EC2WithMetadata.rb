CloudFormation do
  Description("AWS CloudFormation Sample Template EC2WithMetadata: Create an Amazon EC2 instance running the Amazon Linux AMI. The Amazon EC2 instance has metadata attached, illustrating that meta data can be used to tag and instance with additonal information that can be accessed via the AWS CloudFormation command line or API. This example used the default security group, so to SSH to the new instance you will need to have port 22 open in your default security group. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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
    Metadata("Comment", "This metadata is availabile via the cfn-describe-stack-resource command line tool, the DescribeStackResource API call or the cfn-get-metadata helper")
    Metadata("MyAMI", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Metadata("MyRegion", Ref("AWS::Region"))
    Metadata("MyStack", Ref("AWS::StackId"))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("UserData", FnBase64("80"))
  end

  Output("InstanceId") do
    Description("InstanceId of the newly created EC2 instance")
    Value(Ref("Ec2Instance"))
  end

  Output("AZ") do
    Description("Availability Zone of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end

  Output("PublicIP") do
    Description("Public IP address of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PublicIp"))
  end

  Output("PrivateIP") do
    Description("Private IP address of the newly created EC2 instance")
    Value(FnGetAtt("Ec2Instance", "PrivateIp"))
  end
end

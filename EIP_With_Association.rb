CloudFormation do
  Description("AWS CloudFormation Sample Template Sample template EIP_With_Association: This template shows how to associate an Elastic IP address with an Amazon EC2 instance - you can use this same technique to associate an EC2 instance with an Elastic IP Address that is not created inside the template by replacing the EIP reference in the AWS::EC2::EIPAssoication resource type with the IP address of the external EIP. **WARNING** This template creates an Amazon EC2 instance and an Elastic IP Address. You will be billed for the AWS resources used if you create a stack from this template.")
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
    Property("UserData", FnBase64(FnJoin("", [
  "IPAddress=",
  Ref("IPAddress")
])))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
  end

  Resource("IPAddress") do
    Type("AWS::EC2::EIP")
  end

  Resource("IPAssoc") do
    Type("AWS::EC2::EIPAssociation")
    Property("InstanceId", Ref("Ec2Instance"))
    Property("EIP", Ref("IPAddress"))
  end

  Output("InstanceId") do
    Value(Ref("Ec2Instance"))
  end

  Output("InstanceIPAddress") do
    Value(Ref("IPAddress"))
  end
end

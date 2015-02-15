CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

# Using a Wait Condition with an Amazon EC2 Instance
  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI" => "ami-8e08a38f"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-72621c20"
  },
  "eu-west-1"      => {
    "AMI" => "ami-7fd4e10b"
  },
  "us-east-1"      => {
    "AMI" => "ami-76f0061f"
  },
  "us-west-1"      => {
    "AMI" => "ami-655a0a20"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("UserData", FnBase64(Ref("myWaitHandle")))
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
  end

  Resource("myWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("myWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("Ec2Instance")
    Property("Handle", Ref("myWaitHandle"))
    Property("Timeout", "4500")
  end

  Output("ApplicationData") do
    Description("The data passed back as part of signalling the WaitCondition.")
    Value(FnGetAtt("myWaitCondition", "Data"))
  end
end

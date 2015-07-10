CloudFormation do
  Description("AWS CloudFormation Sample Template ec2_instance_with_instance_profile: Create an EC2 instance with an associated instance profile. **WARNING** This template creates one or more Amazon EC2 instances and an Amazon SQS queue. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Resource("myEC2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("IamInstanceProfile", Ref("RootInstanceProfile"))
  end

  Resource("RootRole") do
    Type("AWS::IAM::Role")
    Property("AssumeRolePolicyDocument", {
  "Statement" => [
    {
      "Action"    => [
        "sts:AssumeRole"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "Service" => [
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
})
    Property("Path", "/")
  end

  Resource("RolePolicies") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "root")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => "*",
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Roles", [
  Ref("RootRole")
])
  end

  Resource("RootInstanceProfile") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("RootRole")
])
  end
end

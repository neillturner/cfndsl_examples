CloudFormation do
  Description("AWS CloudFormation Sample Template auto_scaling_with_instance_profile: Create an Auto Scaling group with an associated instance profile. **WARNING** This template creates one or more Amazon EC2 instances and an Amazon SQS queue. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("InstanceType") do
    Description("EC2 instance type")
    Type("String")
    Default("m1.small")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "m3.xlarge",
  "m3.2xlarge",
  "c1.medium",
  "c1.xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"  => {
    "Arch" => "64"
  },
  "c1.xlarge"  => {
    "Arch" => "64"
  },
  "m1.large"   => {
    "Arch" => "64"
  },
  "m1.medium"  => {
    "Arch" => "64"
  },
  "m1.small"   => {
    "Arch" => "64"
  },
  "m1.xlarge"  => {
    "Arch" => "64"
  },
  "m2.2xlarge" => {
    "Arch" => "64"
  },
  "m2.4xlarge" => {
    "Arch" => "64"
  },
  "m2.xlarge"  => {
    "Arch" => "64"
  },
  "m3.2xlarge" => {
    "Arch" => "64"
  },
  "m3.xlarge"  => {
    "Arch" => "64"
  },
  "t1.micro"   => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32" => "ami-7871c579",
    "64" => "ami-7671c577"
  },
  "ap-southeast-1" => {
    "32" => "ami-425a2010",
    "64" => "ami-5e5a200c"
  },
  "ap-southeast-2" => {
    "32" => "ami-b3990e89",
    "64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "32" => "ami-018bb975",
    "64" => "ami-998bb9ed"
  },
  "sa-east-1"      => {
    "32" => "ami-a039e6bd",
    "64" => "ami-a239e6bf"
  },
  "us-east-1"      => {
    "32" => "ami-aba768c2",
    "64" => "ami-81a768e8"
  },
  "us-west-1"      => {
    "32" => "ami-458fd300",
    "64" => "ami-b18ed2f4"
  },
  "us-west-2"      => {
    "32" => "ami-fcff72cc",
    "64" => "ami-feff72ce"
  }
})

  Resource("myLCOne") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("InstanceType", Ref("InstanceType"))
    Property("IamInstanceProfile", Ref("RootInstanceProfile"))
  end

  Resource("myASGrpOne") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("myLCOne"))
    Property("MinSize", "1")
    Property("MaxSize", "1")
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

CloudFormation do
  Description("AWS CloudFormer Beta - template creation prototype application. This tool allows you to create an AWS CloudFormation template from the AWS resources in your AWS account. **Warning** This template creates a single t1.micro instance in your account to run the application - you will be billed for the instance at normal AWS EC2 rates for the t1.micro.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("AccessControl") do
    Description(" The IP address range that can be used to access the CloudFormer tool. NOTE: We highly recommend that you specify a customized address range to lock down the tool.")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI" => "ami-7d1a777c"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-c0356292"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-cd1b84f7"
  },
  "eu-west-1"      => {
    "AMI" => "ami-26688051"
  },
  "sa-east-1"      => {
    "AMI" => "ami-592d8c44"
  },
  "us-east-1"      => {
    "AMI" => "ami-21341f48"
  },
  "us-gov-west-1"  => {
    "AMI" => "ami-23c1a500"
  },
  "us-west-1"      => {
    "AMI" => "ami-ec7c4fa9"
  },
  "us-west-2"      => {
    "AMI" => "ami-d6096ee6"
  }
})

  Resource("CFNRole") do
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

  Resource("CFNRolePolicy") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "CloudFormerPolicy")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => [
        "autoscaling:Describe*",
        "cloudfront:List*",
        "cloudwatch:Describe*",
        "dynamodb:List*",
        "dynamodb:Describe*",
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "elasticache:Describe*",
        "rds:Describe*",
        "rds:List*",
        "route53:List*",
        "s3:List*",
        "s3:Get*",
        "s3:PutObject",
        "sdb:Get*",
        "sdb:List*",
        "sns:Get*",
        "sns:List*",
        "sqs:Get*",
        "sqs:List*"
      ],
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Roles", [
  Ref("CFNRole")
])
  end

  Resource("CFNInstanceProfile") do
    Type("AWS::IAM::InstanceProfile")
    Property("Path", "/")
    Property("Roles", [
  Ref("CFNRole")
])
  end

  Resource("WebServer") do
    Type("AWS::EC2::Instance")
    Property("InstanceType", "t1.micro")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("IamInstanceProfile", Ref("CFNInstanceProfile"))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable Access via port 80")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("AccessControl"),
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  }
])
  end

  Output("URL") do
    Description("AWS CloudFormer Prototype URL. Use this endpoint to create templates from your account.")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "PublicDnsName")
]))
  end
end

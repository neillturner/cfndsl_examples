CloudFormation do
  Description("AWS CloudFormation Sample Template Route53_A: Sample template showing how to create an Amazon Route 53 A record that maps to the public IP address of an EC2 instance. It assumes that you already have a Hosted Zone registered with Amazon Route 53. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
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
  end

  Resource("myDNSRecord") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneName", FnJoin("", [
  Ref("HostedZone"),
  "."
]))
    Property("Comment", "DNS name for my instance.")
    Property("Name", FnJoin("", [
  Ref("Ec2Instance"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone"),
  "."
]))
    Property("Type", "A")
    Property("TTL", "900")
    Property("ResourceRecords", [
  FnGetAtt("Ec2Instance", "PublicIp")
])
  end

  Output("DomainName") do
    Value(Ref("myDNSRecord"))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template ELBZoneApex: Create a load balanced sample web site mapping the site to a zone apex. This example creates 2 EC2 instances behind a load balancer with a simple health check and maps the load balancer to the DNS zone apex specified. The instances may be created in one or more AZs. The web site is available on port 80, however, the instances can be configured to listen on any port (8888 by default). **WARNING** This template creates one or more Amazon EC2 instances and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
    Type("String")
  end

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
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "m3.xlarge",
  "m3.2xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge",
  "cc2.8xlarge",
  "cg1.4xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("WebServerPort") do
    Description("TCP/IP port of the web server")
    Type("String")
    Default("8888")
  end

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
  end

  Parameter("SSHLocation") do
    Description("The IP address range that can be used to SSH to the EC2 instances")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
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
    "32" => "ami-f98512c3",
    "64" => "ami-43851279"
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

  Resource("DNSZone") do
    Type("AWS::Route53::RecordSetGroup")
    Property("HostedZoneName", FnJoin("", [
  Ref("HostedZone"),
  "."
]))
    Property("Comment", "Zone apex alias targeted to ElasticLoadBalancer.")
    Property("RecordSets", [
  {
    "AliasTarget" => {
      "DNSName"      => FnGetAtt("ElasticLoadBalancer", "CanonicalHostedZoneName"),
      "HostedZoneId" => FnGetAtt("ElasticLoadBalancer", "CanonicalHostedZoneNameID")
    },
    "Name"        => FnJoin("", [
  Ref("HostedZone"),
  "."
]),
    "Type"        => "A"
  }
])
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("Instances", [
  Ref("Ec2Instance1"),
  Ref("Ec2Instance2")
])
    Property("Listeners", [
  {
    "InstancePort"     => Ref("WebServerPort"),
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "3",
  "Interval"           => "30",
  "Target"             => FnJoin("", [
  "HTTP:",
  Ref("WebServerPort"),
  "/"
]),
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
  end

  Resource("Ec2Instance1") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(Ref("WebServerPort")))
  end

  Resource("Ec2Instance2") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(Ref("WebServerPort")))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access and HTTP access on the inbound port")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => Ref("WebServerPort"),
    "IpProtocol" => "tcp",
    "ToPort"     => Ref("WebServerPort")
  }
])
  end

  Output("URL") do
    Description("URL of the sample website")
    Value(FnJoin("", [
  "http://",
  Ref("DNSZone")
]))
  end
end

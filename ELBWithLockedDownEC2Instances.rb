CloudFormation do
  Description("AWS CloudFormation Sample Template ELBWithLockedDownEC2Instances: Create a load balanced, Auto Scaled sample website where the instances are locked down to only accept traffic from the load balancer. This example creates an Auto Scaling group behind a load balancer with a simple health check. The web site is available on port 80, however, the instances can be configured to listen on any port (8888 by default). **WARNING** This template creates one or more Amazon EC2 instances and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", "2")
    Property("MaxSize", "2")
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(Ref("WebServerPort")))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", FnGetAZs(""))
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

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access and HTTP access on the inbound port")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => Ref("WebServerPort"),
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => Ref("WebServerPort")
  }
])
  end

  Output("URL") do
    Description("URL of the website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

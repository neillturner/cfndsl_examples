CloudFormation do
  Description("AWS CloudFormation Sample Template vpc_multiple_subnets.template: Sample template showing how to create a VPC with multiple subnets. The first subnet is public and contains the load balancer, the second subnet is private and contains an EC2 instance behind the load balancer. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("InstanceCount") do
    Description("Number of EC2 instances to launch")
    Type("Number")
    Default("1")
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

  Resource("VPC") do
    Type("AWS::EC2::VPC")
    Property("CidrBlock", "10.0.0.0/16")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Public"
  }
])
  end

  Resource("PublicSubnet") do
    Type("AWS::EC2::Subnet")
    Property("VpcId", Ref("VPC"))
    Property("CidrBlock", "10.0.0.0/24")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Public"
  }
])
  end

  Resource("InternetGateway") do
    Type("AWS::EC2::InternetGateway")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Public"
  }
])
  end

  Resource("AttachGateway") do
    Type("AWS::EC2::VPCGatewayAttachment")
    Property("VpcId", Ref("VPC"))
    Property("InternetGatewayId", Ref("InternetGateway"))
  end

  Resource("PublicRouteTable") do
    Type("AWS::EC2::RouteTable")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Public"
  }
])
  end

  Resource("PublicRoute") do
    Type("AWS::EC2::Route")
    DependsOn("AttachGateway")
    Property("RouteTableId", Ref("PublicRouteTable"))
    Property("DestinationCidrBlock", "0.0.0.0/0")
    Property("GatewayId", Ref("InternetGateway"))
  end

  Resource("PublicSubnetRouteTableAssociation") do
    Type("AWS::EC2::SubnetRouteTableAssociation")
    Property("SubnetId", Ref("PublicSubnet"))
    Property("RouteTableId", Ref("PublicRouteTable"))
  end

  Resource("PublicNetworkAcl") do
    Type("AWS::EC2::NetworkAcl")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Public"
  }
])
  end

  Resource("InboundHTTPPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "80",
  "To"   => "80"
})
  end

  Resource("InboundDynamicPortsPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "101")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "1024",
  "To"   => "65535"
})
  end

  Resource("OutboundHTTPPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "80",
  "To"   => "80"
})
  end

  Resource("OutBoundDynamicPortPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "101")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "1024",
  "To"   => "65535"
})
  end

  Resource("PublicSubnetNetworkAclAssociation") do
    Type("AWS::EC2::SubnetNetworkAclAssociation")
    Property("SubnetId", Ref("PublicSubnet"))
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
  end

  Resource("PrivateSubnet") do
    Type("AWS::EC2::Subnet")
    Property("VpcId", Ref("VPC"))
    Property("CidrBlock", "10.0.1.0/24")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Private"
  }
])
  end

  Resource("PrivateRouteTable") do
    Type("AWS::EC2::RouteTable")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Private"
  }
])
  end

  Resource("PrivateSubnetRouteTableAssociation") do
    Type("AWS::EC2::SubnetRouteTableAssociation")
    Property("SubnetId", Ref("PrivateSubnet"))
    Property("RouteTableId", Ref("PrivateRouteTable"))
  end

  Resource("PrivateNetworkAcl") do
    Type("AWS::EC2::NetworkAcl")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  },
  {
    "Key"   => "Network",
    "Value" => "Private"
  }
])
  end

  Resource("InboundPrivateNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PrivateNetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "0",
  "To"   => "65535"
})
  end

  Resource("OutBoundPrivateNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PrivateNetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "0",
  "To"   => "65535"
})
  end

  Resource("PrivateSubnetNetworkAclAssociation") do
    Type("AWS::EC2::SubnetNetworkAclAssociation")
    Property("SubnetId", Ref("PrivateSubnet"))
    Property("NetworkAclId", Ref("PrivateNetworkAcl"))
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("SecurityGroups", [
  Ref("LoadBalancerSecurityGroup")
])
    Property("Subnets", [
  Ref("PublicSubnet")
])
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "3",
  "Interval"           => "90",
  "Target"             => "HTTP:80/",
  "Timeout"            => "60",
  "UnhealthyThreshold" => "5"
})
  end

  Resource("LoadBalancerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access on port 80")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  }
])
    Property("SecurityGroupEgress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  }
])
  end

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", [
  FnGetAtt("PrivateSubnet", "AvailabilityZone")
])
    Property("VPCZoneIdentifier", [
  Ref("PrivateSubnet")
])
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", "1")
    Property("MaxSize", "10")
    Property("DesiredCapacity", Ref("InstanceCount"))
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
    Property("Tags", [
  {
    "Key"               => "Network",
    "PropagateAtLaunch" => "true",
    "Value"             => "Public"
  }
])
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64("80"))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable HTTP access on the configured port")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "FromPort"              => "80",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("LoadBalancerSecurityGroup"),
    "ToPort"                => "80"
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

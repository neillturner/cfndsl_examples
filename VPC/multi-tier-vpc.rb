CloudFormation do
  Description("AWS CloudFormation Sample Template multi-tier-vpc.template: Sample template showing how to create a multi-tier VPC with multiple subnets that can be used to launch VPC-based Elastic Beanstalk applications in. The first subnet is public and contains a NAT device for internet access from the private subnet and a bastion host to allow SSH access to the hosts in the private subnet. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the bastion host")
    Type("String")
    AllowedPattern("[-_ a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("can contain only alphanumeric characters, spaces, dashes and underscores.")
  end

  Parameter("SSHFrom") do
    Description("Lockdown SSH access to the bastion host (default can be accessed from anywhere)")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid CIDR range of the form x.x.x.x/x.")
  end

  Parameter("BastionInstanceType") do
    Description("Bastion Host EC2 instance type")
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

  Parameter("NATInstanceType") do
    Description("NET Device EC2 instance type")
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

  Mapping("AWSNATAMI", {
  "ap-northeast-1" => {
    "AMI" => "ami-14d86d15"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-02eb9350"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-ab990e91"
  },
  "eu-west-1"      => {
    "AMI" => "ami-0b5b6c7f"
  },
  "sa-east-1"      => {
    "AMI" => "ami-0439e619"
  },
  "us-east-1"      => {
    "AMI" => "ami-c6699baf"
  },
  "us-west-1"      => {
    "AMI" => "ami-3bcc9e7e"
  },
  "us-west-2"      => {
    "AMI" => "ami-52ff7262"
  }
})

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"   => {
    "Arch" => "64"
  },
  "c1.xlarge"   => {
    "Arch" => "64"
  },
  "cc1.4xlarge" => {
    "Arch" => "64Cluster"
  },
  "cc2.8xlarge" => {
    "Arch" => "64Cluster"
  },
  "cg1.4xlarge" => {
    "Arch" => "64GPU"
  },
  "m1.large"    => {
    "Arch" => "64"
  },
  "m1.medium"   => {
    "Arch" => "64"
  },
  "m1.small"    => {
    "Arch" => "64"
  },
  "m1.xlarge"   => {
    "Arch" => "64"
  },
  "m2.2xlarge"  => {
    "Arch" => "64"
  },
  "m2.4xlarge"  => {
    "Arch" => "64"
  },
  "m2.xlarge"   => {
    "Arch" => "64"
  },
  "m3.2xlarge"  => {
    "Arch" => "64"
  },
  "m3.xlarge"   => {
    "Arch" => "64"
  },
  "t1.micro"    => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32"        => "ami-2a19aa2b",
    "64"        => "ami-2819aa29",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-1" => {
    "32"        => "ami-220b4a70",
    "64"        => "ami-3c0b4a6e",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-2" => {
    "32"        => "ami-b3990e89",
    "64"        => "ami-bd990e87",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "eu-west-1"      => {
    "32"        => "ami-61555115",
    "64"        => "ami-6d555119",
    "64Cluster" => "ami-67555113",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "sa-east-1"      => {
    "32"        => "ami-f836e8e5",
    "64"        => "ami-fe36e8e3",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "us-east-1"      => {
    "32"        => "ami-a0cd60c9",
    "64"        => "ami-aecd60c7",
    "64Cluster" => "ami-a8cd60c1",
    "64GPU"     => "ami-eccf6285"
  },
  "us-west-1"      => {
    "32"        => "ami-7d4c6938",
    "64"        => "ami-734c6936",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  },
  "us-west-2"      => {
    "32"        => "ami-46da5576",
    "64"        => "ami-48da5578",
    "64Cluster" => "NOT_YET_SUPPORTED",
    "64GPU"     => "NOT_YET_SUPPORTED"
  }
})

  Mapping("SubnetConfig", {
  "Private" => {
    "CIDR" => "10.0.1.0/24"
  },
  "Public"  => {
    "CIDR" => "10.0.0.0/24"
  },
  "VPC"     => {
    "CIDR" => "10.0.0.0/16"
  }
})

  Resource("VPC") do
    Type("AWS::EC2::VPC")
    Property("CidrBlock", FnFindInMap("SubnetConfig", "VPC", "CIDR"))
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
    Property("CidrBlock", FnFindInMap("SubnetConfig", "Public", "CIDR"))
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

  Resource("GatewayToInternet") do
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
    DependsOn("GatewayToInternet")
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

  Resource("InboundHTTPSPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "101")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "443",
  "To"   => "443"
})
  end

  Resource("InboundSSHPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "102")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", Ref("SSHFrom"))
    Property("PortRange", {
  "From" => "22",
  "To"   => "22"
})
  end

  Resource("InboundEmphemeralPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
    Property("RuleNumber", "103")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "1024",
  "To"   => "65535"
})
  end

  Resource("OutboundPublicNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
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

  Resource("PublicSubnetNetworkAclAssociation") do
    Type("AWS::EC2::SubnetNetworkAclAssociation")
    Property("SubnetId", Ref("PublicSubnet"))
    Property("NetworkAclId", Ref("PublicNetworkAcl"))
  end

  Resource("PrivateSubnet") do
    Type("AWS::EC2::Subnet")
    Property("VpcId", Ref("VPC"))
    Property("CidrBlock", FnFindInMap("SubnetConfig", "Private", "CIDR"))
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

  Resource("PrivateRoute") do
    Type("AWS::EC2::Route")
    Property("RouteTableId", Ref("PrivateRouteTable"))
    Property("DestinationCidrBlock", "0.0.0.0/0")
    Property("InstanceId", Ref("NATDevice"))
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

  Resource("NATIPAddress") do
    Type("AWS::EC2::EIP")
    DependsOn("GatewayToInternet")
    Property("Domain", "vpc")
    Property("InstanceId", Ref("NATDevice"))
  end

  Resource("NATDevice") do
    Type("AWS::EC2::Instance")
    Property("InstanceType", Ref("NATInstanceType"))
    Property("SubnetId", Ref("PublicSubnet"))
    Property("SourceDestCheck", "false")
    Property("ImageId", FnFindInMap("AWSNATAMI", Ref("AWS::Region"), "AMI"))
    Property("SecurityGroupIds", [
  Ref("NATSecurityGroup")
])
  end

  Resource("NATSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable internal access to the NAT device")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "443",
    "IpProtocol" => "tcp",
    "ToPort"     => "443"
  }
])
    Property("SecurityGroupEgress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "443",
    "IpProtocol" => "tcp",
    "ToPort"     => "443"
  }
])
  end

  Resource("BastionIPAddress") do
    Type("AWS::EC2::EIP")
    DependsOn("GatewayToInternet")
    Property("Domain", "vpc")
    Property("InstanceId", Ref("BastionHost"))
  end

  Resource("BastionHost") do
    Type("AWS::EC2::Instance")
    Property("InstanceType", Ref("BastionInstanceType"))
    Property("KeyName", Ref("KeyName"))
    Property("SubnetId", Ref("PublicSubnet"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("BastionInstanceType"), "Arch")))
    Property("SecurityGroupIds", [
  Ref("BastionSecurityGroup")
])
  end

  Resource("BastionSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable access to the Bastion host")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHFrom"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
    Property("SecurityGroupEgress", [
  {
    "CidrIp"     => FnFindInMap("SubnetConfig", "Private", "CIDR"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Output("VPCId") do
    Description("VPCId of the newly created VPC")
    Value(Ref("VPC"))
  end

  Output("PublicSubnet") do
    Description("SubnetId of the public subnet")
    Value(Ref("PublicSubnet"))
  end

  Output("PrivateSubnet") do
    Description("SubnetId of the private subnet")
    Value(Ref("PrivateSubnet"))
  end

  Output("Bastion") do
    Description("IP Address of the Bastion host")
    Value(Ref("BastionIPAddress"))
  end

  Output("BastionSecuirtyGroup") do
    Description("Security group of the Bastin Host")
    Value(Ref("BastionSecurityGroup"))
  end
end

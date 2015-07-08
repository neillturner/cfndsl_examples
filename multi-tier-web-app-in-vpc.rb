CloudFormation do
  Description("AWS CloudFormation Sample Template multi-tier-web-app-in-vpc.template: Sample template showing how to create a multi-tier web application in a VPC with multiple subnets. The first subnet is public and contains and internet facing load balancer, a NAT device for internet access from the private subnet and a bastion host to allow SSH access to the hosts in the private subnet. The second subnet is private and contains a Frontend fleet of EC2 instances, an internal load balancer and a Backend fleet of EC2 instances. **WARNING** This template creates Elastic Load Balancers and Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instances")
    Type("String")
    AllowedPattern("[-_ a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("can contain only alphanumeric characters, spaces, dashes and underscores.")
  end

  Parameter("SSHLocation") do
    Description("Lockdown SSH access to the bastion host (default can be accessed from anywhere)")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid CIDR range of the form x.x.x.x/x.")
  end

  Parameter("FrontendInstanceType") do
    Description("Frontend Server EC2 instance type")
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

  Parameter("FrontendSize") do
    Description("Number of EC2 instances to launch for the Frontend server")
    Type("Number")
    Default("1")
  end

  Parameter("BackendInstanceType") do
    Description("Backend Server EC2 instance type")
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

  Parameter("BackendSize") do
    Description("Number of EC2 instances to launch for the backend server")
    Type("Number")
    Default("1")
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
    Property("CidrBlock", Ref("SSHLocation"))
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
    Property("KeyName", Ref("KeyName"))
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
  },
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
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
    "CidrIp"     => Ref("SSHLocation"),
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

  Resource("PublicElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("SecurityGroups", [
  Ref("PublicLoadBalancerSecurityGroup")
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

  Resource("PublicLoadBalancerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Public ELB Security Group with HTTP access on port 80 from the internet")
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

  Resource("FrontendFleet") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", [
  FnGetAtt("PrivateSubnet", "AvailabilityZone")
])
    Property("VPCZoneIdentifier", [
  Ref("PrivateSubnet")
])
    Property("LaunchConfigurationName", Ref("FrontendServerLaunchConfig"))
    Property("MinSize", "1")
    Property("MaxSize", "10")
    Property("DesiredCapacity", Ref("FrontendSize"))
    Property("LoadBalancerNames", [
  Ref("PublicElasticLoadBalancer")
])
    Property("Tags", [
  {
    "Key"               => "Network",
    "PropagateAtLaunch" => "true",
    "Value"             => "Public"
  }
])
  end

  Resource("FrontendServerLaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("Comment1", "Configure the FrontendServer to forward /backend requests to the backend servers")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/httpd/conf.d/maptobackend.conf" => {
        "content" => FnJoin("", [
  "ProxyPass /backend http://",
  FnGetAtt("PrivateElasticLoadBalancer", "DNSName"),
  "\n",
  "ProxyPassReverse /backend http://",
  FnGetAtt("PrivateElasticLoadBalancer", "DNSName"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/var/www/html/index.html"            => {
        "content" => FnJoin("
", [
  "<img src=\"https://s3.amazonaws.com/cloudformation-examples/cloudformation_graphic.png\" alt=\"AWS CloudFormation Logo\"/>",
  "<h1>Congratulations, you have successfully launched the multi-tier AWS CloudFormation sample.</h1>",
  "<p>This is a multi-tier web application launched in an Amazon Virtual Private Cloud (Amazon VPC) with multiple subnets. The first subnet is public and contains and internet facing load balancer, a NAT device for internet access from the private subnet and a bastion host to allow SSH access to the hosts in the private subnet. The second subnet is private and contains a Frontend fleet of EC2 instances, an internal load balancer and a Backend fleet of EC2 instances.",
  "<p>To serve a web page from the backend service, click <a href=\"/backend\">here</a>.</p>"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "yum" => {
        "httpd" => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd" => {
          "enabled"       => "true",
          "ensureRunning" => "true",
          "files"         => [
            "/etc/httpd/conf.d/maptobackend.conf",
            "/var/www/html/index.html"
          ]
        }
      }
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("FrontendInstanceType"), "Arch")))
    Property("SecurityGroups", [
  Ref("FrontendSecurityGroup")
])
    Property("InstanceType", Ref("FrontendInstanceType"))
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Install Apache and configure as a reverse Frontend\n",
  "/opt/aws/bin/cfn-init --stack ",
  Ref("AWS::StackId"),
  " --resource FrontendServerLaunchConfig ",
  "    --region ",
  Ref("AWS::Region"),
  "\n",
  "# Signal completion\n",
  "/opt/aws/bin/cfn-signal -e $? -r \"Frontend setup done\" '",
  Ref("FrontendWaitHandle"),
  "'\n"
])))
  end

  Resource("FrontendSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Allow access from load balancer and bastion as well as outbound HTTP and HTTPS traffic")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "FromPort"              => "80",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("PublicLoadBalancerSecurityGroup"),
    "ToPort"                => "80"
  },
  {
    "FromPort"              => "22",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("BastionSecurityGroup"),
    "ToPort"                => "22"
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

  Resource("FrontendWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("FrontendWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("FrontendFleet")
    Property("Handle", Ref("FrontendWaitHandle"))
    Property("Timeout", "300")
    Property("Count", Ref("FrontendSize"))
  end

  Resource("PrivateElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("SecurityGroups", [
  Ref("PrivateLoadBalancerSecurityGroup")
])
    Property("Subnets", [
  Ref("PrivateSubnet")
])
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("Scheme", "internal")
    Property("HealthCheck", {
  "HealthyThreshold"   => "3",
  "Interval"           => "90",
  "Target"             => "HTTP:80/",
  "Timeout"            => "60",
  "UnhealthyThreshold" => "5"
})
  end

  Resource("PrivateLoadBalancerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Private ELB Security Group with HTTP access on port 80 from the Frontend Fleet only")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "FromPort"              => "80",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("FrontendSecurityGroup"),
    "ToPort"                => "80"
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

  Resource("BackendFleet") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", [
  FnGetAtt("PrivateSubnet", "AvailabilityZone")
])
    Property("VPCZoneIdentifier", [
  Ref("PrivateSubnet")
])
    Property("LaunchConfigurationName", Ref("BackendLaunchConfig"))
    Property("MinSize", "1")
    Property("MaxSize", "10")
    Property("DesiredCapacity", Ref("BackendSize"))
    Property("LoadBalancerNames", [
  Ref("PrivateElasticLoadBalancer")
])
    Property("Tags", [
  {
    "Key"               => "Network",
    "PropagateAtLaunch" => "true",
    "Value"             => "Private"
  }
])
  end

  Resource("BackendLaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Metadata("Comment1", "Configure the Backend server to respond to requests")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/var/www/html/index.html" => {
        "content" => FnJoin("
", [
  "<img src=\"https://s3.amazonaws.com/cloudformation-examples/cloudformation_graphic.png\" alt=\"AWS CloudFormation Logo\"/>",
  "<h1>Congratulations, this request was served from the backend fleet</h1>"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      }
    },
    "packages" => {
      "yum" => {
        "httpd" => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd" => {
          "enabled"       => "true",
          "ensureRunning" => "true",
          "files"         => [
            "/var/www/html/index.html"
          ]
        }
      }
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("BackendInstanceType"), "Arch")))
    Property("SecurityGroups", [
  Ref("BackendSecurityGroup")
])
    Property("InstanceType", Ref("BackendInstanceType"))
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Install Apache\n",
  "/opt/aws/bin/cfn-init --stack ",
  Ref("AWS::StackId"),
  " --resource BackendLaunchConfig ",
  "    --region ",
  Ref("AWS::Region"),
  "\n",
  "# Signal completion\n",
  "/opt/aws/bin/cfn-signal -e $? -r \"Backend setup done\" '",
  Ref("BackendWaitHandle"),
  "'\n"
])))
  end

  Resource("BackendSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Allow access from private load balancer and bastion as well as outbound HTTP and HTTPS traffic")
    Property("VpcId", Ref("VPC"))
    Property("SecurityGroupIngress", [
  {
    "FromPort"              => "80",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("PrivateLoadBalancerSecurityGroup"),
    "ToPort"                => "80"
  },
  {
    "FromPort"              => "22",
    "IpProtocol"            => "tcp",
    "SourceSecurityGroupId" => Ref("BastionSecurityGroup"),
    "ToPort"                => "22"
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

  Resource("BackendWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("BackendWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("BackendFleet")
    Property("Handle", Ref("BackendWaitHandle"))
    Property("Timeout", "300")
    Property("Count", Ref("BackendSize"))
  end

  Output("WebSite") do
    Description("URL of the website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("PublicElasticLoadBalancer", "DNSName")
]))
  end

  Output("Bastion") do
    Description("IP Address of the Bastion host")
    Value(Ref("BastionIPAddress"))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template VPC_With_VPN_Connection.template: Sample template showing how to create a private subnet with a VPN connection using static routing to an existing VPN endpoint. NOTE: The VPNConnection created will define the configuration you need yonk the tunnels to your VPN endpoint - you can get the VPN Gateway configuration from the AWS Management console. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("VPCCIDR") do
    Description("IP Address range for the VPN connected VPC")
    Type("String")
    Default("10.1.0.0/16")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Parameter("SubnetCIDR") do
    Description("IP Address range for the VPN connected Subnet")
    Type("String")
    Default("10.1.0.0/24")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Parameter("VPNAddress") do
    Description("IP Address of your VPN device")
    Type("String")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})")
    MaxLength(15)
    MinLength(7)
    ConstraintDescription("must be a valid IP address of the form x.x.x.x")
  end

  Parameter("OnPremiseCIDR") do
    Description("IP Address range for your existing infrastructure")
    Type("String")
    Default("10.0.0.0/16")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Resource("VPC") do
    Type("AWS::EC2::VPC")
    Property("EnableDnsSupport", "true")
    Property("EnableDnsHostnames", "true")
    Property("CidrBlock", Ref("VPCCIDR"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
  },
  {
    "Key"   => "Network",
    "Value" => "VPN Connected VPC"
  }
])
  end

  Resource("PrivateSubnet") do
    Type("AWS::EC2::Subnet")
    Property("VpcId", Ref("VPC"))
    Property("CidrBlock", Ref("SubnetCIDR"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
  },
  {
    "Key"   => "Network",
    "Value" => "VPN Connected Subnet"
  }
])
  end

  Resource("VPNGateway") do
    Type("AWS::EC2::VPNGateway")
    Property("Type", "ipsec.1")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
  }
])
  end

  Resource("VPNGatewayAttachment") do
    Type("AWS::EC2::VPCGatewayAttachment")
    Property("VpcId", Ref("VPC"))
    Property("VpnGatewayId", Ref("VPNGateway"))
  end

  Resource("CustomerGateway") do
    Type("AWS::EC2::CustomerGateway")
    Property("Type", "ipsec.1")
    Property("BgpAsn", "65000")
    Property("IpAddress", Ref("VPNAddress"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
  },
  {
    "Key"   => "VPN",
    "Value" => FnJoin("", [
  "Gateway to ",
  Ref("VPNAddress")
])
  }
])
  end

  Resource("VPNConnection") do
    Type("AWS::EC2::VPNConnection")
    Property("Type", "ipsec.1")
    Property("StaticRoutesOnly", "true")
    Property("CustomerGatewayId", Ref("CustomerGateway"))
    Property("VpnGatewayId", Ref("VPNGateway"))
  end

  Resource("VPNConnectionRoute") do
    Type("AWS::EC2::VPNConnectionRoute")
    Property("VpnConnectionId", Ref("VPNConnection"))
    Property("DestinationCidrBlock", Ref("OnPremiseCIDR"))
  end

  Resource("PrivateRouteTable") do
    Type("AWS::EC2::RouteTable")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
  },
  {
    "Key"   => "Network",
    "Value" => "VPN Connected Subnet"
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
    DependsOn("VPNGatewayAttachment")
    Property("RouteTableId", Ref("PrivateRouteTable"))
    Property("DestinationCidrBlock", "0.0.0.0/0")
    Property("GatewayId", Ref("VPNGateway"))
  end

  Resource("PrivateNetworkAcl") do
    Type("AWS::EC2::NetworkAcl")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackName")
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

  Output("VPCId") do
    Description("VPCId of the newly created VPC")
    Value(Ref("VPC"))
  end

  Output("PrivateSubnet") do
    Description("SubnetId of the VPN connected subnet")
    Value(Ref("PrivateSubnet"))
  end
end

CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

# Amazon Redshift Cluster
#
# The following sample template creates an Amazon Redshift cluster according to the parameter values that are specified
# when the stack is created. The cluster parameter group that is associated with the Amazon Redshift cluster enables user
# activity logging. The template also launches the Amazon Redshift clusters in an Amazon VPC that is defined in the template.
# The VPC includes an internet gateway so that you can access the Amazon Redshift clusters from the Internet. However, the
# communication between the cluster and the Internet gateway must also be enabled, which is done by the route table entry.
#
  Parameter("DatabaseName") do
    Description("The name of the first database to be created when the cluster is created")
    Type("String")
    Default("dev")
    AllowedPattern("([a-z]|[0-9])+")
  end

  Parameter("ClusterType") do
    Description("The type of cluster")
    Type("String")
    Default("single-node")
    AllowedValues([
  "single-node",
  "multi-node"
])
  end

  Parameter("NumberOfNodes") do
    Description("The number of compute nodes in the cluster. For multi-node clusters, the NumberOfNodes parameter must be greater than 1")
    Type("Number")
    Default("1")
  end

  Parameter("NodeType") do
    Description("The type of node to be provisioned")
    Type("String")
    Default("dw1.xlarge")
    AllowedValues([
  "dw1.xlarge",
  "dw1.8xlarge",
  "dw2.large",
  "dw2.8xlarge"
])
  end

  Parameter("MasterUsername") do
    Description("The user name that is associated with the master user account for the cluster that is being created")
    Type("String")
    Default("defaultuser")
    AllowedPattern("([a-z])([a-z]|[0-9])*")
  end

  Parameter("MasterUserPassword") do
    Description("The password that is associated with the master user account for the cluster that is being created.")
    Type("String")
    NoEcho(true)
  end

  Parameter("InboundTraffic") do
    Description("Allow inbound traffic to the cluster from this CIDR range.")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid CIDR range of the form x.x.x.x/x.")
  end

  Parameter("PortNumber") do
    Description("The port number on which the cluster accepts incoming connections.")
    Type("Number")
    Default("5439")
  end

  Condition("IsMultiNodeCluster", FnEquals(Ref("ClusterType"), "multi-node"))

  Resource("RedshiftCluster") do
    Type("AWS::Redshift::Cluster")
    DependsOn("AttachGateway")
    Property("ClusterType", Ref("ClusterType"))
    Property("NumberOfNodes", FnIf("IsMultiNodeCluster", Ref("NumberOfNodes"), Ref("AWS::NoValue")))
    Property("NodeType", Ref("NodeType"))
    Property("DBName", Ref("DatabaseName"))
    Property("MasterUsername", Ref("MasterUsername"))
    Property("MasterUserPassword", Ref("MasterUserPassword"))
    Property("ClusterParameterGroupName", Ref("RedshiftClusterParameterGroup"))
    Property("VpcSecurityGroupIds", [
  Ref("SecurityGroup")
])
    Property("ClusterSubnetGroupName", Ref("RedshiftClusterSubnetGroup"))
    Property("PubliclyAccessible", "true")
    Property("Port", Ref("PortNumber"))
  end

  Resource("RedshiftClusterParameterGroup") do
    Type("AWS::Redshift::ClusterParameterGroup")
    Property("Description", "Cluster parameter group")
    Property("ParameterGroupFamily", "redshift-1.0")
    Property("Parameters", [
  {
    "ParameterName"  => "enable_user_activity_logging",
    "ParameterValue" => "true"
  }
])
  end

  Resource("RedshiftClusterSubnetGroup") do
    Type("AWS::Redshift::ClusterSubnetGroup")
    Property("Description", "Cluster subnet group")
    Property("SubnetIds", [
  Ref("PublicSubnet")
])
  end

  Resource("VPC") do
    Type("AWS::EC2::VPC")
    Property("CidrBlock", "10.0.0.0/16")
  end

  Resource("PublicSubnet") do
    Type("AWS::EC2::Subnet")
    Property("CidrBlock", "10.0.0.0/24")
    Property("VpcId", Ref("VPC"))
  end

  Resource("SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Security group")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("InboundTraffic"),
    "FromPort"   => Ref("PortNumber"),
    "IpProtocol" => "tcp",
    "ToPort"     => Ref("PortNumber")
  }
])
    Property("VpcId", Ref("VPC"))
  end

  Resource("myInternetGateway") do
    Type("AWS::EC2::InternetGateway")
  end

  Resource("AttachGateway") do
    Type("AWS::EC2::VPCGatewayAttachment")
    Property("VpcId", Ref("VPC"))
    Property("InternetGatewayId", Ref("myInternetGateway"))
  end

  Resource("PublicRouteTable") do
    Type("AWS::EC2::RouteTable")
    Property("VpcId", Ref("VPC"))
  end

  Resource("PublicRoute") do
    Type("AWS::EC2::Route")
    DependsOn("AttachGateway")
    Property("RouteTableId", Ref("PublicRouteTable"))
    Property("DestinationCidrBlock", "0.0.0.0/0")
    Property("GatewayId", Ref("myInternetGateway"))
  end

  Resource("PublicSubnetRouteTableAssociation") do
    Type("AWS::EC2::SubnetRouteTableAssociation")
    Property("SubnetId", Ref("PublicSubnet"))
    Property("RouteTableId", Ref("PublicRouteTable"))
  end

  Output("ClusterEndpoint") do
    Description("Cluster endpoint")
    Value(FnJoin(":", [
  FnGetAtt("RedshiftCluster", "Endpoint.Address"),
  FnGetAtt("RedshiftCluster", "Endpoint.Port")
]))
  end

  Output("ClusterName") do
    Description("Name of cluster")
    Value(Ref("RedshiftCluster"))
  end

  Output("ParameterGroupName") do
    Description("Name of parameter group")
    Value(Ref("RedshiftClusterParameterGroup"))
  end

  Output("RedshiftClusterSubnetGroupName") do
    Description("Name of cluster subnet group")
    Value(Ref("RedshiftClusterSubnetGroup"))
  end

  Output("RedshiftClusterSecurityGroupName") do
    Description("Name of cluster security group")
    Value(Ref("SecurityGroup"))
  end
end

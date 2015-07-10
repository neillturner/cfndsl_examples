CloudFormation do
  Description("AWS CloudFormation Sample Template VPC_RDS_DB_Instance: Sample template showing how to create an RDS DBInstance in an existing Virtual Private Cloud (VPC). **WARNING** This template creates an Amazon Relational Database Service database instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("VpcId") do
    Description("VpcId of your existing Virtual Private Cloud (VPC)")
    Type("String")
  end

  Parameter("Subnets") do
    Description("The list of SubnetIds, for at least two Availability Zones in the region in your Virtual Private Cloud (VPC)")
    Type("CommaDelimitedList")
  end

  Parameter("DBName") do
    Description("The database name")
    Type("String")
    Default("MyDatabase")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUsername") do
    Description("The database admin account username")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("The database admin account password")
    Type("String")
    Default("password")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBClass") do
    Description("Database instance class")
    Type("String")
    Default("db.m1.small")
    AllowedValues([
  "db.m1.small",
  "db.m1.large",
  "db.m1.xlarge",
  "db.m2.xlarge",
  "db.m2.2xlarge",
  "db.m2.4xlarge"
])
    ConstraintDescription("must select a valid database instance type.")
  end

  Parameter("DBAllocatedStorage") do
    Description("The size of the database (Gb)")
    Type("Number")
    Default("5")
    MaxValue(1024)
    MinValue(5)
    ConstraintDescription("must be between 5 and 1024Gb.")
  end

  Resource("MyDBSubnetGroup") do
    Type("AWS::RDS::DBSubnetGroup")
    Property("DBSubnetGroupDescription", "Subnets available for the RDS DB Instance")
    Property("SubnetIds", Ref("Subnets"))
  end

  Resource("myVPCSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Security group for RDS DB Instance.")
    Property("VpcId", Ref("VpcId"))
  end

  Resource("MyDB") do
    Type("AWS::RDS::DBInstance")
    Property("DBName", Ref("DBName"))
    Property("AllocatedStorage", Ref("DBAllocatedStorage"))
    Property("DBInstanceClass", Ref("DBClass"))
    Property("Engine", "MySQL")
    Property("EngineVersion", "5.5")
    Property("MasterUsername", Ref("DBUsername"))
    Property("MasterUserPassword", Ref("DBPassword"))
    Property("DBSubnetGroupName", Ref("MyDBSubnetGroup"))
    Property("VPCSecurityGroups", [
  Ref("myVPCSecurityGroup")
])
  end

  Output("JDBCConnectionString") do
    Description("JDBC connection string for database")
    Value(FnJoin("", [
  "jdbc:mysql://",
  FnGetAtt("MyDB", "Endpoint.Address"),
  ":",
  FnGetAtt("MyDB", "Endpoint.Port"),
  "/",
  Ref("DBName")
]))
  end
end

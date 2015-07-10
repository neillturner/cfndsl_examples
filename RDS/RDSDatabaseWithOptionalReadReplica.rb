CloudFormation do
  Description("AWS CloudFormation Sample Template RDSDatabaseWithOptionalReadReplica.template: Sample template showing how to create a highly-available, RDS DBInstance version 5.6 with an optional read replica. **WARNING** This template creates an Amazon Relational Database Service database instance and Amazon CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("DBName") do
    Description("The database name")
    Type("String")
    Default("MyDatabase")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBUser") do
    Description("The database admin account username")
    Type("String")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DBPassword") do
    Description("The database admin account password")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("DBAllocatedStorage") do
    Description("The size of the database (Gb)")
    Type("Number")
    Default("5")
    MaxValue(1024)
    MinValue(5)
    ConstraintDescription("must be between 5 and 1024Gb.")
  end

  Parameter("DBInstanceClass") do
    Description("The database instance type")
    Type("String")
    Default("db.m1.small")
    AllowedValues([
  "db.t1.micro",
  "db.m1.small",
  "db.m1.medium",
  "db.m1.large",
  "db.m1.xlarge",
  "db.m2.xlarge",
  "db.m2.2xlarge",
  "db.m2.4xlarge",
  "db.cr1.8xlarge"
])
    ConstraintDescription("must select a valid database instance type.")
  end

  Parameter("EC2SecurityGroup") do
    Description("The EC2 security group that contains instances that need access to the database")
    Type("String")
    Default("default")
  end

  Parameter("MultiAZ") do
    Description("Multi-AZ master database")
    Type("String")
    Default("false")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be true or false.")
  end

  Parameter("ReadReplica") do
    Description("Create a read replica")
    Type("String")
    Default("false")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be true or false.")
  end

  Condition("CreateReadReplica", FnEquals(Ref("ReadReplica"), "true"))

  Resource("MasterDB") do
    Type("AWS::RDS::DBInstance")
    DeletionPolicy("Snapshot")
    Property("DBName", Ref("DBName"))
    Property("AllocatedStorage", Ref("DBAllocatedStorage"))
    Property("DBInstanceClass", Ref("DBInstanceClass"))
    Property("Engine", "MySQL")
    Property("EngineVersion", "5.6")
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("MasterUsername", Ref("DBUser"))
    Property("MasterUserPassword", Ref("DBPassword"))
    Property("MultiAZ", Ref("MultiAZ"))
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "Master Database"
  }
])
  end

  Resource("ReplicaDB") do
    Type("AWS::RDS::DBInstance")
    Condition("CreateReadReplica")
    Property("SourceDBInstanceIdentifier", Ref("MasterDB"))
    Property("DBInstanceClass", Ref("DBInstanceClass"))
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "Read Replica Database"
  }
])
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => Ref("EC2SecurityGroup")
})
    Property("GroupDescription", "database access")
  end

  Output("MasterJDBCConnectionString") do
    Description("JDBC connection string for the master database")
    Value(FnJoin("", [
  "jdbc:mysql://",
  FnGetAtt("MasterDB", "Endpoint.Address"),
  ":",
  FnGetAtt("MasterDB", "Endpoint.Port"),
  "/",
  Ref("DBName")
]))
  end

  Output("ReplicaJDBCConnectionString") do
    Condition("CreateReadReplica")
    Description("JDBC connection string for the replica database")
    Value(FnJoin("", [
  "jdbc:mysql://",
  FnGetAtt("ReplicaDB", "Endpoint.Address"),
  ":",
  FnGetAtt("ReplicaDB", "Endpoint.Port"),
  "/",
  Ref("DBName")
]))
  end
end

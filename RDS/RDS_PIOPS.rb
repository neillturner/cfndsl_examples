CloudFormation do
  Description("AWS CloudFormation Sample Template RDS_PIOPS: Sample template showing how to create an Amazon RDS Database Instance with provisioned IOPs.**WARNING** This template creates an Amazon Relational Database Service database instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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

  Resource("MyDB") do
    Type("AWS::RDS::DBInstance")
    Property("AllocatedStorage", "100")
    Property("DBInstanceClass", "db.m1.small")
    Property("Engine", "MySQL")
    Property("EngineVersion", "5.5")
    Property("Iops", "1000")
    Property("MasterUsername", Ref("DBUser"))
    Property("MasterUserPassword", Ref("DBPassword"))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template RDS_Version: Sample template showing how to create an RDS DBInstance using a specific engine version - in this case the latest of the V5.5 family. **WARNING** This template creates an Amazon Relational Database Service database instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyDB") do
    Type("AWS::RDS::DBInstance")
    Property("AllocatedStorage", "5")
    Property("DBInstanceClass", "db.m1.small")
    Property("Engine", "MySQL")
    Property("EngineVersion", "5.5")
    Property("MasterUsername", "MyName")
    Property("MasterUserPassword", "MyPassword")
  end
end

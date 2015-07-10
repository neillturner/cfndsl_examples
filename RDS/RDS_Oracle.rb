CloudFormation do
  Description("AWS CloudFormation Sample Template RDS_Oracle: Sample template showing how to create an RDS Oracle DBInstance. **WARNING** This template creates an Amazon RDS database instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyDB") do
    Type("AWS::RDS::DBInstance")
    Property("AllocatedStorage", "10")
    Property("DBInstanceClass", "db.m1.small")
    Property("Engine", "oracle-ee")
    Property("LicenseModel", "bring-your-own-license")
    Property("MasterUsername", "MyName")
    Property("MasterUserPassword", "MyPassword")
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template RDS_Snapshot_On_Delete: Sample template showing how to create an RDS DBInstance that is snapshotted on stack deletion. **WARNING** This template creates an Amazon RDS database instance. When the stack is deleted a database snpshot will be left in your account. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyDB") do
    Type("AWS::RDS::DBInstance")
    DeletionPolicy("Snapshot")
    Property("AllocatedStorage", "5")
    Property("DBInstanceClass", "db.m1.small")
    Property("Engine", "MySQL")
    Property("MasterUsername", "MyName")
    Property("MasterUserPassword", "MyPassword")
  end
end

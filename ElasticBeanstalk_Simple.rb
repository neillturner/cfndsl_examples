CloudFormation do
  Description("AWS CloudFormation Sample Template ElasticBeanstalk_Simple: Configure and launch an AWS Elastic Beanstalk application that connects to an Amazon RDS database instance. Monitoring is setup on the database. **WARNING** This template creates one or more Amazon EC2 instances and an Amazon Relational Database Service database instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("DatabaseUser") do
    Description("Test database admin account name")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DatabasePassword") do
    Description("Test database admin account password")
    Type("String")
    Default("password")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(8)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("OperatorEmail") do
    Description("Email address to notify if there are any operational issues")
    Type("String")
    Default("nobody@amazon.com")
  end

  Resource("SampleApplication") do
    Type("AWS::ElasticBeanstalk::Application")
    Property("Description", "AWS Elastic Beanstalk Sample Application")
    Property("ApplicationVersions", [
  {
    "Description"  => "Version 1.0",
    "SourceBundle" => {
      "S3Bucket" => FnJoin("-", [
  "cloudformation-samples",
  Ref("AWS::Region")
]),
      "S3Key"    => "CloudFormationBeanstalkRDSExample.war"
    },
    "VersionLabel" => "Initial Version"
  }
])
    Property("ConfigurationTemplates", [
  {
    "Description"       => "Default Configuration Version 1.0 - with SSH access",
    "OptionSettings"    => [
      {
        "Namespace"  => "aws:elasticbeanstalk:application:environment",
        "OptionName" => "JDBC_CONNECTION_STRING",
        "Value"      => FnJoin("", [
  "jdbc:mysql://",
  FnGetAtt("SampleDB", "Endpoint.Address"),
  ":",
  FnGetAtt("SampleDB", "Endpoint.Port"),
  "/beanstalkdb"
])
      },
      {
        "Namespace"  => "aws:elasticbeanstalk:application:environment",
        "OptionName" => "PARAM1",
        "Value"      => Ref("DatabaseUser")
      },
      {
        "Namespace"  => "aws:elasticbeanstalk:application:environment",
        "OptionName" => "PARAM2",
        "Value"      => Ref("DatabasePassword")
      }
    ],
    "SolutionStackName" => "64bit Amazon Linux running Tomcat 7",
    "TemplateName"      => "DefaultConfiguration"
  }
])
  end

  Resource("SampleEnvironment") do
    Type("AWS::ElasticBeanstalk::Environment")
    Property("ApplicationName", Ref("SampleApplication"))
    Property("Description", "AWS Elastic Beanstalk Environment running Sample Application")
    Property("TemplateName", "DefaultConfiguration")
    Property("VersionLabel", "Initial Version")
  end

  Resource("DBSecurityGroup") do
    Type("AWS::RDS::DBSecurityGroup")
    Property("DBSecurityGroupIngress", {
  "EC2SecurityGroupName" => "elasticbeanstalk-default"
})
    Property("GroupDescription", "database access")
  end

  Resource("SampleDB") do
    Type("AWS::RDS::DBInstance")
    Property("Engine", "MySQL")
    Property("DBName", "beanstalkdb")
    Property("MasterUsername", Ref("DatabaseUser"))
    Property("DBInstanceClass", "db.m1.small")
    Property("DBSecurityGroups", [
  Ref("DBSecurityGroup")
])
    Property("AllocatedStorage", "5")
    Property("MasterUserPassword", Ref("DatabasePassword"))
  end

  Resource("AlarmTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => Ref("OperatorEmail"),
    "Protocol" => "email"
  }
])
  end

  Resource("CPUAlarmHigh") do
    Type("AWS::CloudWatch::Alarm")
    Property("EvaluationPeriods", "10")
    Property("Statistic", "Average")
    Property("Threshold", "50")
    Property("AlarmDescription", "Alarm if CPU too high or metric disappears indicating the RDS database instance is having issues")
    Property("Period", "60")
    Property("Namespace", "AWS/RDS")
    Property("MetricName", "CPUUtilization")
    Property("Dimensions", [
  {
    "Name"  => "DBInstanceIdentifier",
    "Value" => Ref("SampleDB")
  }
])
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
    Property("InsufficientDataActions", [
  Ref("AlarmTopic")
])
  end

  Output("URL") do
    Description("URL of the AWS Elastic Beanstalk Environment")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("SampleEnvironment", "EndpointURL")
]))
  end
end

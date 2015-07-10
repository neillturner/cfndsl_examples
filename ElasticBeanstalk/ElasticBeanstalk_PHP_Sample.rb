CloudFormation do
  Description("AWS CloudFormation Sample Template ElasticBeanstalk_PHP_Sample: Configure and launch the AWS Elastic Beanstalk PHP sample application. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the AWS Elastic Beanstalk instance")
    Type("String")
  end

  Resource("sampleApplication") do
    Type("AWS::ElasticBeanstalk::Application")
    Property("Description", "AWS Elastic Beanstalk PHP Sample Application")
    Property("ApplicationVersions", [
  {
    "Description"  => "Version 1.0",
    "SourceBundle" => {
      "S3Bucket" => FnJoin("-", [
  "elasticbeanstalk-samples",
  Ref("AWS::Region")
]),
      "S3Key"    => "php-sample.zip"
    },
    "VersionLabel" => "Initial Version"
  }
])
    Property("ConfigurationTemplates", [
  {
    "Description"       => "Default Configuration Version 1.0 - with SSH access",
    "OptionSettings"    => [
      {
        "Namespace"  => "aws:autoscaling:launchconfiguration",
        "OptionName" => "EC2KeyName",
        "Value"      => Ref("KeyName")
      }
    ],
    "SolutionStackName" => "64bit Amazon Linux running PHP 5.3",
    "TemplateName"      => "DefaultConfiguration"
  }
])
  end

  Resource("sampleEnvironment") do
    Type("AWS::ElasticBeanstalk::Environment")
    Property("ApplicationName", Ref("sampleApplication"))
    Property("Description", "AWS Elastic Beanstalk Environment running PHP Sample Application")
    Property("TemplateName", "DefaultConfiguration")
    Property("VersionLabel", "Initial Version")
  end

  Output("URL") do
    Description("URL of the AWS Elastic Beanstalk Environment")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("sampleEnvironment", "EndpointURL")
]))
  end
end

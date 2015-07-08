CloudFormation do
  Description("AWS CloudFormation Sample Template ElasticBeanstalkSampleWithRoute53: Configure and launch the AWS Elastic Beanstalk sample application, specifying a custom DNS name using Amazon Route 53. Note, since AWS Elastic Beanstalk is only available in US-East-1, this template can only be used to create stacks in the US-East-1 region. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the AWS Elastic Beanstalk instance")
    Type("String")
  end

  Parameter("DNSName") do
    Description("DNS name for the running environment. The fully qualified DNS name of the environment is created using the DNSName and the DNSZone parameters.")
    Type("String")
  end

  Parameter("DNSZone") do
    Description("The name of an existing Amazon Route 53 hosted zone. The fully qualified DNS name of the environment is created using the DNSName and the DNSZone parameters.")
    Type("String")
  end

  Resource("sampleApplication") do
    Type("AWS::ElasticBeanstalk::Application")
    Property("Description", "AWS Elastic Beanstalk Sample Application")
    Property("ApplicationVersions", [
  {
    "Description"  => "Version 1.0",
    "SourceBundle" => {
      "S3Bucket" => FnJoin("-", [
  "elasticbeanstalk",
  Ref("AWS::Region")
]),
      "S3Key"    => "resources/elasticbeanstalk-sampleapp.war"
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
    "SolutionStackName" => "64bit Amazon Linux running Tomcat 7",
    "TemplateName"      => "DefaultConfiguration"
  }
])
  end

  Resource("sampleEnvironment") do
    Type("AWS::ElasticBeanstalk::Environment")
    Property("ApplicationName", Ref("sampleApplication"))
    Property("Description", "AWS Elastic Beanstalk Environment running Sample Application")
    Property("TemplateName", "DefaultConfiguration")
    Property("VersionLabel", "Initial Version")
  end

  Resource("environmentDNSRecord") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneName", FnJoin("", [
  Ref("DNSZone"),
  "."
]))
    Property("Comment", "CNAME redirect to aws.amazon.com.")
    Property("Name", FnJoin("", [
  Ref("DNSName"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("DNSZone")
]))
    Property("Type", "CNAME")
    Property("TTL", "900")
    Property("ResourceRecords", [
  FnGetAtt("sampleEnvironment", "EndpointURL")
])
  end

  Output("URL") do
    Description("URL of the AWS Elastic Beanstalk Environment")
    Value(FnJoin("", [
  "http://",
  Ref("environmentDNSRecord")
]))
  end
end

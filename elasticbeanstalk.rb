CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("sampleApplication") do
    Type("AWS::ElasticBeanstalk::Application")
    Property("Description", "AWS Elastic Beanstalk Sample Application")
  end

  Resource("sampleApplicationVersion") do
    Type("AWS::ElasticBeanstalk::ApplicationVersion")
    Property("ApplicationName", Ref("sampleApplication"))
    Property("Description", "AWS ElasticBeanstalk Sample Application Version")
    Property("SourceBundle", {
  "S3Bucket" => FnJoin("-", [
  "elasticbeanstalk-samples",
  Ref("AWS::Region")
]),
  "S3Key"    => "php-sample.zip"
})
  end

  Resource("sampleConfigurationTemplate") do
    Type("AWS::ElasticBeanstalk::ConfigurationTemplate")
    Property("ApplicationName", Ref("sampleApplication"))
    Property("Description", "AWS ElasticBeanstalk Sample Configuration Template")
    Property("OptionSettings", [
  {
    "Namespace"  => "aws:autoscaling:asg",
    "OptionName" => "MinSize",
    "Value"      => "2"
  },
  {
    "Namespace"  => "aws:autoscaling:asg",
    "OptionName" => "MaxSize",
    "Value"      => "6"
  },
  {
    "Namespace"  => "aws:elasticbeanstalk:environment",
    "OptionName" => "EnvironmentType",
    "Value"      => "LoadBalanced"
  }
])
    Property("SolutionStackName", "64bit Amazon Linux running PHP 5.3")
  end

  Resource("sampleEnvironment") do
    Type("AWS::ElasticBeanstalk::Environment")
    Property("ApplicationName", Ref("sampleApplication"))
    Property("Description", "AWS ElasticBeanstalk Sample Environment")
    Property("TemplateName", Ref("sampleConfigurationTemplate"))
    Property("VersionLabel", Ref("sampleApplicationVersion"))
  end
end

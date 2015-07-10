CloudFormation do
  Description("A sample template to create a CloudFront distribution with multiple origins (2 origins) --- 1) a custom origin - Sample PHP application created using Elastic Beanstalk, 2) a s3 origin - S3 bucket to store image files in jpeg format. **WARNING** This template creates one or more AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the AWS Elastic Beanstalk instance")
    Type("String")
  end

  Resource("sampleS3OriginBucket") do
    Type("AWS::S3::Bucket")
    Property("AccessControl", "PublicRead")
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

  Resource("sampleS3LoggingBucket") do
    Type("AWS::S3::Bucket")
    Property("AccessControl", "PublicRead")
  end

  Resource("sampleDistribution") do
    Type("AWS::CloudFront::Distribution")
    Property("DistributionConfig", {
  "CacheBehaviors"       => [
    {
      "ForwardedValues"      => {
        "QueryString" => "false"
      },
      "MinTTL"               => "500",
      "PathPattern"          => "*.jpg",
      "TargetOriginId"       => "S3 Origin",
      "ViewerProtocolPolicy" => "allow-all"
    }
  ],
  "Comment"              => "Sample multi-origin CloudFront distribution created using CloudFormation.",
  "DefaultCacheBehavior" => {
    "ForwardedValues"      => {
      "QueryString" => "true"
    },
    "TargetOriginId"       => "Custom Origin",
    "ViewerProtocolPolicy" => "allow-all"
  },
  "DefaultRootObject"    => "index.php",
  "Enabled"              => "true",
  "Logging"              => {
    "Bucket" => FnGetAtt("sampleS3LoggingBucket", "DomainName"),
    "Prefix" => "CloudFrontDistributionSampleLogs"
  },
  "Origins"              => [
    {
      "DomainName"     => FnGetAtt("sampleS3OriginBucket", "DomainName"),
      "Id"             => "S3 Origin",
      "S3OriginConfig" => {}
    },
    {
      "CustomOriginConfig" => {
        "OriginProtocolPolicy" => "match-viewer"
      },
      "DomainName"         => FnGetAtt("sampleEnvironment", "EndpointURL"),
      "Id"                 => "Custom Origin"
    }
  ]
})
  end

  Output("DistributionId") do
    Description("CloudFront Distribution Id")
    Value(Ref("sampleDistribution"))
  end

  Output("DistributionName") do
    Description("URL to access the CloudFront distribution")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("sampleDistribution", "DomainName")
]))
  end

  Output("S3OriginDNSName") do
    Description("DNS Name of the S3 bucket created as a part of this stack, which is treated as an origin to serve .jpg files for the distribution. After the stack has been created, you can upload .jpg files to the S3 bucket, and access them using : <DistributionName>/<ObjectName>, where <DistributionName is the CloudFront distribution url and <ObjectName> is an image file (say Sample.jpg) uploaded to the S3 bucket.")
    Value(FnGetAtt("sampleS3OriginBucket", "DomainName"))
  end
end

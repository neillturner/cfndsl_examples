CloudFormation do
  Description("This sample template creates an HTTP endpoint using AWS Elastic Beanstalk, creates an Amazon SNS topic, and subscribes the HTTP endpoint to that topic. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the Amazon EC2 instance(s) in the environment deployed for the AWS Elastic Beanstalk application in this template.")
    Type("String")
  end

  Parameter("MyPublishUserPassword") do
    Description("Password for the IAM user MyPublishUser")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Resource("MySNSTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => FnJoin("/", [
  "http:/",
  FnGetAtt("MyEndpointEnvironment", "EndpointURL"),
  "myendpoint"
]),
    "Protocol" => "http"
  }
])
  end

  Resource("MyEndpointApplication") do
    Type("AWS::ElasticBeanstalk::Application")
    Property("Description", "HTTP endpoint to receive messages from Amazon SNS subscription.")
    Property("ApplicationVersions", [
  {
    "Description"  => "Version 1.0",
    "SourceBundle" => {
      "S3Bucket" => "@@@CFN_EXAMPLES_DIR@@@",
      "S3Key"    => "sns-http-example.war"
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
    "SolutionStackName" => "32bit Amazon Linux running Tomcat 7",
    "TemplateName"      => "DefaultConfiguration"
  }
])
  end

  Resource("MyEndpointEnvironment") do
    Type("AWS::ElasticBeanstalk::Environment")
    Property("ApplicationName", Ref("MyEndpointApplication"))
    Property("Description", "AWS Elastic Beanstalk Environment running HTTP endpoint for Amazon SNS subscription.")
    Property("TemplateName", "DefaultConfiguration")
    Property("VersionLabel", "Initial Version")
  end

  Resource("MyPublishUser") do
    Type("AWS::IAM::User")
    Property("LoginProfile", {
  "Password" => Ref("MyPublishUserPassword")
})
  end

  Resource("MyPublishUserKey") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("MyPublishUser"))
  end

  Resource("MyPublishTopicGroup") do
    Type("AWS::IAM::Group")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "sns:Publish"
          ],
          "Effect"   => "Allow",
          "Resource" => Ref("MySNSTopic")
        }
      ]
    },
    "PolicyName"     => "MyTopicGroupPolicy"
  }
])
  end

  Resource("AddUserToMyPublishTopicGroup") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", Ref("MyPublishTopicGroup"))
    Property("Users", [
  Ref("MyPublishUser")
])
  end

  Output("MySNSTopicTopicARN") do
    Description("ARN for MySNSTopic.")
    Value(Ref("MySNSTopic"))
  end

  Output("MyPublishUserInfo") do
    Description("Information about MyPublishUser.")
    Value(FnJoin(" ", [
  "ARN:",
  FnGetAtt("MyPublishUser", "Arn"),
  "Access Key:",
  Ref("MyPublishUserKey"),
  "Secret Key:",
  FnGetAtt("MyPublishUserKey", "SecretAccessKey")
]))
  end

  Output("URL") do
    Description("URL of the HTTP endpoint hosted on AWS Elastic Beanstalk and subscribed to topic.")
    Value(FnJoin("/", [
  "http:/",
  FnGetAtt("MyEndpointEnvironment", "EndpointURL"),
  "myendpoint"
]))
  end
end

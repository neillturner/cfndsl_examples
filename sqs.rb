CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyQueue") do
    Type("AWS::SQS::Queue")
    Property("VisibilityTimeout", "value")
  end
end

CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

# Amazon SQS Queue Snippet
  Resource("MyQueue") do
    Type("AWS::SQS::Queue")
    Property("VisibilityTimeout", "value")
  end
end

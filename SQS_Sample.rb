CloudFormation do
  Description("AWS CloudFormation Sample Template SQS: Sample template showing how to create an SQS queue. **WARNING** This template creates an Amazon SQS Queue. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyQueue") do
    Type("AWS::SQS::Queue")
  end

  Output("QueueURL") do
    Description("URL of newly created SQS Queue")
    Value(Ref("MyQueue"))
  end

  Output("QueueARN") do
    Description("ARN of newly created SQS Queue")
    Value(FnGetAtt("MyQueue", "Arn"))
  end
end

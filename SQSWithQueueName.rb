CloudFormation do
  Description("AWS CloudFormation Sample Template SQSWithQueueName: Sample template showing how to create an SQS queue with a specific name. **WARNING** This template creates an Amazon SQS Queue. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("QueueName") do
    Description("Name of queue to create")
    Type("String")
    AllowedPattern("[a-zA-Z0-9_-]+")
    MaxLength(80)
    MinLength(1)
    ConstraintDescription("must be a valid queue name.")
  end

  Resource("MyQueue") do
    Type("AWS::SQS::Queue")
    Property("QueueName", Ref("QueueName"))
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

CloudFormation do
  Description("AWS CloudFormation Sample Template SQS_With_CloudWatch_Alarms: Sample template showing how to create an SQS queue with AWS CloudWatch alarms on queue depth. **WARNING** This template creates an Amazon SQS Queue and one or more Amazon CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("AlarmEmail") do
    Description("Email address to notify if there are any operational issues")
    Type("String")
    Default("nobody@amazon.com")
  end

  Resource("MyQueue") do
    Type("AWS::SQS::Queue")
  end

  Resource("AlarmTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => Ref("AlarmEmail"),
    "Protocol" => "email"
  }
])
  end

  Resource("QueueDepthAlarm") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Alarm if queue depth grows beyond 10 messages")
    Property("Namespace", "AWS/SQS")
    Property("MetricName", "ApproximateNumberOfMessagesVisible")
    Property("Dimensions", [
  {
    "Name"  => "QueueName",
    "Value" => FnGetAtt("MyQueue", "QueueName")
  }
])
    Property("Statistic", "Sum")
    Property("Period", "300")
    Property("EvaluationPeriods", "1")
    Property("Threshold", "10")
    Property("ComparisonOperator", "GreaterThanThreshold")
    Property("AlarmActions", [
  Ref("AlarmTopic")
])
    Property("InsufficientDataActions", [
  Ref("AlarmTopic")
])
  end

  Output("QueueURL") do
    Description("URL of newly created SQS Queue")
    Value(Ref("MyQueue"))
  end

  Output("QueueARN") do
    Description("ARN of newly created SQS Queue")
    Value(FnGetAtt("MyQueue", "Arn"))
  end

  Output("QueueName") do
    Description("Name newly created SQS Queue")
    Value(FnGetAtt("MyQueue", "QueueName"))
  end
end

CloudFormation do
  Description("AWS CloudFormation Sample Template IAM_Policies_SNS_Publish_To_SQS: Sample template showing how to grant rights so that you can publish SNS notifications to an SQS queue. Note that you will need to specify the CAPABILITY_IAM flag when you create the stack to allow this template to execute. You can do this through the AWS management console by clicking on the check box acknowledging that you understand this template creates IAM resources or by specifying the CAPABILITY_IAM flag to the cfn-create-stack command line tool or CreateStack API call. **WARNING** This template creates an Amazon SQS queue and an Amazon SNS topic. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("SQSQueue") do
    Type("AWS::SQS::Queue")
  end

  Resource("SNSTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => FnGetAtt("SQSQueue", "Arn"),
    "Protocol" => "sqs"
  }
])
  end

  Resource("AllowSNS2SQSPolicy") do
    Type("AWS::SQS::QueuePolicy")
    Property("Queues", [
  Ref("SQSQueue")
])
    Property("PolicyDocument", {
  "Id"        => "PublicationPolicy",
  "Statement" => [
    {
      "Action"    => [
        "sqs:SendMessage"
      ],
      "Condition" => {
        "ArnEquals" => {
          "aws:SourceArn" => Ref("SNSTopic")
        }
      },
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => "*"
      },
      "Resource"  => FnGetAtt("SQSQueue", "Arn"),
      "Sid"       => "Allow-SNS-SendMessage"
    }
  ],
  "Version"   => "2008-10-17"
})
  end

  Output("QueueArn") do
    Description("ARN of SQS Queue")
    Value(FnGetAtt("SQSQueue", "Arn"))
  end

  Output("TopicArn") do
    Description("ARN of SNS Topic")
    Value(Ref("SNSTopic"))
  end
end

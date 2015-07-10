CloudFormation do
  Description("This Template creates an SNS topic that can send messages to two SQS queues with appropriate permissions for one IAM user to publish to the topic and another to read messages from the queues. MySNSTopic is set up to publish to two subscribed endpoints, which are two SQS queues (MyQueue1 and MyQueue2). MyPublishUser is an IAM user that can publish to MySNSTopic using the Publish API. MyTopicPolicy assigns that permission to MyPublishUser. MyQueueUser is an IAM user that can read messages from the two SQS queues. MyQueuePolicy assigns those permissions to MyQueueUser. It also assigns permission for MySNSTopic to publish its notifications to the two queues. The template creates access keys for the two IAM users with MyPublishUserKey and MyQueueUserKey.  Note that you will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("MyPublishUserPassword") do
    Description("Password for the IAM user MyPublishUser")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("MyQueueUserPassword") do
    Description("Password for the IAM user MyQueueUser")
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
    "Endpoint" => FnGetAtt("MyQueue1", "Arn"),
    "Protocol" => "sqs"
  },
  {
    "Endpoint" => FnGetAtt("MyQueue2", "Arn"),
    "Protocol" => "sqs"
  }
])
  end

  Resource("MyQueue1") do
    Type("AWS::SQS::Queue")
  end

  Resource("MyQueue2") do
    Type("AWS::SQS::Queue")
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

  Resource("MyQueueUser") do
    Type("AWS::IAM::User")
    Property("LoginProfile", {
  "Password" => Ref("MyQueueUserPassword")
})
  end

  Resource("MyQueueUserKey") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("MyQueueUser"))
  end

  Resource("MyRDMessageQueueGroup") do
    Type("AWS::IAM::Group")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "sqs:DeleteMessage",
            "sqs:ReceiveMessage"
          ],
          "Effect"   => "Allow",
          "Resource" => [
            FnGetAtt("MyQueue1", "Arn"),
            FnGetAtt("MyQueue2", "Arn")
          ]
        }
      ]
    },
    "PolicyName"     => "MyQueueGroupPolicy"
  }
])
  end

  Resource("AddUserToMyQueueGroup") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", Ref("MyRDMessageQueueGroup"))
    Property("Users", [
  Ref("MyQueueUser")
])
  end

  Resource("MyQueuePolicy") do
    Type("AWS::SQS::QueuePolicy")
    Property("PolicyDocument", {
  "Id"        => "MyQueuePolicy",
  "Statement" => [
    {
      "Action"    => [
        "sqs:SendMessage"
      ],
      "Condition" => {
        "ArnEquals" => {
          "aws:SourceArn" => Ref("MySNSTopic")
        }
      },
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => "*"
      },
      "Resource"  => "*",
      "Sid"       => "Allow-SendMessage-To-Both-Queues-From-SNS-Topic"
    }
  ]
})
    Property("Queues", [
  Ref("MyQueue1"),
  Ref("MyQueue2")
])
  end

  Output("MySNSTopicTopicARN") do
    Value(Ref("MySNSTopic"))
  end

  Output("MyQueue1Info") do
    Value(FnJoin(" ", [
  "ARN:",
  FnGetAtt("MyQueue1", "Arn"),
  "URL:",
  Ref("MyQueue1")
]))
  end

  Output("MyQueue2Info") do
    Value(FnJoin(" ", [
  "ARN:",
  FnGetAtt("MyQueue2", "Arn"),
  "URL:",
  Ref("MyQueue2")
]))
  end

  Output("MyPublishUserInfo") do
    Value(FnJoin(" ", [
  "ARN:",
  FnGetAtt("MyPublishUser", "Arn"),
  "Access Key:",
  Ref("MyPublishUserKey"),
  "Secret Key:",
  FnGetAtt("MyPublishUserKey", "SecretAccessKey")
]))
  end

  Output("MyQueueUserInfo") do
    Value(FnJoin(" ", [
  "ARN:",
  FnGetAtt("MyQueueUser", "Arn"),
  "Access Key:",
  Ref("MyQueueUserKey"),
  "Secret Key:",
  FnGetAtt("MyQueueUserKey", "SecretAccessKey")
]))
  end
end

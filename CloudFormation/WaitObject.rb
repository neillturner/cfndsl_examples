CloudFormation do
  Description("Example template showing how the WaitCondition and WaitConditionHandle are configured. With this template, the stack will not complete until either the WaitCondition timeout occurs, or you manually signal the WaitCondition object using the URL created by the WaitConditionHandle. You can use CURL or some other equivalent mechanism to signal the WaitCondition. To find the URL, use cfn-describe-stack-resources or the AWS Management Console to display the PhysicalResourceId of the WaitConditionHandle - this is the URL to use to signal. For details of the signal request see the AWS CloudFormation User Guide at http://docs.amazonwebservices.com/AWSCloudFormation/latest/UserGuide/")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("myWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("myWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    Property("Handle", Ref("myWaitHandle"))
    Property("Timeout", "300")
  end

  Output("ApplicationData") do
    Description("The data passed back as part of signalling the WaitCondition")
    Value(FnGetAtt("myWaitCondition", "Data"))
  end
end

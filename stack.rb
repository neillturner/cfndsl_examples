CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("myStackWithParams") do
    Type("AWS::CloudFormation::Stack")
    Property("TemplateURL", "https://s3.amazonaws.com/cloudformation-templates-us-east-1/EC2ChooseAMI.template")
    Property("Parameters", {
  "InstanceType" => "t1.micro",
  "KeyName"      => "mykey"
})
    Property("TimeoutInMinutes", "60")
  end

  Output("StackRef") do
    Value(Ref("myStackWithParams"))
  end

  Output("OutputFromNestedStack") do
    Value(FnGetAtt("myStackWithParams", "Outputs.BucketName"))
  end
end

CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

# Amazon SNS Topic Resource
  Resource("MySNSTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => "add valid email address",
    "Protocol" => "email"
  }
])
  end
end

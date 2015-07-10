CloudFormation do
  Description("AWS CloudFormation Sample Template CloudFront_S3: Sample template showing how to create an Amazon CloudFront distribution using an S3 origin. **WARNING** This template creates one or more AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("S3DNSName") do
    Description("The DNS name of an existing S3 bucket to use as the Cloudfront distribution origin")
    Type("String")
  end

  Resource("myDistribution") do
    Type("AWS::CloudFront::Distribution")
    Property("DistributionConfig", {
  "Enabled"  => "true",
  "S3Origin" => {
    "DNSName" => Ref("S3DNSName")
  }
})
  end

  Output("DistributionId") do
    Value(Ref("myDistribution"))
  end

  Output("DistributionName") do
    Value(FnJoin("", [
  "http://",
  FnGetAtt("myDistribution", "DomainName")
]))
  end
end

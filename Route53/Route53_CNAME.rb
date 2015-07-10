CloudFormation do
  Description("AWS CloudFormation Sample Template Route53_CNAME: Sample template showing how to create an Amazon Route 53 CNAME record.  It assumes that you already have a Hosted Zone registered with Amazon Route 53. **WARNING** This template creates one or more AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
    Type("String")
  end

  Resource("myDNSRecord") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneName", FnJoin("", [
  Ref("HostedZone"),
  "."
]))
    Property("Comment", "CNAME redirect to aws.amazon.com.")
    Property("Name", FnJoin("", [
  Ref("AWS::StackName"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone"),
  "."
]))
    Property("Type", "CNAME")
    Property("TTL", "900")
    Property("ResourceRecords", [
  "aws.amazon.com"
])
  end

  Output("CNAME") do
    Value(Ref("myDNSRecord"))
  end
end

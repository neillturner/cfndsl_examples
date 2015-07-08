CloudFormation do
  Description("AWS CloudFormation Sample Template Route53_RoundRobin: Sample template showing how to use weighted round robin (WRR) DNS entried via Amazon Route 53. This contrived sample uses weighted CNAME records to illustrate that the weighting influences the return records. It assumes that you already have a Hosted Zone registered with Amazon Route 53. **WARNING** This template creates one or more AWS resources. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
    Type("String")
  end

  Resource("myDNSRecord") do
    Type("AWS::Route53::RecordSetGroup")
    Property("HostedZoneName", FnJoin("", [
  Ref("HostedZone"),
  "."
]))
    Property("Comment", "Contrived example to redirect to aws.amazon.com 75% of the time and www.amazon.com 25% of the time.")
    Property("RecordSets", [
  {
    "Name"            => FnJoin("", [
  Ref("AWS::StackId"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone"),
  "."
]),
    "ResourceRecords" => [
      "aws.amazon.com"
    ],
    "SetIdentifier"   => FnJoin(" ", [
  Ref("AWS::StackId"),
  "AWS"
]),
    "TTL"             => "900",
    "Type"            => "CNAME",
    "Weight"          => "3"
  },
  {
    "Name"            => FnJoin("", [
  Ref("AWS::StackId"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone"),
  "."
]),
    "ResourceRecords" => [
      "www.amazon.com"
    ],
    "SetIdentifier"   => FnJoin(" ", [
  Ref("AWS::StackId"),
  "Amazon"
]),
    "TTL"             => "900",
    "Type"            => "CNAME",
    "Weight"          => "1"
  }
])
  end
end

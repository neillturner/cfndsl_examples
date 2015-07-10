CloudFormation do
  Description("AWS CloudFormation Sample Template S3_Website_With_CloudFront_Distribution: Sample template showing how to create a website with a custom DNS name, hosted on Amazon S3 and served via Amazone CloudFront. It assumes you already have a Hosted Zone registered with Amazon Route 53. **WARNING** This template creates an Amazon Route 53 DNS record, an S3 bucket and a CloudFront distribution. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
    Type("String")
  end

  Resource("S3BucketForWebsiteContent") do
    Type("AWS::S3::Bucket")
    Property("AccessControl", "PublicRead")
    Property("WebsiteConfiguration", {
  "ErrorDocument" => "error.html",
  "IndexDocument" => "index.html"
})
  end

  Resource("WebsiteCDN") do
    Type("AWS::CloudFront::Distribution")
    Property("DistributionConfig", {
  "CNAMEs"            => [
    FnJoin("", [
  Ref("AWS::StackId"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone")
])
  ],
  "Comment"           => "CDN for S3-backed website",
  "CustomOrigin"      => {
    "DNSName"              => FnJoin("", [
  Ref("S3BucketForWebsiteContent"),
  ".s3-website-",
  Ref("AWS::Region"),
  ".amazonaws.com"
]),
    "HTTPPort"             => "80",
    "HTTPSPort"            => "443",
    "OriginProtocolPolicy" => "http-only"
  },
  "DefaultRootObject" => "index.html",
  "Enabled"           => "true"
})
  end

  Resource("WebsiteDNSName") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneName", FnJoin("", [
  Ref("HostedZone"),
  "."
]))
    Property("Comment", "CNAME redirect custom name to CloudFront distribution")
    Property("Name", FnJoin("", [
  Ref("AWS::StackId"),
  ".",
  Ref("AWS::Region"),
  ".",
  Ref("HostedZone")
]))
    Property("Type", "CNAME")
    Property("TTL", "900")
    Property("ResourceRecords", [
  FnJoin("", [
  "http://",
  FnGetAtt("WebsiteCDN", "DomainName")
])
])
  end

  Output("WebsiteURL") do
    Description("The URL of the newly created website")
    Value(FnJoin("", [
  "http://",
  Ref("WebsiteDNSName")
]))
  end

  Output("BucketName") do
    Description("Name of S3 bucket to hold website content")
    Value(Ref("S3BucketForWebsiteContent"))
  end
end

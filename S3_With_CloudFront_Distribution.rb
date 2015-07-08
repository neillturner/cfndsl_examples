CloudFormation do
  Description("AWS CloudFormation Sample Template S3_With_CloudFront_Distribution: Sample template showing how to create a website with a custom DNS name, hosted on Amazon S3 and served via Amazone CloudFront. It assumes you already have a Hosted Zone registered with Amazon Route 53. **WARNING** This template creates an Amazon Route 53 DNS record, an S3 bucket and a CloudFront distribution. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HostedZone") do
    Description("The DNS name of an existing Amazon Route 53 hosted zone")
    Type("String")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "s3BucketDomain" => ".s3-ap-northeast-1.amazonaws.com"
  },
  "ap-southeast-1" => {
    "s3BucketDomain" => ".s3-ap-southeast-1.amazonaws.com"
  },
  "ap-southeast-2" => {
    "s3BucketDomain" => ".s3-ap-southeast-2.amazonaws.com"
  },
  "eu-west-1"      => {
    "s3BucketDomain" => ".s3-eu-west-1.amazonaws.com"
  },
  "sa-east-1"      => {
    "s3BucketDomain" => ".s3-sa-east-1.amazonaws.com"
  },
  "us-east-1"      => {
    "s3BucketDomain" => ".s3.amazonaws.com"
  },
  "us-west-1"      => {
    "s3BucketDomain" => ".s3-us-west-1.amazonaws.com"
  },
  "us-west-2"      => {
    "s3BucketDomain" => ".s3-us-west-2.amazonaws.com"
  }
})

  Resource("S3BucketForWebsiteContent") do
    Type("AWS::S3::Bucket")
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
  FnFindInMap("RegionMap", Ref("AWS::Region"), "s3BucketDomain")
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

CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("RootDomainName") do
    Description("Domain name for your website (example.com)")
    Type("String")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "S3hostedzoneID"  => "Z2M4EHUR26P7ZW",
    "websiteendpoint" => "s3-website-ap-northeast-1.amazonaws.com"
  },
  "ap-southeast-1" => {
    "S3hostedzoneID"  => "Z3O0J2DXBE1FTB",
    "websiteendpoint" => "s3-website-ap-southeast-1.amazonaws.com"
  },
  "ap-southeast-2" => {
    "S3hostedzoneID"  => "Z1WCIGYICN2BYD",
    "websiteendpoint" => "s3-website-ap-southeast-2.amazonaws.com"
  },
  "eu-west-1"      => {
    "S3hostedzoneID"  => "Z1BKCTXD74EZPE",
    "websiteendpoint" => "s3-website-eu-west-1.amazonaws.com"
  },
  "sa-east-1"      => {
    "S3hostedzoneID"  => "Z31GFT0UA1I2HV",
    "websiteendpoint" => "s3-website-sa-east-1.amazonaws.com"
  },
  "us-east-1"      => {
    "S3hostedzoneID"  => "Z3AQBSTGFYJSTF",
    "websiteendpoint" => "s3-website-us-east-1.amazonaws.com"
  },
  "us-west-1"      => {
    "S3hostedzoneID"  => "Z2F56UZL2M1ACD",
    "websiteendpoint" => "s3-website-us-west-1.amazonaws.com"
  },
  "us-west-2"      => {
    "S3hostedzoneID"  => "Z3BJ6K6RIION7M",
    "websiteendpoint" => "s3-website-us-west-2.amazonaws.com"
  }
})

  Resource("RootBucket") do
    Type("AWS::S3::Bucket")
    Property("BucketName", Ref("RootDomainName"))
    Property("AccessControl", "PublicRead")
    Property("WebsiteConfiguration", {
  "ErrorDocument" => "404.html",
  "IndexDocument" => "index.html"
})
  end

  Resource("WWWBucket") do
    Type("AWS::S3::Bucket")
    Property("BucketName", FnJoin("", [
  "www.",
  Ref("RootDomainName")
]))
    Property("AccessControl", "BucketOwnerFullControl")
    Property("WebsiteConfiguration", {
  "RedirectAllRequestsTo" => {
    "HostName" => Ref("RootBucket")
  }
})
  end

  Resource("myDNS") do
    Type("AWS::Route53::RecordSetGroup")
    Property("HostedZoneName", FnJoin("", [
  Ref("RootDomainName"),
  "."
]))
    Property("Comment", "Zone apex alias.")
    Property("RecordSets", [
  {
    "AliasTarget" => {
      "DNSName"      => FnFindInMap("RegionMap", Ref("AWS::Region"), "websiteendpoint"),
      "HostedZoneId" => FnFindInMap("RegionMap", Ref("AWS::Region"), "S3hostedzoneID")
    },
    "Name"        => Ref("RootDomainName"),
    "Type"        => "A"
  },
  {
    "Name"            => FnJoin("", [
  "www.",
  Ref("RootDomainName")
]),
    "ResourceRecords" => [
      FnGetAtt("WWWBucket", "DomainName")
    ],
    "TTL"             => "900",
    "Type"            => "CNAME"
  }
])
  end

  Output("WebsiteURL") do
    Description("URL for website hosted on S3")
    Value(FnGetAtt("RootBucket", "WebsiteURL"))
  end
end

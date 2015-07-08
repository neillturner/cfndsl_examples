CloudFormation do
  Description("AWS CloudFormation Sample Template S3_Website_Bucket_With_Retain_On_Delete: Sample template showing how to create a publicly accessible S3 bucket configured for website access with a deletion policy of retail on delete. **WARNING** This template creates an S3 bucket that will NOT be deleted when the stack is deleted. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("S3Bucket") do
    Type("AWS::S3::Bucket")
    DeletionPolicy("Retain")
    Property("AccessControl", "PublicRead")
    Property("WebsiteConfiguration", {
  "ErrorDocument" => "error.html",
  "IndexDocument" => "index.html"
})
  end

  Output("WebsiteURL") do
    Description("URL for website hosted on S3")
    Value(FnGetAtt("S3Bucket", "WebsiteURL"))
  end

  Output("S3BucketSecureURL") do
    Description("Name of S3 bucket to hold website content")
    Value(FnJoin("", [
  "https://",
  FnGetAtt("S3Bucket", "DomainName")
]))
  end
end

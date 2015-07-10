CloudFormation do
  Description("AWS CloudFormation Sample Template S3_Bucket_With_Tags: Sample template showing how to create a publicly accessible S3 bucket that has tags. **WARNING** This template creates an S3 bucket. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("S3Bucket") do
    Type("AWS::S3::Bucket")
    Property("AccessControl", "PublicRead")
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "My Bucket"
  }
])
  end

  Output("BucketName") do
    Description("Name of S3 bucket to hold website content")
    Value(Ref("S3Bucket"))
  end
end

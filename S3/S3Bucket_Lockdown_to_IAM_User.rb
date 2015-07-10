CloudFormation do
  Description("AWS CloudFormation Sample Template S3Bucket_Lockdown_to_IAM_User: Simple test template showing how to create a bucket and an IAM user and lock the bucket down to be accessible by that new user. **WARNING** This template creates an Amazon S3 Bucket. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("Password") do
    Description("IAM user login password")
    Type("String")
    NoEcho(true)
    MaxLength(50)
    MinLength(3)
  end

  Resource("S3Bucket") do
    Type("AWS::S3::Bucket")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "Give access to user",
  "Statement" => [
    {
      "Action"    => [
        "s3:*"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("S3User", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("S3Bucket")
]),
      "Sid"       => "AllAccess"
    }
  ]
})
    Property("Bucket", Ref("S3Bucket"))
  end

  Resource("S3User") do
    Type("AWS::IAM::User")
    Property("LoginProfile", {
  "Password" => Ref("Password")
})
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => "s3:ListAllMyBuckets",
          "Effect"   => "Allow",
          "Resource" => "*"
        },
        {
          "Action"   => "s3:*",
          "Effect"   => "Allow",
          "Resource" => FnJoin("", [
  "arn:aws:s3:::",
  Ref("S3Bucket"),
  "/*"
])
        }
      ]
    },
    "PolicyName"     => "S3Access"
  }
])
  end

  Output("IAMUser") do
    Description("IAM User for customer")
    Value(Ref("S3User"))
  end

  Output("BucketName") do
    Description("Name of newly created customer S3 bucket")
    Value(Ref("S3Bucket"))
  end
end

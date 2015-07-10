CloudFormation do
  Description("AWS CloudFormation Sample Template IAM_Policies_for_S3: Sample template showing how to create an IAM user with access to an S3 bucket via an IAM policy. Note that you will need to specify the CAPABILITY_IAM flag when you create the stack to allow this template to execute. You can do this through the AWS management console by clicking on the check box acknowledging that you understand this template creates IAM resources or by specifying the CAPABILITY_IAM flag to the cfn-create-stack command line tool or CreateStack API call. **WARNING** This template creates an Amazon S3 bucket. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("S3Bucket") do
    Type("AWS::S3::Bucket")
  end

  Resource("S3User") do
    Type("AWS::IAM::User")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "MyPolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:GetObject"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("S3User", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("S3Bucket"),
  "/*"
]),
      "Sid"       => "ReadAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("S3Bucket"))
  end

  Output("BucketName") do
    Description("Name of newly created S3 bucket")
    Value(Ref("S3Bucket"))
  end
end

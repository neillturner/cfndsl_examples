CloudFormation do
  Description("AWS CloudFormation Sample Template IAM_Users_Groups_and_Policies: Sample template showing how to create IAM users, groups and policies. It creates a single user that is a member of a users group and an admin group. The groups each have different IAM policies associated with them. Note: This example also creates an AWSAccessKeyId/AWSSecretKey pair associated with the new user. The example is somewhat contrived since it creates all of the users and groups, typically you would be creating policies, users and/or groups that contain referemces to existing users or groups in your environment. Note that you will need to specify the CAPABILITY_IAM flag when you create the stack to allow this template to execute. You can do this through the AWS management console by clicking on the check box acknowledging that you understand this template creates IAM resources or by specifying the CAPABILITY_IAM flag to the cfn-create-stack command line tool or CreateStack API call. ")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("Password") do
    Description("New account password")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Resource("CFNUser") do
    Type("AWS::IAM::User")
    Property("LoginProfile", {
  "Password" => Ref("Password")
})
  end

  Resource("CFNUserGroup") do
    Type("AWS::IAM::Group")
  end

  Resource("CFNAdminGroup") do
    Type("AWS::IAM::Group")
  end

  Resource("Users") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", Ref("CFNUserGroup"))
    Property("Users", [
  Ref("CFNUser")
])
  end

  Resource("Admins") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", Ref("CFNAdminGroup"))
    Property("Users", [
  Ref("CFNUser")
])
  end

  Resource("CFNUserPolicies") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "CFNUsers")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => [
        "cloudformation:Describe*",
        "cloudformation:List*",
        "cloudformation:Get*"
      ],
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Groups", [
  Ref("CFNUserGroup")
])
  end

  Resource("CFNAdminPolicies") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "CFNAdmins")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => "cloudformation:*",
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Groups", [
  Ref("CFNAdminGroup")
])
  end

  Resource("CFNKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("CFNUser"))
  end

  Output("AccessKey") do
    Description("AWSAccessKeyId of new user")
    Value(Ref("CFNKeys"))
  end

  Output("SecretKey") do
    Description("AWSSecretKey of new user")
    Value(FnGetAtt("CFNKeys", "SecretAccessKey"))
  end
end

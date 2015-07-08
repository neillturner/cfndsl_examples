CloudFormation do
  Description("AWS CloudFormation Sample Template Mutually_Referencing_EC2_Security_Groups: Sample template showing how to create 2 EC2 security groups that mutually reference each other")
  AWSTemplateFormatVersion("2010-09-09")

  Resource("SGroup1") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "EC2 Instance access")
  end

  Resource("SGroup2") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "EC2 Instance access")
  end

  Resource("SGroup1Ingress") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("SGroup1"))
    Property("IpProtocol", "tcp")
    Property("ToPort", "80")
    Property("FromPort", "80")
    Property("SourceSecurityGroupName", Ref("SGroup2"))
  end

  Resource("SGroup2Ingress") do
    Type("AWS::EC2::SecurityGroupIngress")
    Property("GroupName", Ref("SGroup2"))
    Property("IpProtocol", "tcp")
    Property("ToPort", "80")
    Property("FromPort", "80")
    Property("SourceSecurityGroupName", Ref("SGroup1"))
  end
end

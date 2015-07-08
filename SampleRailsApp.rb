CloudFormation do
  Description("AWS CloudFormation Sample Template SampleRailsApp: This sample template shows how to use AWS CloudFormation with the Amazon Linux AMI Cloud-init feature to instantiate an application at runtime. The sample uses the WaitCondition resource to synchronize creation of the stack with the application becoming healthy. **WARNING** This template creates an Amazon EC2 instance and an Elastic IP Address. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the instance")
    Type("String")
  end

  Parameter("SSHLocation") do
    Description(" The IP address range that can be used to SSH to the EC2 instances")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Mapping("RegionMap", {
  "ap-northeast-1" => {
    "AMI" => "ami-dcfa4edd"
  },
  "ap-southeast-1" => {
    "AMI" => "ami-74dda626"
  },
  "ap-southeast-2" => {
    "AMI" => "ami-b3990e89"
  },
  "eu-west-1"      => {
    "AMI" => "ami-24506250"
  },
  "sa-east-1"      => {
    "AMI" => "ami-3e3be423"
  },
  "us-east-1"      => {
    "AMI" => "ami-7f418316"
  },
  "us-west-1"      => {
    "AMI" => "ami-951945d0"
  },
  "us-west-2"      => {
    "AMI" => "ami-16fd7026"
  }
})

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("KeyName", Ref("KeyName"))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -ex",
  "\n",
  "yum -y install gcc-c++ make",
  "\n",
  "yum -y install mysql-devel sqlite-devel",
  "\n",
  "yum -y install ruby-rdoc rubygems ruby-mysql ruby-devel",
  "\n",
  "gem install --no-ri --no-rdoc rails",
  "\n",
  "gem install --no-ri --no-rdoc mysql",
  "\n",
  "gem install --no-ri --no-rdoc sqlite3",
  "\n",
  "rails new myapp",
  "\n",
  "cd myapp",
  "\n",
  "rails server -d",
  "\n",
  "curl -X PUT -H 'Content-Type:' --data-binary '{\"Status\" : \"SUCCESS\",",
  "\"Reason\" : \"The application myapp is ready\",",
  "\"UniqueId\" : \"myapp\",",
  "\"Data\" : \"Done\"}' ",
  "\"",
  Ref("WaitForInstanceWaitHandle"),
  "\"\n"
])))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable Access to Rails application via port 3000 and SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "3000",
    "IpProtocol" => "tcp",
    "ToPort"     => "3000"
  }
])
  end

  Resource("WaitForInstanceWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WaitForInstance") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("Ec2Instance")
    Property("Handle", Ref("WaitForInstanceWaitHandle"))
    Property("Timeout", "600")
  end

  Output("WebsiteURL") do
    Description("The URL for the newly created Rails application")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("Ec2Instance", "PublicDnsName"),
  ":3000"
]))
  end
end

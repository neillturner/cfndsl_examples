CloudFormation do
  Description("This template demonstrates using embedded templates to build an end to end solution from basic building blocks. It builds a WordPress installation using an RDS database backend configured via a Puppet Master. **WARNING** This template creates one or more Amazon EC2 instances and CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
    Type("String")
  end

  Parameter("PuppetClientSecurityGroup") do
    Description("The EC2 security group for the instances")
    Type("String")
  end

  Parameter("PuppetMasterDNSName") do
    Description("The PuppetMaster DNS name")
    Type("String")
  end

  Parameter("InstanceType") do
    Description("WebServer EC2 instance type")
    Type("String")
    Default("m1.small")
    AllowedValues([
  "t1.micro",
  "m1.small",
  "m1.medium",
  "m1.large",
  "m1.xlarge",
  "m2.xlarge",
  "m2.2xlarge",
  "m2.4xlarge",
  "m3.xlarge",
  "m3.2xlarge",
  "c1.medium",
  "c1.xlarge",
  "cc1.4xlarge",
  "cc2.8xlarge",
  "cg1.4xlarge"
])
    ConstraintDescription("must be a valid EC2 instance type.")
  end

  Parameter("DatabaseType") do
    Description("The database instance type")
    Type("String")
    Default("db.m1.small")
    AllowedValues([
  "db.m1.small",
  "db.m1.large",
  "db.m1.xlarge",
  "db.m2.xlarge",
  "db.m2.2xlarge",
  "db.m2.4xlarge"
])
    ConstraintDescription("must be a valid RDS DB Instance type.")
  end

  Parameter("DatabaseUser") do
    Description("Test database admin account name")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(16)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("DatabasePassword") do
    Description("Test database admin account password")
    Type("String")
    Default("admin")
    AllowedPattern("[a-zA-Z0-9]*")
    NoEcho(true)
    MaxLength(41)
    MinLength(1)
    ConstraintDescription("must contain only alphanumeric characters.")
  end

  Parameter("OperatorEmail") do
    Description("EMail address to notify if there are operational issues")
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
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-ap-northeast-1"
  },
  "ap-southeast-1" => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-ap-southeast-1"
  },
  "ap-southeast-2" => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-ap-southeast-2"
  },
  "eu-west-1"      => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-eu-west-1"
  },
  "sa-east-1"      => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-sa-east-1"
  },
  "us-east-1"      => {
    "s3Bucket" => "https://s3.amazonaws.com/@@@CFN_TEMPLATES_USEAST1_DIR@@@"
  },
  "us-west-1"      => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-us-west-1"
  },
  "us-west-2"      => {
    "s3Bucket" => "https://s3.amazonaws.com/cloudformation-templates-us-west-2"
  }
})

  Resource("AlarmTopic") do
    Type("AWS::SNS::Topic")
    Property("Subscription", [
  {
    "Endpoint" => Ref("OperatorEmail"),
    "Protocol" => "email"
  }
])
  end

  Resource("EC2SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Open up SSH and HTTP access")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  }
])
  end

  Resource("WebServer") do
    Type("AWS::CloudFormation::Stack")
    Metadata("Puppet", {
  "database" => "WordPressDB",
  "host"     => FnGetAtt("AppDatabase", "Outputs.DBAddress"),
  "password" => Ref("DatabasePassword"),
  "roles"    => [
    "wordpress"
  ],
  "user"     => Ref("DatabaseUser")
})
    Property("TemplateURL", FnJoin("/", [
  FnFindInMap("RegionMap", Ref("AWS::Region"), "s3Bucket"),
  "puppet-client-configuration.template"
]))
    Property("Parameters", {
  "EC2SecurityGroup"          => Ref("EC2SecurityGroup"),
  "InstanceType"              => Ref("InstanceType"),
  "KeyName"                   => Ref("KeyName"),
  "PuppetClientSecurityGroup" => Ref("PuppetClientSecurityGroup"),
  "PuppetMasterDNSName"       => Ref("PuppetMasterDNSName"),
  "ResourceName"              => "WebServer",
  "StackNameOrId"             => Ref("AWS::StackId")
})
  end

  Resource("AppDatabase") do
    Type("AWS::CloudFormation::Stack")
    Metadata("Comment", "Application database.")
    Property("TemplateURL", FnJoin("/", [
  FnFindInMap("RegionMap", Ref("AWS::Region"), "s3Bucket"),
  "RDS_MySQL_55.template"
]))
    Property("Parameters", {
  "AlarmTopic"       => Ref("AlarmTopic"),
  "DBInstanceClass"  => Ref("DatabaseType"),
  "DBName"           => "WordPressDB",
  "DBPassword"       => Ref("DatabasePassword"),
  "DBUser"           => Ref("DatabaseUser"),
  "EC2SecurityGroup" => Ref("EC2SecurityGroup"),
  "MultiAZ"          => "false"
})
  end

  Output("URL") do
    Description("URL of the website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServer", "Outputs.ServerDNSName"),
  "/wordpress"
]))
  end
end

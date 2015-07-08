CloudFormation do
  Description("This template demonstrates using Opscode Chef Solo to deploy the WordPress application. It uses embedded templates to build an Auto Scaling group and a Amazon Relational Database Service database instance. **WARNING** This template creates one or more Amazon EC2 instances, an Amazon RDS database instance and CloudWatch alarms. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
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
    ConstraintDescription("must contain only alphanumeric characters.")
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

  Parameter("HighlyAvailable") do
    Description("Create a solution that spans multiple Availability Zones for high availability")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be true or false.")
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
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-ap-northeast-1"
  },
  "ap-southeast-1" => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-ap-southeast-1"
  },
  "ap-southeast-2" => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-ap-southeast-2"
  },
  "eu-west-1"      => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-eu-west-1"
  },
  "sa-east-1"      => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-sa-east-1"
  },
  "us-east-1"      => {
    "TemplateLocation" => "https://s3.amazonaws.com/@@@CFN_TEMPLATES_USEAST1_DIR@@@"
  },
  "us-west-1"      => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-us-west-1"
  },
  "us-west-2"      => {
    "TemplateLocation" => "https://s3.amazonaws.com/cloudformation-templates-us-west-2"
  }
})

  Mapping("AvailabilityMap", {
  "false" => {
    "InstanceCount" => "1",
    "MultiAZDB"     => "false"
  },
  "true"  => {
    "InstanceCount" => "2",
    "MultiAZDB"     => "true"
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
    Property("GroupDescription", "Open up SSH access")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("WordPressFrontEnd") do
    Type("AWS::CloudFormation::Stack")
    Metadata("Comment", "Create Wordpress web server farm attached to database.")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files" => {
      "/etc/chef/node.json" => {
        "content" => {
          "run_list"  => [
            "recipe[wordpress]"
          ],
          "wordpress" => {
            "db" => {
              "database" => "WordPressDB",
              "host"     => FnGetAtt("WordpressDatabase", "Outputs.DBAddress"),
              "password" => Ref("DatabasePassword"),
              "user"     => Ref("DatabaseUser")
            }
          }
        },
        "group"   => "wheel",
        "mode"    => "000644",
        "owner"   => "root"
      }
    }
  }
})
    Property("TemplateURL", FnJoin("/", [
  FnFindInMap("RegionMap", Ref("AWS::Region"), "TemplateLocation"),
  "chef-solo-configuration.template"
]))
    Property("Parameters", {
  "AlarmTopic"       => Ref("AlarmTopic"),
  "DesiredCapacity"  => FnFindInMap("AvailabilityMap", Ref("HighlyAvailable"), "InstanceCount"),
  "EC2SecurityGroup" => Ref("EC2SecurityGroup"),
  "HealthCheckPath"  => "/wp-admin/install.php",
  "InstanceType"     => Ref("InstanceType"),
  "KeyName"          => Ref("KeyName"),
  "RecipeURL"        => "https://s3.amazonaws.com/@@@CFN_EXAMPLES_DIR@@@/wordpress.tar.gz",
  "ResourceName"     => "WordPressFrontEnd",
  "StackNameOrId"    => Ref("AWS::StackId"),
  "WebServerPort"    => "80"
})
  end

  Resource("WordpressDatabase") do
    Type("AWS::CloudFormation::Stack")
    Metadata("Comment", "Database configuration for Wordpress.")
    Property("TemplateURL", FnJoin("/", [
  FnFindInMap("RegionMap", Ref("AWS::Region"), "TemplateLocation"),
  "RDS_MySQL_55.template"
]))
    Property("Parameters", {
  "AlarmTopic"       => Ref("AlarmTopic"),
  "DBInstanceClass"  => Ref("DatabaseType"),
  "DBName"           => "WordPressDB",
  "DBPassword"       => Ref("DatabasePassword"),
  "DBUser"           => Ref("DatabaseUser"),
  "EC2SecurityGroup" => Ref("EC2SecurityGroup"),
  "MultiAZ"          => FnFindInMap("AvailabilityMap", Ref("HighlyAvailable"), "MultiAZDB")
})
  end

  Output("URL") do
    Description("URL of the website")
    Value(FnGetAtt("WordPressFrontEnd", "Outputs.URL"))
  end
end

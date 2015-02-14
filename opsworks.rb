CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("ServiceRole") do
    Description("The OpsWorks service role")
    Type("String")
    Default("aws-opsworks-service-role")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9-]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("InstanceRole") do
    Description("The OpsWorks instance role")
    Type("String")
    Default("aws-opsworks-ec2-role")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9-]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("AppName") do
    Description("The app name")
    Type("String")
    Default("myapp")
    AllowedPattern("[a-zA-Z][a-zA-Z0-9]*")
    MaxLength(64)
    MinLength(1)
    ConstraintDescription("must begin with a letter and contain only alphanumeric characters.")
  end

  Parameter("MysqlRootPassword") do
    Description("MysqlRootPassword")
    Type("String")
    NoEcho(true)
  end

  Resource("myStack") do
    Type("AWS::OpsWorks::Stack")
    Property("Name", Ref("AWS::StackName"))
    Property("ServiceRoleArn", FnJoin("", [
  "arn:aws:iam::",
  Ref("AWS::AccountId"),
  ":role/",
  Ref("ServiceRole")
]))
    Property("DefaultInstanceProfileArn", FnJoin("", [
  "arn:aws:iam::",
  Ref("AWS::AccountId"),
  ":instance-profile/",
  Ref("InstanceRole")
]))
    Property("UseCustomCookbooks", "true")
    Property("CustomCookbooksSource", {
  "Type" => "git",
  "Url"  => "git://github.com/amazonwebservices/opsworks-example-cookbooks.git"
})
  end

  Resource("myLayer") do
    Type("AWS::OpsWorks::Layer")
    DependsOn("myApp")
    Property("StackId", Ref("myStack"))
    Property("Type", "php-app")
    Property("Shortname", "php-app")
    Property("EnableAutoHealing", "true")
    Property("AutoAssignElasticIps", "false")
    Property("AutoAssignPublicIps", "true")
    Property("Name", "MyPHPApp")
    Property("CustomRecipes", {
  "Configure" => [
    "phpapp::appsetup"
  ]
})
  end

  Resource("DBLayer") do
    Type("AWS::OpsWorks::Layer")
    DependsOn("myApp")
    Property("StackId", Ref("myStack"))
    Property("Type", "db-master")
    Property("Shortname", "db-layer")
    Property("EnableAutoHealing", "true")
    Property("AutoAssignElasticIps", "false")
    Property("AutoAssignPublicIps", "true")
    Property("Name", "MyMySQL")
    Property("CustomRecipes", {
  "Setup" => [
    "phpapp::dbsetup"
  ]
})
    Property("Attributes", {
  "MysqlRootPassword"           => Ref("MysqlRootPassword"),
  "MysqlRootPasswordUbiquitous" => "true"
})
    Property("VolumeConfigurations", [
  {
    "MountPoint"    => "/vol/mysql",
    "NumberOfDisks" => 1,
    "Size"          => 10
  }
])
  end

  Resource("ELBAttachment") do
    Type("AWS::OpsWorks::ElasticLoadBalancerAttachment")
    Property("ElasticLoadBalancerName", Ref("ELB"))
    Property("LayerId", Ref("myLayer"))
  end

  Resource("ELB") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "InstanceProtocol" => "HTTP",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "2",
  "Interval"           => "30",
  "Target"             => "HTTP:80/",
  "Timeout"            => "5",
  "UnhealthyThreshold" => "10"
})
  end

  Resource("myAppInstance1") do
    Type("AWS::OpsWorks::Instance")
    Property("StackId", Ref("myStack"))
    Property("LayerIds", [
  Ref("myLayer")
])
    Property("InstanceType", "m1.small")
  end

  Resource("myAppInstance2") do
    Type("AWS::OpsWorks::Instance")
    Property("StackId", Ref("myStack"))
    Property("LayerIds", [
  Ref("myLayer")
])
    Property("InstanceType", "m1.small")
  end

  Resource("myDBInstance") do
    Type("AWS::OpsWorks::Instance")
    Property("StackId", Ref("myStack"))
    Property("LayerIds", [
  Ref("DBLayer")
])
    Property("InstanceType", "m1.small")
  end

  Resource("myApp") do
    Type("AWS::OpsWorks::App")
    Property("StackId", Ref("myStack"))
    Property("Type", "php")
    Property("Name", Ref("AppName"))
    Property("AppSource", {
  "Revision" => "version2",
  "Type"     => "git",
  "Url"      => "git://github.com/amazonwebservices/opsworks-demo-php-simple-app.git"
})
    Property("Attributes", {
  "DocumentRoot" => "web"
})
  end
end

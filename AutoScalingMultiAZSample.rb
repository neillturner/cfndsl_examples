CloudFormation do
  Description("AWS CloudFormation Sample Template AutoScalingMultiAZSample: Create a multi-az, load balanced and Auto Scaled sample web site running on an Apache Web Server with PHP. The application is configured to span all Availability Zones in the region and is Auto-Scaled based on the CPU utilization of the web servers. The instances are load balanced with a simple health check against the default web page. The web site is available on port 80, however, the instances can be configured to listen on any port (8888 by default). **WARNING** This template creates one or more Amazon EC2 instances and an Elastic Load Balancer. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

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

  Parameter("WebServerPort") do
    Description("The TCP port for the Web Server")
    Type("Number")
    Default("8888")
  end

  Parameter("KeyName") do
    Description("The EC2 Key Pair to allow SSH access to the instances")
    Type("String")
  end

  Parameter("SSHLocation") do
    Description("The IP address range that can be used to SSH to the EC2 instances")
    Type("String")
    Default("0.0.0.0/0")
    AllowedPattern("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})")
    MaxLength(18)
    MinLength(9)
    ConstraintDescription("must be a valid IP CIDR range of the form x.x.x.x/x.")
  end

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"  => {
    "Arch" => "64"
  },
  "c1.xlarge"  => {
    "Arch" => "64"
  },
  "m1.large"   => {
    "Arch" => "64"
  },
  "m1.medium"  => {
    "Arch" => "64"
  },
  "m1.small"   => {
    "Arch" => "64"
  },
  "m1.xlarge"  => {
    "Arch" => "64"
  },
  "m2.2xlarge" => {
    "Arch" => "64"
  },
  "m2.4xlarge" => {
    "Arch" => "64"
  },
  "m2.xlarge"  => {
    "Arch" => "64"
  },
  "m3.2xlarge" => {
    "Arch" => "64"
  },
  "m3.xlarge"  => {
    "Arch" => "64"
  },
  "t1.micro"   => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32" => "ami-7871c579",
    "64" => "ami-7671c577"
  },
  "ap-southeast-1" => {
    "32" => "ami-425a2010",
    "64" => "ami-5e5a200c"
  },
  "ap-southeast-2" => {
    "32" => "ami-b3990e89",
    "64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "32" => "ami-018bb975",
    "64" => "ami-998bb9ed"
  },
  "sa-east-1"      => {
    "32" => "ami-a039e6bd",
    "64" => "ami-a239e6bf"
  },
  "us-east-1"      => {
    "32" => "ami-aba768c2",
    "64" => "ami-81a768e8"
  },
  "us-west-1"      => {
    "32" => "ami-458fd300",
    "64" => "ami-b18ed2f4"
  },
  "us-west-2"      => {
    "32" => "ami-fcff72cc",
    "64" => "ami-feff72ce"
  }
})

  Resource("WebServerGroup") do
    Type("AWS::AutoScaling::AutoScalingGroup")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("LaunchConfigurationName", Ref("LaunchConfig"))
    Property("MinSize", "1")
    Property("MaxSize", "3")
    Property("LoadBalancerNames", [
  Ref("ElasticLoadBalancer")
])
  end

  Resource("LaunchConfig") do
    Type("AWS::AutoScaling::LaunchConfiguration")
    Property("KeyName", Ref("KeyName"))
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(Ref("WebServerPort")))
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("WebServerScaleUpPolicy") do
    Type("AWS::AutoScaling::ScalingPolicy")
    Property("AdjustmentType", "ChangeInCapacity")
    Property("AutoScalingGroupName", Ref("WebServerGroup"))
    Property("Cooldown", "60")
    Property("ScalingAdjustment", "1")
  end

  Resource("WebServerScaleDownPolicy") do
    Type("AWS::AutoScaling::ScalingPolicy")
    Property("AdjustmentType", "ChangeInCapacity")
    Property("AutoScalingGroupName", Ref("WebServerGroup"))
    Property("Cooldown", "60")
    Property("ScalingAdjustment", "-1")
  end

  Resource("CPUAlarmHigh") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Scale-up if CPU > 90% for 10 minutes")
    Property("MetricName", "CPUUtilization")
    Property("Namespace", "AWS/EC2")
    Property("Statistic", "Average")
    Property("Period", "300")
    Property("EvaluationPeriods", "2")
    Property("Threshold", "90")
    Property("AlarmActions", [
  Ref("WebServerScaleUpPolicy")
])
    Property("Dimensions", [
  {
    "Name"  => "AutoScalingGroupName",
    "Value" => Ref("WebServerGroup")
  }
])
    Property("ComparisonOperator", "GreaterThanThreshold")
  end

  Resource("CPUAlarmLow") do
    Type("AWS::CloudWatch::Alarm")
    Property("AlarmDescription", "Scale-down if CPU < 70% for 10 minutes")
    Property("MetricName", "CPUUtilization")
    Property("Namespace", "AWS/EC2")
    Property("Statistic", "Average")
    Property("Period", "300")
    Property("EvaluationPeriods", "2")
    Property("Threshold", "70")
    Property("AlarmActions", [
  Ref("WebServerScaleDownPolicy")
])
    Property("Dimensions", [
  {
    "Name"  => "AutoScalingGroupName",
    "Value" => Ref("WebServerGroup")
  }
])
    Property("ComparisonOperator", "LessThanThreshold")
  end

  Resource("ElasticLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", FnGetAZs(""))
    Property("Listeners", [
  {
    "InstancePort"     => Ref("WebServerPort"),
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "3",
  "Interval"           => "30",
  "Target"             => FnJoin("", [
  "HTTP:",
  Ref("WebServerPort"),
  "/"
]),
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access and HTTP from the load balancer only")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "FromPort"                   => Ref("WebServerPort"),
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => Ref("WebServerPort")
  }
])
  end

  Output("URL") do
    Description("The URL of the website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ElasticLoadBalancer", "DNSName")
]))
  end
end

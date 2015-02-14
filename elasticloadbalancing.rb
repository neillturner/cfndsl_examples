CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("MyLoadBalancer") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", [
  "us-east-1a"
])
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
  end

  Resource("MyLoadBalancer2") do
    Type("AWS::ElasticLoadBalancing::LoadBalancer")
    Property("AvailabilityZones", [
  "us-east-1a"
])
    Property("Instances", [
  Ref("logical name of AWS::EC2::Instance resource 1"),
  Ref("logical name of AWS::EC2::Instance resource 2")
])
    Property("Listeners", [
  {
    "InstancePort"     => "80",
    "LoadBalancerPort" => "80",
    "Protocol"         => "HTTP"
  }
])
    Property("HealthCheck", {
  "HealthyThreshold"   => "3",
  "Interval"           => "30",
  "Target"             => "HTTP:80/",
  "Timeout"            => "5",
  "UnhealthyThreshold" => "5"
})
  end
end

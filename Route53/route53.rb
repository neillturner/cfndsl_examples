CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

#  adds an Amazon Route 53 resource record set containing an SPF record for the domain name mysite.example.com
# that uses the HostedZoneId property to specify the hosted zone.
  Resource("myDNSRecord") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneId", "/hostedzone/Z3DG6IL3SJCGPX")
    Property("Name", "mysite.example.com.")
    Property("Type", "SPF")
    Property("TTL", "900")
    Property("ResourceRecords", [
  "\"v=spf1 ip4:192.168.0.1/16 -all\""
])
  end

# adds an Amazon Route 53 resource record set containing A records for the domain name "mysite.example.com" using 
# the HostedZoneName property to specify the hosted zone.
  Resource("myDNSRecord2") do
    Type("AWS::Route53::RecordSet")
    Property("HostedZoneName", "example.com.")
    Property("Comment", "A records for my frontends.")
    Property("Name", "mysite.example.com.")
    Property("Type", "A")
    Property("TTL", "900")
    Property("ResourceRecords", [
  "192.168.0.1",
  "192.168.0.2"
])
  end

# Using RecordSetGroup to Set Up Weighted Resource Record Sets
  Resource("myDNSOne") do
    Type("AWS::Route53::RecordSetGroup")
    Property("HostedZoneName", "example.com.")
    Property("Comment", "Weighted RR for my frontends.")
    Property("RecordSets", [
  {
    "Name"            => "mysite.example.com.",
    "ResourceRecords" => [
      "example-ec2.amazonaws.com"
    ],
    "SetIdentifier"   => "Frontend One",
    "TTL"             => "900",
    "Type"            => "CNAME",
    "Weight"          => "4"
  },
  {
    "Name"            => "mysite.example.com.",
    "ResourceRecords" => [
      "example-ec2-larger.amazonaws.com"
    ],
    "SetIdentifier"   => "Frontend Two",
    "TTL"             => "900",
    "Type"            => "CNAME",
    "Weight"          => "6"
  }
])
  end

# Using RecordSetGroup to Set Up an Alias Resource Record Set
  Resource("myELB") do
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

# An Alias Resource Record Set for a CloudFront Distribution
  Resource("myDNS") do
    Type("AWS::Route53::RecordSetGroup")
    Property("HostedZoneId", Ref("myHostedZoneID"))
    Property("RecordSets", [
  {
    "AliasTarget" => {
      "DNSName"      => Ref("myCloudFrontDistributionDomainName"),
      "HostedZoneId" => "Z2FDTNDATAQYW2"
    },
    "Name"        => Ref("myRecordSetDomainName"),
    "Type"        => "A"
  }
])
  end
end

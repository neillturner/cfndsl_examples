CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("Ec2SecurityGroup")
])
    Property("BlockDeviceMappings", [
  {
    "DeviceName" => "/dev/sda1",
    "Ebs"        => {
      "VolumeSize" => "50"
    }
  },
  {
    "DeviceName" => "/dev/sdm",
    "Ebs"        => {
      "VolumeSize" => "100"
    }
  }
])
  end

  Resource("Ec2Instance2") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), "PV64"))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", "m1.small")
    Property("SecurityGroups", [
  Ref("Ec2SecurityGroup")
])
    Property("BlockDeviceMappings", [
  {
    "DeviceName"  => "/dev/sdc",
    "VirtualName" => "ephemeral0"
  }
])
  end

  Resource("MyEIP") do
    Type("AWS::EC2::EIP")
    Property("InstanceId", Ref("logical name of an AWS::EC2::Instance resource"))
  end

  Resource("IPAssoc") do
    Type("AWS::EC2::EIPAssociation")
    Property("InstanceId", Ref("logical name of an AWS::EC2::Instance resource"))
    Property("EIP", "existing Elastic IP address")
  end

  Resource("VpcIPAssoc") do
    Type("AWS::EC2::EIPAssociation")
    Property("InstanceId", Ref("logical name of an AWS::EC2::Instance resource"))
    Property("AllocationId", "existing VPC Elastic IP allocation ID")
  end

  Resource("ControlPortAddress") do
    Type("AWS::EC2::EIP")
    Property("Domain", "vpc")
  end

  Resource("AssociateControlPort") do
    Type("AWS::EC2::EIPAssociation")
    Property("AllocationId", FnGetAtt("ControlPortAddress", "AllocationId"))
    Property("NetworkInterfaceId", Ref("controlXface"))
  end

  Resource("WebPortAddress") do
    Type("AWS::EC2::EIP")
    Property("Domain", "vpc")
  end

  Resource("AssociateWebPort") do
    Type("AWS::EC2::EIPAssociation")
    Property("AllocationId", FnGetAtt("WebPortAddress", "AllocationId"))
    Property("NetworkInterfaceId", Ref("webXface"))
  end

  Resource("SSHSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("VpcId", Ref("VpcId"))
    Property("GroupDescription", "Enable SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("WebSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("VpcId", Ref("VpcId"))
    Property("GroupDescription", "Enable HTTP access via user defined port")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => 80,
    "IpProtocol" => "tcp",
    "ToPort"     => 80
  }
])
  end

  Resource("controlXface") do
    Type("AWS::EC2::NetworkInterface")
    Property("SubnetId", Ref("SubnetId"))
    Property("Description", "Interface for control traffic such as SSH")
    Property("GroupSet", [
  Ref("SSHSecurityGroup")
])
    Property("SourceDestCheck", "true")
    Property("Tags", [
  {
    "Key"   => "Network",
    "Value" => "Control"
  }
])
  end

  Resource("webXface") do
    Type("AWS::EC2::NetworkInterface")
    Property("SubnetId", Ref("SubnetId"))
    Property("Description", "Interface for web traffic")
    Property("GroupSet", [
  Ref("WebSecurityGroup")
])
    Property("SourceDestCheck", "true")
    Property("Tags", [
  {
    "Key"   => "Network",
    "Value" => "Web"
  }
])
  end

  Resource("Ec2Instance3") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("KeyName", Ref("KeyName"))
    Property("NetworkInterfaces", [
  {
    "DeviceIndex"        => "0",
    "NetworkInterfaceId" => Ref("controlXface")
  },
  {
    "DeviceIndex"        => "1",
    "NetworkInterfaceId" => Ref("webXface")
  }
])
    Property("Tags", [
  {
    "Key"   => "Role",
    "Value" => "Test Instance"
  }
])
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -ex",
  "\n",
  "\n",
  "yum install ec2-net-utils -y",
  "\n",
  "ec2ifup eth1",
  "\n",
  "service httpd start"
])))
  end

  Resource("MyInstance") do
    Type("AWS::EC2::Instance")
    Property("AvailabilityZone", "us-east-1a")
    Property("ImageId", "ami-20b65349")
  end

  Resource("MyInstance2") do
    Type("AWS::EC2::Instance")
    Property("KeyName", Ref("KeyName"))
    Property("SecurityGroups", [
  Ref("logical name of AWS::EC2::SecurityGroup resource")
])
    Property("UserData", FnBase64(FnJoin(":", [
  "PORT=80",
  "TOPIC=",
  Ref("logical name of an AWS::SNS::Topic resource")
])))
    Property("InstanceType", "m1.small")
    Property("AvailabilityZone", "us-east-1a")
    Property("ImageId", "ami-1e817677")
    Property("Volumes", [
  {
    "Device"   => "/dev/sdk",
    "VolumeId" => Ref("logical name of AWS::EC2::Volume resource")
  }
])
    Property("Tags", [
  {
    "Key"   => "Name",
    "Value" => "MyTag"
  }
])
  end

  Resource("MyInstance3") do
    Type("AWS::EC2::Instance")
    Property("UserData", FnBase64(FnJoin("", [
  "Domain=",
  Ref("logical name of an AWS::SDB::Domain resource")
])))
    Property("AvailabilityZone", "us-east-1a")
    Property("ImageId", "ami-20b65349")
  end

  Resource("ServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "allow connections from specified CIDR ranges")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "80",
    "IpProtocol" => "tcp",
    "ToPort"     => "80"
  },
  {
    "CidrIp"     => "192.168.1.1/32",
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("ServerSecurityGroupBySG") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "allow connections from specified source security group")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => "22",
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => "myadminsecuritygroup",
    "SourceSecurityGroupOwnerId" => "123456789012",
    "ToPort"                     => "22"
  },
  {
    "FromPort"                => "80",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("mysecuritygroupcreatedincfn"),
    "ToPort"                  => "80"
  }
])
  end

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

  Resource("ELBIngressGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "ELB ingress group")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                   => "80",
    "IpProtocol"                 => "tcp",
    "SourceSecurityGroupName"    => FnGetAtt("myELB", "SourceSecurityGroup.GroupName"),
    "SourceSecurityGroupOwnerId" => FnGetAtt("myELB", "SourceSecurityGroup.OwnerAlias"),
    "ToPort"                     => "80"
  }
])
  end

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

  Resource("MyEBSVolume") do
    Type("AWS::EC2::Volume")
    DeletionPolicy("Snapshot")
    Property("Size", "specify a size if no SnapShotId")
    Property("SnapshotId", "specify a SnapShotId if no Size")
    Property("AvailabilityZone", Ref("AvailabilityZone"))
  end

  Resource("Ec2Instance4") do
    Type("AWS::EC2::Instance")
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("ImageId", "ami-76f0061f")
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("NewVolume") do
    Type("AWS::EC2::Volume")
    Property("Size", "100")
    Property("AvailabilityZone", FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end

  Resource("MountPoint") do
    Type("AWS::EC2::VolumeAttachment")
    Property("InstanceId", Ref("Ec2Instance"))
    Property("VolumeId", Ref("NewVolume"))
    Property("Device", "/dev/sdh")
  end

  Resource("myVPC") do
    Type("AWS::EC2::VPC")
    Property("CidrBlock", Ref("myVPCCIDRRange"))
    Property("EnableDnsSupport", false)
    Property("EnableDnsHostnames", false)
    Property("InstanceTenancy", "default")
  end

  Resource("myInstance5") do
    Type("AWS::EC2::Instance")
    Property("ImageId", FnFindInMap("AWSRegionToAMI", Ref("AWS::Region"), "64"))
    Property("SecurityGroupIds", [
  FnGetAtt("myVPC", "DefaultSecurityGroup")
])
    Property("SubnetId", Ref("mySubnet"))
  end
end

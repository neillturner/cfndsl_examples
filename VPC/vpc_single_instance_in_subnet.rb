CloudFormation do
  Description("AWS CloudFormation Sample Template vpc_single_instance_in_subnet.template: Sample template showing how to create a VPC and add an EC2 instance with an Elastic IP address and a security group. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("KeyName") do
    Description("Name of and existing EC2 KeyPair to enable SSH access to the instance")
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

  Resource("VPC") do
    Type("AWS::EC2::VPC")
    Property("CidrBlock", "10.0.0.0/16")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
  end

  Resource("Subnet") do
    Type("AWS::EC2::Subnet")
    Property("VpcId", Ref("VPC"))
    Property("CidrBlock", "10.0.0.0/24")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
  end

  Resource("InternetGateway") do
    Type("AWS::EC2::InternetGateway")
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
  end

  Resource("AttachGateway") do
    Type("AWS::EC2::VPCGatewayAttachment")
    Property("VpcId", Ref("VPC"))
    Property("InternetGatewayId", Ref("InternetGateway"))
  end

  Resource("RouteTable") do
    Type("AWS::EC2::RouteTable")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
  end

  Resource("Route") do
    Type("AWS::EC2::Route")
    DependsOn("AttachGateway")
    Property("RouteTableId", Ref("RouteTable"))
    Property("DestinationCidrBlock", "0.0.0.0/0")
    Property("GatewayId", Ref("InternetGateway"))
  end

  Resource("SubnetRouteTableAssociation") do
    Type("AWS::EC2::SubnetRouteTableAssociation")
    Property("SubnetId", Ref("Subnet"))
    Property("RouteTableId", Ref("RouteTable"))
  end

  Resource("NetworkAcl") do
    Type("AWS::EC2::NetworkAcl")
    Property("VpcId", Ref("VPC"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
  end

  Resource("InboundHTTPNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "80",
  "To"   => "80"
})
  end

  Resource("InboundSSHNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "101")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "22",
  "To"   => "22"
})
  end

  Resource("InboundResponsePortsNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "102")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "false")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "1024",
  "To"   => "65535"
})
  end

  Resource("OutBoundHTTPNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "100")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "80",
  "To"   => "80"
})
  end

  Resource("OutBoundHTTPSNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "101")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "443",
  "To"   => "443"
})
  end

  Resource("OutBoundResponsePortsNetworkAclEntry") do
    Type("AWS::EC2::NetworkAclEntry")
    Property("NetworkAclId", Ref("NetworkAcl"))
    Property("RuleNumber", "102")
    Property("Protocol", "6")
    Property("RuleAction", "allow")
    Property("Egress", "true")
    Property("CidrBlock", "0.0.0.0/0")
    Property("PortRange", {
  "From" => "1024",
  "To"   => "65535"
})
  end

  Resource("SubnetNetworkAclAssociation") do
    Type("AWS::EC2::SubnetNetworkAclAssociation")
    Property("SubnetId", Ref("Subnet"))
    Property("NetworkAclId", Ref("NetworkAcl"))
  end

  Resource("IPAddress") do
    Type("AWS::EC2::EIP")
    DependsOn("AttachGateway")
    Property("Domain", "vpc")
    Property("InstanceId", Ref("WebServerInstance"))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("VpcId", Ref("VPC"))
    Property("GroupDescription", "Enable SSH access via port 22")
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

  Resource("WebServerInstance") do
    Type("AWS::EC2::Instance")
    Metadata("Comment", "Install a simple PHP application")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/cfn/cfn-hup.conf"                   => {
        "content" => FnJoin("", [
  "[main]\n",
  "stack=",
  Ref("AWS::StackId"),
  "\n",
  "region=",
  Ref("AWS::Region"),
  "\n"
]),
        "group"   => "root",
        "mode"    => "000400",
        "owner"   => "root"
      },
      "/etc/cfn/hooks.d/cfn-auto-reloader.conf" => {
        "content" => FnJoin("", [
  "[cfn-auto-reloader-hook]\n",
  "triggers=post.update\n",
  "path=Resources.WebServerInstance.Metadata.AWS::CloudFormation::Init\n",
  "action=/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServerInstance ",
  " --region     ",
  Ref("AWS::Region"),
  "\n",
  "runas=root\n"
])
      },
      "/var/www/html/index.php"                 => {
        "content" => FnJoin("", [
  "<?php\n",
  "echo '<h1>AWS CloudFormation sample PHP application</h1>';\n",
  "?>\n"
]),
        "group"   => "apache",
        "mode"    => "000644",
        "owner"   => "apache"
      }
    },
    "packages" => {
      "yum" => {
        "httpd" => [],
        "php"   => []
      }
    },
    "services" => {
      "sysvinit" => {
        "httpd"    => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        },
        "sendmail" => {
          "enabled"       => "false",
          "ensureRunning" => "false"
        }
      }
    }
  }
})
    Property("ImageId", FnFindInMap("RegionMap", Ref("AWS::Region"), "AMI"))
    Property("SecurityGroupIds", [
  Ref("InstanceSecurityGroup")
])
    Property("SubnetId", Ref("Subnet"))
    Property("InstanceType", Ref("InstanceType"))
    Property("KeyName", Ref("KeyName"))
    Property("Tags", [
  {
    "Key"   => "Application",
    "Value" => Ref("AWS::StackId")
  }
])
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Helper function\n",
  "function error_exit\n",
  "{\n",
  "  /opt/aws/bin/cfn-signal -e 1 -r \"$1\" '",
  Ref("WebServerWaitHandle"),
  "'\n",
  "  exit 1\n",
  "}\n",
  "# Install the simple web page\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r WebServerInstance ",
  "         --region ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Start up the cfn-hup daemon to listen for changes to the Web Server metadata\n",
  "/opt/aws/bin/cfn-hup || error_exit 'Failed to start cfn-hup'\n",
  "# All done so signal success\n",
  "/opt/aws/bin/cfn-signal -e 0 -r \"WebServer setup complete\" '",
  Ref("WebServerWaitHandle"),
  "'\n"
])))
  end

  Resource("WebServerWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WebServerWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("WebServerInstance")
    Property("Handle", Ref("WebServerWaitHandle"))
    Property("Timeout", "300")
  end

  Output("URL") do
    Description("Newly created application URL")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("WebServerInstance", "PublicIp")
]))
  end
end

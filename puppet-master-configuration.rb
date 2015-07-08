CloudFormation do
  Description("Sample template to bring up Puppet Master instance that can be used to bootstrap and manage Puppet Clients. The Puppet Master is populated from an embedded template that defines the set of applications to load. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
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
    Description("Name of an existing EC2 KeyPair to enable SSH access to the PuppetMaster")
    Type("String")
  end

  Parameter("ContentManifest") do
    Description("Manifest of roles to add to nodes.pp")
    Type("String")
    Default("/wordpress/: { include wordpress }")
  end

  Parameter("ContentLocation") do
    Description("Location of package (Zip, GZIP or Git repository URL) that includes the PuppetMaster content")
    Type("String")
    Default("https://s3.amazonaws.com/cloudformation-examples/wordpress-puppet-config.tar.gz")
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

  Mapping("AWSInstanceType2Arch", {
  "c1.medium"   => {
    "Arch" => "64"
  },
  "c1.xlarge"   => {
    "Arch" => "64"
  },
  "cc1.4xlarge" => {
    "Arch" => "64HVM"
  },
  "cc2.8xlarge" => {
    "Arch" => "64HVM"
  },
  "cg1.4xlarge" => {
    "Arch" => "64HVM"
  },
  "m1.large"    => {
    "Arch" => "64"
  },
  "m1.medium"   => {
    "Arch" => "64"
  },
  "m1.small"    => {
    "Arch" => "64"
  },
  "m1.xlarge"   => {
    "Arch" => "64"
  },
  "m2.2xlarge"  => {
    "Arch" => "64"
  },
  "m2.4xlarge"  => {
    "Arch" => "64"
  },
  "m2.xlarge"   => {
    "Arch" => "64"
  },
  "m3.2xlarge"  => {
    "Arch" => "64"
  },
  "m3.xlarge"   => {
    "Arch" => "64"
  },
  "t1.micro"    => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32"    => "ami-0644f007",
    "64"    => "ami-0a44f00b",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "ap-southeast-1" => {
    "32"    => "ami-b3990e89",
    "64"    => "ami-bd990e87",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "eu-west-1"      => {
    "32"    => "ami-973b06e3",
    "64"    => "ami-953b06e1",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "sa-east-1"      => {
    "32"    => "ami-3e3be423",
    "64"    => "ami-3c3be421",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-east-1"      => {
    "32"    => "ami-31814f58",
    "64"    => "ami-1b814f72",
    "64HVM" => "ami-0da96764"
  },
  "us-west-1"      => {
    "32"    => "ami-11d68a54",
    "64"    => "ami-1bd68a5e",
    "64HVM" => "NOT_YET_SUPPORTED"
  },
  "us-west-2"      => {
    "32"    => "ami-38fe7308",
    "64"    => "ami-30fe7300",
    "64HVM" => "NOT_YET_SUPPORTED"
  }
})

  Resource("PuppetMasterInstance") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/puppet/autosign.conf"                 => {
        "content" => "*.internal\n",
        "group"   => "wheel",
        "mode"    => "100644",
        "owner"   => "root"
      },
      "/etc/puppet/fileserver.conf"               => {
        "content" => "[modules]\n   allow *.internal\n",
        "group"   => "wheel",
        "mode"    => "100644",
        "owner"   => "root"
      },
      "/etc/puppet/manifests/nodes.pp"            => {
        "content" => FnJoin("", [
  "node basenode {\n",
  "  include cfn\n",
  "}\n",
  "node /^.*internal$/ inherits basenode {\n",
  "  case $cfn_roles {\n",
  "    ",
  Ref("ContentManifest"),
  "\n",
  "  }\n",
  "}\n"
]),
        "group"   => "wheel",
        "mode"    => "100644",
        "owner"   => "root"
      },
      "/etc/puppet/manifests/site.pp"             => {
        "content" => "import \"nodes\"\n",
        "group"   => "wheel",
        "mode"    => "100644",
        "owner"   => "root"
      },
      "/etc/puppet/modules/cfn/lib/facter/cfn.rb" => {
        "group"  => "wheel",
        "mode"   => "100644",
        "owner"  => "root",
        "source" => "https://s3.amazonaws.com/cloudformation-examples/cfn-facter-plugin.rb"
      },
      "/etc/puppet/modules/cfn/manifests/init.pp" => {
        "content" => "class cfn {}",
        "group"   => "wheel",
        "mode"    => "100644",
        "owner"   => "root"
      },
      "/etc/puppet/puppet.conf"                   => {
        "content" => FnJoin("", [
  "[main]\n",
  "   logdir=/var/log/puppet\n",
  "   rundir=/var/run/puppet\n",
  "   ssldir=$vardir/ssl\n",
  "   pluginsync=true\n",
  "[agent]\n",
  "   classfile=$vardir/classes.txt\n",
  "   localconfig=$vardir/localconfig\n"
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/yum.repos.d/epel.repo"                => {
        "group"  => "root",
        "mode"   => "000644",
        "owner"  => "root",
        "source" => "https://s3.amazonaws.com/cloudformation-examples/enable-epel-on-amazon-linux-ami"
      }
    },
    "packages" => {
      "rubygems" => {
        "json" => []
      },
      "yum"      => {
        "gcc"           => [],
        "make"          => [],
        "puppet"        => [],
        "puppet-server" => [],
        "ruby-devel"    => [],
        "rubygems"      => []
      }
    },
    "services" => {
      "sysvinit" => {
        "puppetmaster" => {
          "enabled"       => "true",
          "ensureRunning" => "true"
        }
      }
    },
    "sources"  => {
      "/etc/puppet" => Ref("ContentLocation")
    }
  }
})
    Property("InstanceType", Ref("InstanceType"))
    Property("SecurityGroups", [
  Ref("PuppetGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("KeyName", Ref("KeyName"))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "yum update -y aws-cfn-bootstrap\n",
  "/opt/aws/bin/cfn-init --region ",
  Ref("AWS::Region"),
  "    -s ",
  Ref("AWS::StackId"),
  " -r PuppetMasterInstance ",
  "\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("PuppetMasterWaitHandle"),
  "'\n"
])))
  end

  Resource("EC2SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Group for clients to communicate with Puppet Master")
  end

  Resource("PuppetGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Group for puppet communication")
    Property("SecurityGroupIngress", [
  {
    "FromPort"                => "8140",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("EC2SecurityGroup"),
    "ToPort"                  => "8140"
  },
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Resource("PuppetMasterWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("PuppetMasterWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("PuppetMasterInstance")
    Property("Handle", Ref("PuppetMasterWaitHandle"))
    Property("Timeout", "600")
  end

  Output("PuppetMasterDNSName") do
    Description("DNS Name of PuppetMaster")
    Value(FnGetAtt("PuppetMasterInstance", "PrivateDnsName"))
  end

  Output("PuppetClientSecurityGroup") do
    Description("Clients of the Puppet Master should be part of this security group")
    Value(Ref("EC2SecurityGroup"))
  end
end

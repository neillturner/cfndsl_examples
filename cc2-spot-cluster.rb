CloudFormation do
  Description("An example template which launches and bootstraps a cluster of eight CC2 EC2 instances for high performance computational tasks using spot pricing. Includes StarCluster, Grid Engine and NFS.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("AccountNumber") do
    Description("Twelve digit AWS account number.")
    Type("String")
    NoEcho(True)
  end

  Parameter("KeyName") do
    Description("Name of an existing EC2 Key Pair used to log into the StarCluster controller instance.")
    Type("String")
  end

  Parameter("ClusterSize") do
    Description("Number of instances to provision as compute nodes in the cluster.")
    Type("Number")
  end

  Parameter("InstanceType") do
    Description("Instance type to provision as compute nodes in the cluster.")
    Type("String")
  end

  Parameter("ClusterKeypair") do
    Description("Unique name of the new key pair StarCluster will use for cluster access.")
    Type("String")
  end

  Parameter("SpotPrice") do
    Description("Maximum spot price in USD (e.g.: 1.50).")
    Type("Number")
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
  "t1.micro"    => {
    "Arch" => "64"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "us-east-1" => {
    "32"    => "ami-899d49e0",
    "64"    => "ami-999d49f0",
    "64HVM" => "ami-4583572c"
  }
})

  Resource("ClusterUser") do
    Type("AWS::IAM::User")
  end

  Resource("ClusterGroup") do
    Type("AWS::IAM::Group")
  end

  Resource("ClusterUsers") do
    Type("AWS::IAM::UserToGroupAddition")
    Property("GroupName", Ref("ClusterGroup"))
    Property("Users", [
  Ref("ClusterUser")
])
  end

  Resource("CFNUserPolicies") do
    Type("AWS::IAM::Policy")
    Property("PolicyName", "ClusterUsers")
    Property("PolicyDocument", {
  "Statement" => [
    {
      "Action"   => [
        "ec2:*",
        "s3:*",
        "cloudformation:DescribeStackResource"
      ],
      "Effect"   => "Allow",
      "Resource" => "*"
    }
  ]
})
    Property("Groups", [
  Ref("ClusterGroup")
])
  end

  Resource("ClusterUserKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("ClusterUser"))
  end

  Resource("Ec2Instance") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/home/ec2-user/cc2-spot-template.erb" => {
        "group"  => "ec2-user",
        "mode"   => "000644",
        "owner"  => "ec2-user",
        "source" => "http://cfn-cc.s3.amazonaws.com/cc2-spot-template.erb"
      },
      "/home/ec2-user/parser.rb"             => {
        "group"  => "ec2-user",
        "mode"   => "000644",
        "owner"  => "ec2-user",
        "source" => "http://cfn-cc.s3.amazonaws.com/parser.rb"
      },
      "/home/ec2-user/values.yml"            => {
        "content" => FnJoin("", [
  "values:\n",
  " access_key_id: ",
  Ref("ClusterUserKeys"),
  "\n",
  " secret_access_key: ",
  FnGetAtt("ClusterUserKeys", "SecretAccessKey"),
  "\n",
  " account_number: ",
  Ref("AccountNumber"),
  "\n",
  " instance_type: ",
  Ref("InstanceType"),
  "\n",
  " cluster_size: ",
  Ref("ClusterSize"),
  "\n",
  " image_id: ",
  FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")),
  "\n",
  " cluster_keypair: ",
  Ref("ClusterKeypair"),
  "\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000644",
        "owner"   => "ec2-user"
      }
    },
    "packages" => {
      "yum" => {
        "gcc"          => [],
        "make"         => [],
        "python-devel" => []
      }
    },
    "sources"  => {
      "/home/ec2-user/starcluster" => "https://github.com/jtriley/StarCluster/tarball/master",
      "/usr/src/pycrypto"          => "https://ftp.dlitz.net/pub/dlitz/crypto/pycrypto/pycrypto-2.4.tar.gz"
    }
  }
})
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", "t1.micro")
    Property("ImageId", "ami-e565ba8c")
    Property("KeyName", Ref("KeyName"))
    Property("Tags", [
  {
    "Key"   => "Role",
    "Value" => "Controller"
  }
])
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/sh\n",
  "/opt/aws/bin/cfn-init ",
  " -s ",
  Ref("AWS::StackId"),
  " -r Ec2Instance ",
  "\n",
  "cd /usr/src/pycrypto/pycrypto-2.4; /usr/bin/python setup.py build\n",
  "cd /usr/src/pycrypto/pycrypto-2.4; /usr/bin/python setup.py install\n",
  "cd /home/ec2-user/starcluster; /usr/bin/python distribute_setup.py\n",
  "cd /home/ec2-user/starcluster; /usr/bin/python setup.py install\n",
  "/bin/mkdir /home/ec2-user/.starcluster\n",
  "/bin/chown ec2-user:ec2-user -R /home/ec2-user/.starcluster\n",
  "/usr/bin/ruby /home/ec2-user/parser.rb /home/ec2-user/cc2-spot-template.erb /home/ec2-user/values.yml > /home/ec2-user/.starcluster/config\n",
  "/usr/bin/starcluster -c /home/ec2-user/.starcluster/config createkey ",
  Ref("ClusterKeypair"),
  " -o /home/ec2-user/.ssh/rsa-",
  Ref("ClusterKeypair"),
  "\n",
  "/bin/chown ec2-user:ec2-user -R /home/ec2-user/.ssh/rsa-",
  Ref("ClusterKeypair"),
  "\n",
  "cd /home/ec2-user/; /usr/bin/starcluster -c /home/ec2-user/.starcluster/config start -b ",
  Ref("SpotPrice"),
  " ec2-cluster\n"
])))
  end

  Resource("InstanceSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access via port 22")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Output("InstancePublicDNS") do
    Description("Public DNS for the cluster controller instance")
    Value(FnGetAtt("Ec2Instance", "PublicDnsName"))
  end

  Output("AvailabilityZone") do
    Description("The Availability Zone in which the newly created EC2 instance was launched")
    Value(FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end
end

CloudFormation do
  Description("An example template which launches and bootstraps a cluster of CC1 EC2 instances for high performance computational tasks. Includes StarCluster, SGE, NFS and a Public Data Set.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("AccountNumber") do
    Description("Twelve digit AWS account number")
    Type("String")
    NoEcho(True)
  end

  Parameter("KeyName") do
    Description("The EC2 Key Pair to allow SSH access to the controller instance")
    Type("String")
  end

  Parameter("ClusterKeypair") do
    Description("Unique name of the new keypair used for cluster control")
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
      "/home/ec2-user/cc2-template.erb" => {
        "group"  => "ec2-user",
        "mode"   => "000644",
        "owner"  => "ec2-user",
        "source" => "http://cfn-cc.s3.amazonaws.com/cc2-template.erb"
      },
      "/home/ec2-user/parser.rb"        => {
        "group"  => "ec2-user",
        "mode"   => "000644",
        "owner"  => "ec2-user",
        "source" => "http://cfn-cc.s3.amazonaws.com/parser.rb"
      },
      "/home/ec2-user/values.yml"       => {
        "content" => FnJoin("", [
  "values:\n",
  "  access_key_id: ",
  Ref("ClusterUserKeys"),
  "\n",
  "  secret_access_key: ",
  FnGetAtt("ClusterUserKeys", "SecretAccessKey"),
  "\n",
  "  account_number: ",
  Ref("AccountNumber"),
  "\n",
  "  ensembl_volume: ",
  Ref("NewVolume"),
  "\n",
  "  cluster_keypair: ",
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
      "/home/ec2-user/starcluster" => "https://github.com/mza/StarCluster/tarball/master",
      "/usr/src/pycrypto"          => "https://ftp.dlitz.net/pub/dlitz/crypto/pycrypto/pycrypto-2.4.tar.gz"
    }
  }
})
    Property("SecurityGroups", [
  Ref("InstanceSecurityGroup")
])
    Property("InstanceType", "t1.micro")
    Property("ImageId", "ami-7341831a")
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
  "/usr/bin/ruby /home/ec2-user/parser.rb /home/ec2-user/cc2-template.erb /home/ec2-user/values.yml > /home/ec2-user/.starcluster/config\n",
  "/usr/bin/starcluster -c /home/ec2-user/.starcluster/config createkey ",
  Ref("ClusterKeypair"),
  " -o /home/ec2-user/.ssh/rsa-",
  Ref("ClusterKeypair"),
  "\n",
  "/bin/chown ec2-user:ec2-user -R /home/ec2-user/.ssh/rsa-",
  Ref("ClusterKeypair"),
  "\n",
  "cd /home/ec2-user/; /usr/bin/starcluster -c /home/ec2-user/.starcluster/config start ec2-cluster\n"
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

  Resource("NewVolume") do
    Type("AWS::EC2::Volume")
    Property("SnapshotId", "snap-97a09af6")
    Property("AvailabilityZone", "us-east-1a")
    Property("Tags", [
  {
    "Key"   => "Dataset",
    "Value" => "Ensembl"
  }
])
  end

  Output("InstancePublicDNS") do
    Description("Public DNS for the cluster controller instance")
    Value(FnGetAtt("Ec2Instance", "PublicDnsName"))
  end

  Output("VolumeId") do
    Description("VolumeId of the newly created EBS Volume")
    Value(Ref("NewVolume"))
  end

  Output("AvailabilityZone") do
    Description("The Availability Zone in which the newly created EC2 instance was launched")
    Value(FnGetAtt("Ec2Instance", "AvailabilityZone"))
  end
end

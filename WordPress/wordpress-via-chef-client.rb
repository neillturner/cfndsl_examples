CloudFormation do
  Description("Sample template to bring up an Opscode Chef Client using the BootStrap Chef RubyGems installation. A WaitCondition is used to hold up the stack creation until the application is deployed. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
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

  Parameter("ChefServerURL") do
    Description("URL of Chef Server")
    Type("String")
  end

  Parameter("ChefServerPrivateKeyBucket") do
    Description("S3 bucket containing validation private key for Chef Server")
    Type("String")
  end

  Parameter("ChefServerSecurityGroup") do
    Description("Security group to get access to Opscode Chef Server")
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
    "32" => "ami-d8b812d9",
    "64" => "ami-dab812db"
  },
  "ap-southeast-1" => {
    "32" => "ami-62582130",
    "64" => "ami-60582132"
  },
  "ap-southeast-2" => {
    "32" => "ami-858611bf",
    "64" => "ami-fb8611c1"
  },
  "eu-west-1"      => {
    "32" => "ami-359ea941",
    "64" => "ami-379ea943"
  },
  "sa-east-1"      => {
    "32" => "ami-e23ae5ff",
    "64" => "ami-1e39e603"
  },
  "us-east-1"      => {
    "32" => "ami-06ad526f",
    "64" => "ami-1aad5273"
  },
  "us-west-1"      => {
    "32" => "ami-116f3c54",
    "64" => "ami-136f3c56"
  },
  "us-west-2"      => {
    "32" => "ami-7ef9744e",
    "64" => "ami-60f97450"
  }
})

  Resource("ChefClientUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "cloudformation:DescribeStackResource",
            "s3:Get"
          ],
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("HostKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("ChefClientUser"))
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "ReadPolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:GetObject"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("ChefClientUser", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("ChefServerPrivateKeyBucket"),
  "/*"
]),
      "Sid"       => "ReadAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("ChefServerPrivateKeyBucket"))
  end

  Resource("ChefClient") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files"    => {
      "/etc/chef/chef.json"                                       => {
        "content" => {
          "chef_client" => {
            "server_url" => Ref("ChefServerURL")
          },
          "run_list"    => [
            "recipe[chef-client::config]",
            "recipe[chef-client]"
          ]
        },
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/chef/roles.json"                                      => {
        "content" => {
          "run_list" => [
            "role[wordpress]"
          ]
        },
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/chef/solo.rb"                                         => {
        "content" => FnJoin("
", [
  "file_cache_path \"/tmp/chef-solo\"",
  "cookbook_path \"/tmp/chef-solo/cookbooks\""
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/home/ubuntu/.s3cfg"                                       => {
        "content" => FnJoin("", [
  "[default]\n",
  "access_key = ",
  Ref("HostKeys"),
  "\n",
  "secret_key = ",
  FnGetAtt("HostKeys", "SecretAccessKey"),
  "\n",
  "use_https = True\n"
]),
        "group"   => "ubuntu",
        "mode"    => "000644",
        "owner"   => "ubuntu"
      },
      "/var/lib/gems/1.8/gems/ohai-0.6.4/lib/ohai/plugins/cfn.rb" => {
        "group"  => "root",
        "mode"   => "000644",
        "owner"  => "root",
        "source" => "https://s3.amazonaws.com/cloudformation-examples/cfn.rb"
      }
    },
    "packages" => {
      "apt"      => {
        "build-essential" => [],
        "irb"             => [],
        "libopenssl-ruby" => [],
        "rdoc"            => [],
        "ri"              => [],
        "ruby"            => [],
        "ruby-dev"        => [],
        "rubygems"        => [],
        "s3cmd"           => [],
        "ssl-cert"        => [],
        "wget"            => []
      },
      "rubygems" => {
        "chef" => [],
        "ohai" => [
          "0.6.4"
        ]
      }
    }
  }
})
    DependsOn("BucketPolicy")
    Property("SecurityGroups", [
  Ref("EC2SecurityGroup"),
  Ref("ChefServerSecurityGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "function error_exit\n",
  "{\n",
  "  cfn-signal -e 1 -r \"$1\" '",
  Ref("ChefClientWaitHandle"),
  "'\n",
  "  exit 1\n",
  "}\n",
  "apt-get -y install python-setuptools\n",
  "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
  "cfn-init --region ",
  Ref("AWS::Region"),
  "    -s ",
  Ref("AWS::StackId"),
  " -r ChefClient ",
  "         --region     ",
  Ref("AWS::Region"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Fixup path and links for the bootstrap script\n",
  "export PATH=$PATH:/var/lib/gems/1.8/bin\n",
  "# Bootstrap chef\n",
  "chef-solo -c /etc/chef/solo.rb -j /etc/chef/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz  > /tmp/chef_solo.log 2>&1 || error_exit 'Failed to bootstrap chef client'\n",
  "# Fixup the server URL in client.rb\n",
  "s3cmd -c /home/ubuntu/.s3cfg get s3://",
  Ref("ChefServerPrivateKeyBucket"),
  "/validation.pem /etc/chef/validation.pem > /tmp/get_validation_key.log 2>&1 || error_exit 'Failed to get Chef Server validation key'\n",
  "sed -i 's|http://localhost:4000|",
  Ref("ChefServerURL"),
  "|g' /etc/chef/client.rb\n",
  "chef-client -j /etc/chef/roles.json > /tmp/initialize_client.log 2>&1 || error_exit 'Failed to initialize host via chef client' \n",
  "# If all went well, signal success\n",
  "cfn-signal -e $? -r 'Chef Server configuration' '",
  Ref("ChefClientWaitHandle"),
  "'\n"
])))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("EC2SecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Open up SSH access and HTTP over port 80")
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

  Resource("ChefClientWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("ChefClientWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("ChefClient")
    Property("Handle", Ref("ChefClientWaitHandle"))
    Property("Timeout", "1200")
  end

  Output("WebsiteURL") do
    Description("URL of the WordPress website")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ChefClient", "PublicDnsName"),
  "/"
]))
  end

  Output("InstallURL") do
    Description("URL to install WordPress")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ChefClient", "PublicDnsName"),
  "/wp-admin/install.php"
]))
  end
end

CloudFormation do
  Description("Sample template to bring up an Opscode Chef Server using the BootStrap Chef RubyGems installation. This configuration creates and starts the Chef Server with the WebUI enabled, initializes knife and uploads specified cookbooks and roles to the chef server. A WaitCondition is used to hold up the stack creation until the application is deployed. **WARNING** This template creates one or more Amazon EC2 instances. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("KeyName") do
    Description("Name of an existing EC2 KeyPair to enable SSH access to the web server")
    Type("String")
  end

  Parameter("CookbookLocation") do
    Description("Location of chef cookbooks to upload to server")
    Type("String")
    Default("https://github.com/opscode/cookbooks/tarball/master")
  end

  Parameter("RoleLocation") do
    Description("Location of client roles to upload to server")
    Type("String")
    Default("https://s3.amazonaws.com/@@@CFN_EXAMPLES_DIR@@@/example_chef_roles.tar.gz")
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

  Resource("ChefServerUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => [
            "cloudformation:DescribeStackResource",
            "s3:Put"
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
    Property("UserName", Ref("ChefServerUser"))
  end

  Resource("ChefServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "chefversion" => {
    "files"    => {
      "/etc/chef/chef.json"            => {
        "content" => {
          "chef_server" => {
            "server_url"    => "http://localhost:4000",
            "webui_enabled" => true
          },
          "run_list"    => [
            "recipe[chef-server::rubygems-install]"
          ]
        },
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/etc/chef/solo.rb"              => {
        "content" => FnJoin("
", [
  "file_cache_path \"/tmp/chef-solo\"",
  "cookbook_path \"/tmp/chef-solo/cookbooks\""
]),
        "group"   => "root",
        "mode"    => "000644",
        "owner"   => "root"
      },
      "/home/ubuntu/.s3cfg"            => {
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
      "/home/ubuntu/setup_environment" => {
        "group"  => "ubuntu",
        "mode"   => "000755",
        "owner"  => "ubuntu",
        "source" => "https://s3.amazonaws.com/@@@CFN_EXAMPLES_DIR@@@/setup-chef-server-with-knife"
      }
    },
    "packages" => {
      "rubygems" => {
        "chef" => [
          "10.18.2"
        ],
        "ohai" => []
      }
    },
    "sources"  => {
      "/home/ubuntu/chef-repo"           => "https://github.com/opscode/chef-repo/tarball/master",
      "/home/ubuntu/chef-repo/cookbooks" => Ref("CookbookLocation"),
      "/home/ubuntu/chef-repo/roles"     => Ref("RoleLocation")
    }
  },
  "configSets"  => {
    "orderby" => [
      "gems",
      "chefversion"
    ]
  },
  "gems"        => {
    "packages" => {
      "apt"      => {
        "build-essential" => [],
        "git"             => [],
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
        "net-ssh"         => [
          "2.2.2"
        ],
        "net-ssh-gateway" => [
          "1.1.0"
        ]
      }
    }
  }
})
    Property("SecurityGroups", [
  Ref("ChefServerSecurityGroup")
])
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("InstanceType"), "Arch")))
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash\n",
  "function error_exit\n",
  "{\n",
  "  cfn-signal -e 1 -r \"$1\" '",
  Ref("ChefServerWaitHandle"),
  "'\n",
  "  exit 1\n",
  "}\n",
  "apt-get -y install python-setuptools\n",
  "easy_install https://s3.amazonaws.com/@@@CFN_EXAMPLES_DIR@@@/aws-cfn-bootstrap-latest.tar.gz\n",
  "cfn-init --region ",
  Ref("AWS::Region"),
  "    -s ",
  Ref("AWS::StackId"),
  " -r ChefServer ",
  " -c orderby ",
  "         --access-key ",
  Ref("HostKeys"),
  "         --secret-key ",
  FnGetAtt("HostKeys", "SecretAccessKey"),
  " || error_exit 'Failed to run cfn-init'\n",
  "# Bootstrap chef\n",
  "export PATH=$PATH:/var/lib/gems/1.8/bin\n",
  "ln -s /var/lib/gems/1.8/bin/chef-solo /usr/bin/chef-solo\n",
  "ln -s /var/lib/gems/1.8/bin/chef-server /usr/bin/chef-server\n",
  "ln -s /var/lib/gems/1.8/bin/chef-server-webui /usr/bin/chef-server-webui\n",
  "ln -s /var/lib/gems/1.8/bin/chef-solr /usr/bin/chef-solr\n",
  "ln -s /var/lib/gems/1.8/bin/chef-expander /usr/bin/chef-expander\n",
  "ln -s /var/lib/gems/1.8/bin/knife /usr/bin/knife\n",
  "ln -s /var/lib/gems/1.8/bin/rake /usr/bin/rake\n",
  "chef-solo -c /etc/chef/solo.rb -j /etc/chef/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz  > /tmp/chef_solo.log 2>&1 || error_exit 'Failed to bootstrap chef server'\n",
  "# Setup development environment in ubuntu user\n",
  "sudo -u ubuntu /home/ubuntu/setup_environment > /tmp/setup_environment.log 2>&1 || error_exit 'Failed to bootstrap chef server'\n",
  "# copy validation key to S3 bucket\n",
  "s3cmd -c /home/ubuntu/.s3cfg put /etc/chef/validation.pem s3://",
  Ref("PrivateKeyBucket"),
  "/validation.pem > /tmp/put_validation_key.log 2>&1 || error_exit 'Failed to put Chef Server validation key'\n",
  "# If all went well, signal success\n",
  "cfn-signal -e $? -r 'Chef Server configuration' '",
  Ref("ChefServerWaitHandle"),
  "'\n"
])))
    Property("KeyName", Ref("KeyName"))
    Property("InstanceType", Ref("InstanceType"))
  end

  Resource("ChefServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Open up SSH access plus Chef Server required ports")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  },
  {
    "FromPort"                => "4000",
    "IpProtocol"              => "tcp",
    "SourceSecurityGroupName" => Ref("ChefClientSecurityGroup"),
    "ToPort"                  => "4000"
  },
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => "4040",
    "IpProtocol" => "tcp",
    "ToPort"     => "4040"
  }
])
  end

  Resource("ChefClientSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Group with access to Chef Server")
  end

  Resource("PrivateKeyBucket") do
    Type("AWS::S3::Bucket")
    DeletionPolicy("Delete")
    Property("AccessControl", "Private")
  end

  Resource("BucketPolicy") do
    Type("AWS::S3::BucketPolicy")
    Property("PolicyDocument", {
  "Id"        => "WritePolicy",
  "Statement" => [
    {
      "Action"    => [
        "s3:PutObject"
      ],
      "Effect"    => "Allow",
      "Principal" => {
        "AWS" => FnGetAtt("ChefServerUser", "Arn")
      },
      "Resource"  => FnJoin("", [
  "arn:aws:s3:::",
  Ref("PrivateKeyBucket"),
  "/*"
]),
      "Sid"       => "WriteAccess"
    }
  ],
  "Version"   => "2008-10-17"
})
    Property("Bucket", Ref("PrivateKeyBucket"))
  end

  Resource("ChefServerWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("ChefServerWaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("ChefServer")
    Property("Handle", Ref("ChefServerWaitHandle"))
    Property("Timeout", "1200")
  end

  Output("WebUI") do
    Description("URL of Opscode chef server WebUI")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ChefServer", "PublicDnsName"),
  ":4040"
]))
  end

  Output("ServerURL") do
    Description("URL of newly created Opscode chef server")
    Value(FnJoin("", [
  "http://",
  FnGetAtt("ChefServer", "PublicDnsName"),
  ":4000"
]))
  end

  Output("ChefSecurityGroup") do
    Description("EC2 Security Group with access to Opscode chef server")
    Value(Ref("ChefClientSecurityGroup"))
  end

  Output("ValidationKeyBucket") do
    Description("Location of validation key")
    Value(Ref("PrivateKeyBucket"))
  end
end

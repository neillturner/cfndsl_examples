CloudFormation do
  Description("AWS CloudFormation Sample Template MineCraft_Server: Minecraft is a game about placing blocks to build anything you can imagine. At night monsters come out, make sure to build a shelter before that happens. **WARNING** This template creates an Amazon EC2 instance. You will be billed for the AWS resources used if you create a stack from this template.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("Difficulty") do
    Description("Defines the difficulty (such as damage dealt by mobs and the way hunger and poison affects players) of the server")
    Type("String")
    Default("Easy")
    AllowedValues([
  "Peaceful",
  "Easy",
  "Normal",
  "Hard"
])
    ConstraintDescription("must be one of Peaceful, Easy, Normal, Hard.")
  end

  Parameter("GameMode") do
    Description("Defines the mode of gameplay")
    Type("String")
    Default("Survival")
    AllowedValues([
  "Survival",
  "Creative"
])
    ConstraintDescription("must be one of Survival, Creative.")
  end

  Parameter("Message") do
    Description("This is the message that is displayed in the server list of the client, below the name")
    Type("String")
    Default("Minecraft in the AWS Cloud")
  end

  Parameter("LevelName") do
    Description("The level-name value will be used as the world name and its folder name.")
    Type("String")
    Default("world")
  end

  Parameter("NumberOfPlayers") do
    Description("Number of players this Minecraft server will support (1, up to 10, up to 25, up to 100, up to 200)")
    Type("Number")
    Default("1")
    AllowedValues([
  "1",
  "10",
  "25",
  "100",
  "200"
])
    ConstraintDescription("must be one of 1,10,25,100,200.")
  end

  Parameter("LevelSeed") do
    Description("Seed for level generation")
    Type("String")
    Default("HelloWorld")
  end

  Parameter("PvP") do
    Description("Enable PvP on the server. Note: Hitting a player while having PvP set to false and having tamed wolves will still cause the wolves to attack the player who was hit. true - Players will be able to kill each other. false - Players cannot kill other players (Also called PvE)")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("SpawnNPCS") do
    Description("Determines if non-player characters (NPCs) will be spawned")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("SpawnAnimals") do
    Description("Determines if Animals will be able to spawn")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("SpawnMonsters") do
    Description("Determines if monsters will be spawned")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("GenerateStructures") do
    Description("Defines whether structures (such as NPC Villages) will be generated")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("AllowNether") do
    Description("Allows players to travel to the Nether")
    Type("String")
    Default("true")
    AllowedValues([
  "true",
  "false"
])
    ConstraintDescription("must be one of true, false.")
  end

  Parameter("LevelType") do
    Description("Determines the type of map that is generated. DEFAULT - Standard world with hills, valleys, water, etc. FLAT - A flat world with no features, meant for building.")
    Type("String")
    Default("DEFAULT")
    AllowedValues([
  "DEFAULT",
  "FLAT"
])
    ConstraintDescription("must be one of DEFAULT, FLAT.")
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
  "1"   => {
    "Arch"         => "32",
    "InstanceType" => "t1.micro",
    "MemSize"      => "512"
  },
  "10"  => {
    "Arch"         => "32",
    "InstanceType" => "m1.small",
    "MemSize"      => "1024"
  },
  "100" => {
    "Arch"         => "64",
    "InstanceType" => "m1.large",
    "MemSize"      => "1024"
  },
  "200" => {
    "Arch"         => "64",
    "InstanceType" => "m1.xlarge",
    "MemSize"      => "1024"
  },
  "25"  => {
    "Arch"         => "64",
    "InstanceType" => "m1.medium",
    "MemSize"      => "1024"
  }
})

  Mapping("AWSRegionArch2AMI", {
  "ap-northeast-1" => {
    "32" => "ami-dcfa4edd",
    "64" => "ami-e8fa4ee9"
  },
  "ap-southeast-1" => {
    "32" => "ami-74dda626",
    "64" => "ami-7edda62c"
  },
  "ap-southeast-2" => {
    "32" => "ami-b3990e89",
    "64" => "ami-bd990e87"
  },
  "eu-west-1"      => {
    "32" => "ami-24506250",
    "64" => "ami-20506254"
  },
  "sa-east-1"      => {
    "32" => "ami-3e3be423",
    "64" => "ami-3c3be421"
  },
  "us-east-1"      => {
    "32" => "ami-7f418316",
    "64" => "ami-7341831a"
  },
  "us-west-1"      => {
    "32" => "ami-951945d0",
    "64" => "ami-971945d2"
  },
  "us-west-2"      => {
    "32" => "ami-16fd7026",
    "64" => "ami-10fd7020"
  }
})

  Mapping("CommonProperties", {
  "Difficulty"       => {
    "Easy"     => "1",
    "Hard"     => "3",
    "Normal"   => "2",
    "Peaceful" => "0"
  },
  "GameMode"         => {
    "Creative" => "1",
    "Survival" => "0"
  },
  "ServerProperties" => {
    "Port" => "25565"
  }
})

  Resource("CfnUser") do
    Type("AWS::IAM::User")
    Property("Path", "/")
    Property("Policies", [
  {
    "PolicyDocument" => {
      "Statement" => [
        {
          "Action"   => "cloudformation:DescribeStackResource",
          "Effect"   => "Allow",
          "Resource" => "*"
        }
      ]
    },
    "PolicyName"     => "root"
  }
])
  end

  Resource("CfnKeys") do
    Type("AWS::IAM::AccessKey")
    Property("UserName", Ref("CfnUser"))
  end

  Resource("EIP") do
    Type("AWS::EC2::EIP")
    Property("InstanceId", Ref("MinecraftServer"))
  end

  Resource("MinecraftServer") do
    Type("AWS::EC2::Instance")
    Metadata("AWS::CloudFormation::Init", {
  "config" => {
    "files" => {
      "/home/ec2-user/minecraft.sh"         => {
        "content" => FnJoin("", [
  "#!/bin/sh\n",
  "cd /home/ec2-user\n",
  "java -Xmx",
  FnFindInMap("AWSInstanceType2Arch", Ref("NumberOfPlayers"), "MemSize"),
  "m -Xms",
  FnFindInMap("AWSInstanceType2Arch", Ref("NumberOfPlayers"), "MemSize"),
  "m -jar minecraft_server.jar nogui &\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000755",
        "owner"   => "ec2-user"
      },
      "/home/ec2-user/minecraft_server.jar" => {
        "group"  => "ec2-user",
        "mode"   => "000644",
        "owner"  => "ec2-user",
        "source" => "http://www.minecraft.net/download/minecraft_server.jar"
      },
      "/home/ec2-user/server.properties"    => {
        "content" => FnJoin("", [
  "#Minecraft server properties\n",
  "allow-nether=",
  Ref("AllowNether"),
  "\n",
  "level-name=",
  Ref("LevelName"),
  "\n",
  "enable-query=false\n",
  "allow-flight=false\n",
  "server-port=",
  FnFindInMap("CommonProperties", "ServerProperties", "Port"),
  "\n",
  "level-type=",
  Ref("LevelType"),
  "\n",
  "enable-rcon=false\n",
  "level-seed=",
  Ref("LevelSeed"),
  "\n",
  "server-ip=\n",
  "white-list=false\n",
  "difficulty=",
  FnFindInMap("CommonProperties", "Difficulty", Ref("Difficulty")),
  "\n",
  "gamemode=",
  FnFindInMap("CommonProperties", "GameMode", Ref("GameMode")),
  "\n",
  "max-players=",
  Ref("NumberOfPlayers"),
  "\n",
  "pvp=",
  Ref("PvP"),
  "\n",
  "spawn-npcs=",
  Ref("SpawnNPCS"),
  "\n",
  "spawn-animals=",
  Ref("SpawnAnimals"),
  "\n",
  "spawn-monsters=",
  Ref("SpawnMonsters"),
  "\n",
  "generate-structures=",
  Ref("GenerateStructures"),
  "\n",
  "view-distance=10\n",
  "online-mode=true\n",
  "motd=",
  Ref("Message"),
  "\n"
]),
        "group"   => "ec2-user",
        "mode"    => "000644",
        "owner"   => "ec2-user"
      }
    }
  }
})
    Property("ImageId", FnFindInMap("AWSRegionArch2AMI", Ref("AWS::Region"), FnFindInMap("AWSInstanceType2Arch", Ref("NumberOfPlayers"), "Arch")))
    Property("InstanceType", FnFindInMap("AWSInstanceType2Arch", Ref("NumberOfPlayers"), "InstanceType"))
    Property("SecurityGroups", [
  Ref("MinecraftServerSecurityGroup")
])
    Property("UserData", FnBase64(FnJoin("", [
  "#!/bin/bash -v\n",
  "yum update -y aws-cfn-bootstrap\n",
  "# Install Minecraft\n",
  "/opt/aws/bin/cfn-init -s ",
  Ref("AWS::StackId"),
  " -r MinecraftServer ",
  "    --access-key ",
  Ref("CfnKeys"),
  "    --secret-key ",
  FnGetAtt("CfnKeys", "SecretAccessKey"),
  "    --region ",
  Ref("AWS::Region"),
  "\n",
  "# Signal status\n",
  "/opt/aws/bin/cfn-signal -e $? '",
  Ref("WaitHandle"),
  "'\n",
  "# Start the server\n",
  "/home/ec2-user/minecraft.sh &\n"
])))
  end

  Resource("WaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Resource("WaitCondition") do
    Type("AWS::CloudFormation::WaitCondition")
    DependsOn("MinecraftServer")
    Property("Handle", Ref("WaitHandle"))
    Property("Timeout", "600")
  end

  Resource("MinecraftServerSecurityGroup") do
    Type("AWS::EC2::SecurityGroup")
    Property("GroupDescription", "Enable SSH access and access to the Minecraft server")
    Property("SecurityGroupIngress", [
  {
    "CidrIp"     => "0.0.0.0/0",
    "FromPort"   => FnFindInMap("CommonProperties", "ServerProperties", "Port"),
    "IpProtocol" => "tcp",
    "ToPort"     => FnFindInMap("CommonProperties", "ServerProperties", "Port")
  },
  {
    "CidrIp"     => Ref("SSHLocation"),
    "FromPort"   => "22",
    "IpProtocol" => "tcp",
    "ToPort"     => "22"
  }
])
  end

  Output("MinecraftServer") do
    Description("Address of Minecraft Server")
    Value(Ref("EIP"))
  end
end

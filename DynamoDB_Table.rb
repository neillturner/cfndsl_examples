CloudFormation do
  Description("AWS CloudFormation Sample Template: This template demonstrates the creation of a DynamoDB table.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("HaskKeyElementName") do
    Description("HashType PrimaryKey Name")
    Type("String")
    AllowedPattern("[a-zA-Z0-9]*")
    MaxLength(2048)
    MinLength(1)
    ConstraintDescription("must contain only alphanumberic characters")
  end

  Parameter("HaskKeyElementType") do
    Description("HashType PrimaryKey Type")
    Type("String")
    Default("S")
    AllowedPattern("[S|N]")
    MaxLength(1)
    MinLength(1)
    ConstraintDescription("must be either S or N")
  end

  Parameter("ReadCapacityUnits") do
    Description("Provisioned read throughput")
    Type("Number")
    Default("5")
    MaxValue(10000)
    MinValue(5)
    ConstraintDescription("should be between 5 and 10000")
  end

  Parameter("WriteCapacityUnits") do
    Description("Provisioned write throughput")
    Type("Number")
    Default("10")
    MaxValue(10000)
    MinValue(5)
    ConstraintDescription("should be between 5 and 10000")
  end

  Resource("myDynamoDBTable") do
    Type("AWS::DynamoDB::Table")
    Property("KeySchema", {
  "HashKeyElement" => {
    "AttributeName" => Ref("HaskKeyElementName"),
    "AttributeType" => Ref("HaskKeyElementType")
  }
})
    Property("ProvisionedThroughput", {
  "ReadCapacityUnits"  => Ref("ReadCapacityUnits"),
  "WriteCapacityUnits" => Ref("WriteCapacityUnits")
})
  end

  Output("TableName") do
    Description("Table name of the newly create DynamoDB table")
    Value(Ref("myDynamoDBTable"))
  end
end

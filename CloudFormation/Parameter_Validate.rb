CloudFormation do
  Description("AWS CloudFormation Sample Template Parameter_Validate: Sample template showing how to validate string and numeric parameters. This template does not create any billable AWS Resources.")
  AWSTemplateFormatVersion("2010-09-09")

  Parameter("NumberWithRange") do
    Description("Enter a number between 1 and 10, default is 2")
    Type("Number")
    Default("2")
    MaxValue(10)
    MinValue(1)
  end

  Parameter("NumberWithAllowedValues") do
    Description("Enter 1,2,3,10 or 20, default is 2")
    Type("Number")
    Default("2")
    AllowedValues([
  "1",
  "2",
  "3",
  "10",
  "20"
])
  end

  Parameter("StringWithLength") do
    Description("Enter a string, between 5 and 20 characters in length")
    Type("String")
    Default("Hello World")
    MaxLength(20)
    MinLength(5)
    ConstraintDescription("must have beteen 5 and 20 characters")
  end

  Parameter("StringWithAllowedValues") do
    Description("Enter t1.micro, m1.small, default is t1.micro")
    Type("String")
    Default("t1.micro")
    AllowedValues([
  "t1.micro",
  "m1.small"
])
  end

  Parameter("StringWithRegex") do
    Description("Enter a string with alpha-numeric characters only")
    Type("String")
    Default("Hello")
    AllowedPattern("[A-Za-z0-9]+")
    MaxLength(10)
    ConstraintDescription("must only contain upper and lower case letters and numbers")
  end

  Resource("myWaitHandle") do
    Type("AWS::CloudFormation::WaitConditionHandle")
  end

  Output("NumberWithRange") do
    Value(Ref("NumberWithRange"))
  end

  Output("NumberWithAllowedValues") do
    Value(Ref("NumberWithAllowedValues"))
  end

  Output("StringWithLength") do
    Value(Ref("StringWithLength"))
  end

  Output("StringWithAllowedValue") do
    Value(Ref("StringWithAllowedValues"))
  end

  Output("StringWithRegex") do
    Value(Ref("StringWithRegex"))
  end
end

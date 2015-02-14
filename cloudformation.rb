CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Mapping("LightColor", {
  "Go"       => {
    "Description" => "green",
    "RGBColor"    => "RED 0 GREEN 128 BLUE 0"
  },
  "SlowDown" => {
    "Description" => "yellow",
    "RGBColor"    => "RED 255 GREEN 255 BLUE 0"
  },
  "Stop"     => {
    "Description" => "red",
    "RGBColor"    => "RED 255 GREEN 0 BLUE 0"
  }
})

  Resource("UserData") do
    Type("")
  end

  Resource("UserData2") do
    Type("")
  end

  Resource("Parameters") do
    Type("")
  end

  Resource("Parameters2") do
    Type("")
  end

  Resource("Parameters3") do
    Type("")
  end

  Resource("Parameters4") do
    Type("")
  end

  Resource("Parameters5") do
    Type("")
  end

  Resource("Parameters6") do
    Type("")
  end

  Output("MyPhone") do
    Description("A random message for aws cloudformation describe-stacks")
    Value("Please call 555-5555")
  end
end

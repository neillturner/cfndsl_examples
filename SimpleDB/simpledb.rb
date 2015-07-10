CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

# Amazon SimpleDB Domain Resource
  Resource("MySDBDomain") do
    Type("AWS::SDB::Domain")
    Property("Description", "Other than this AWS CloudFormation Description property, SDB Domains have no properties.")
  end
end

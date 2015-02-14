CloudFormation do
  AWSTemplateFormatVersion("2010-09-09")

  Resource("myDistribution") do
    Type("AWS::CloudFront::Distribution")
    Property("DistributionConfig", {
  "Aliases"              => [
    "mysite.example.com",
    "yoursite.example.com"
  ],
  "Comment"              => "Some comment",
  "DefaultCacheBehavior" => {
    "AllowedMethods"       => [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT"
    ],
    "ForwardedValues"      => {
      "Cookies"     => {
        "Forward" => "none"
      },
      "QueryString" => "false"
    },
    "TargetOriginId"       => "myS3Origin",
    "TrustedSigners"       => [
      "1234567890EX",
      "1234567891EX"
    ],
    "ViewerProtocolPolicy" => "allow-all"
  },
  "DefaultRootObject"    => "index.html",
  "Enabled"              => "true",
  "Logging"              => {
    "Bucket"         => "mylogs.s3.amazonaws.com",
    "IncludeCookies" => "false",
    "Prefix"         => "myprefix"
  },
  "Origins"              => [
    {
      "DomainName"     => "mybucket.s3.amazonaws.com",
      "Id"             => "myS3Origin",
      "S3OriginConfig" => {
        "OriginAccessIdentity" => "origin-access-identity/cloudfront/E127EXAMPLE51Z"
      }
    }
  ],
  "PriceClass"           => "PriceClass_200",
  "Restrictions"         => {
    "GeoRestriction" => {
      "Locations"       => [
        "AQ",
        "CV"
      ],
      "RestrictionType" => "whitelist"
    }
  },
  "ViewerCertificate"    => {
    "CloudFrontDefaultCertificate" => "true"
  }
})
  end

  Resource("myDistribution2") do
    Type("AWS: : CloudFront: : Distribution")
    Property("DistributionConfig", {
  "Aliases"              => [
    "mysite.example.com",
    "*.yoursite.example.com"
  ],
  "Comment"              => "Somecomment",
  "CustomErrorResponses" => [
    {
      "ErrorCachingMinTTL" => "30",
      "ErrorCode"          => "404",
      "ResponseCode"       => "200",
      "ResponsePagePath"   => "/error-pages/404.html"
    }
  ],
  "DefaultCacheBehavior" => {
    "ForwardedValues"      => {
      "Cookies"     => {
        "Forward" => "all"
      },
      "QueryString" => "false"
    },
    "SmoothStreaming"      => "false",
    "TargetOriginId"       => "myCustomOrigin",
    "TrustedSigners"       => [
      "1234567890EX",
      "1234567891EX"
    ],
    "ViewerProtocolPolicy" => "allow-all"
  },
  "DefaultRootObject"    => "index.html",
  "Enabled"              => "true",
  "Logging"              => {
    "Bucket"         => "mylogs.s3.amazonaws.com",
    "IncludeCookies" => "true",
    "Prefix"         => "myprefix"
  },
  "Origins"              => [
    {
      "CustomOriginConfig" => {
        "HTTPPort"             => "80",
        "HTTPSPort"            => "443",
        "OriginProtocolPolicy" => "http-only"
      },
      "DomainName"         => "www.example.com",
      "Id"                 => "myCustomOrigin"
    }
  ],
  "PriceClass"           => "PriceClass_200",
  "Restrictions"         => {
    "GeoRestriction" => {
      "Locations"       => [
        "AQ",
        "CV"
      ],
      "RestrictionType" => "whitelist"
    }
  },
  "ViewerCertificate"    => {
    "CloudFrontDefaultCertificate" => "true"
  }
})
  end

  Resource("myDistribution3") do
    Type("AWS::CloudFront::Distribution")
    Property("DistributionConfig", {
  "Aliases"              => [
    "mysite.example.com",
    "yoursite.example.com"
  ],
  "CacheBehaviors"       => [
    {
      "AllowedMethods"       => [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"
      ],
      "ForwardedValues"      => {
        "Cookies"     => {
          "Forward" => "none"
        },
        "QueryString" => "true"
      },
      "MinTTL"               => "50",
      "PathPattern"          => "images1/*.jpg",
      "TargetOriginId"       => "myS3Origin",
      "TrustedSigners"       => [
        "1234567890EX",
        "1234567891EX"
      ],
      "ViewerProtocolPolicy" => "allow-all"
    },
    {
      "AllowedMethods"       => [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"
      ],
      "ForwardedValues"      => {
        "Cookies"     => {
          "Forward" => "none"
        },
        "QueryString" => "true"
      },
      "MinTTL"               => "50",
      "PathPattern"          => "images2/*.jpg",
      "TargetOriginId"       => "myCustomOrigin",
      "TrustedSigners"       => [
        "1234567890EX",
        "1234567891EX"
      ],
      "ViewerProtocolPolicy" => "allow-all"
    }
  ],
  "Comment"              => "Some comment",
  "CustomErrorResponses" => [
    {
      "ErrorCachingMinTTL" => "30",
      "ErrorCode"          => "404",
      "ResponseCode"       => "200",
      "ResponsePagePath"   => "/error-pages/404.html"
    }
  ],
  "DefaultCacheBehavior" => {
    "ForwardedValues"      => {
      "Cookies"     => {
        "Forward" => "all"
      },
      "QueryString" => "false"
    },
    "MinTTL"               => "100",
    "SmoothStreaming"      => "true",
    "TargetOriginId"       => "myS3Origin",
    "TrustedSigners"       => [
      "1234567890EX",
      "1234567891EX"
    ],
    "ViewerProtocolPolicy" => "allow-all"
  },
  "DefaultRootObject"    => "index.html",
  "Enabled"              => "true",
  "Logging"              => {
    "Bucket"         => "mylogs.s3.amazonaws.com",
    "IncludeCookies" => "true",
    "Prefix"         => "myprefix"
  },
  "Origins"              => [
    {
      "DomainName"     => "mybucket.s3.amazonaws.com",
      "Id"             => "myS3Origin",
      "S3OriginConfig" => {
        "OriginAccessIdentity" => "origin-access-identity/cloudfront/E127EXAMPLE51Z"
      }
    },
    {
      "CustomOriginConfig" => {
        "HTTPPort"             => "80",
        "HTTPSPort"            => "443",
        "OriginProtocolPolicy" => "http-only"
      },
      "DomainName"         => "www.example.com",
      "Id"                 => "myCustomOrigin"
    }
  ],
  "PriceClass"           => "PriceClass_All",
  "ViewerCertificate"    => {
    "CloudFrontDefaultCertificate" => "true"
  }
})
  end
end

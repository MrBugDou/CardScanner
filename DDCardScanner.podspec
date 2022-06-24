#
# Be sure to run `pod lib lint DDCardScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = "DDCardScanner"
  s.version = "1.0.0"
  s.summary = "DDCardScanner."
  s.description = <<-DESC
                       身份证、银行卡扫描
                       DESC

  s.homepage = "https://github.com/MrBugDou/CardScanner"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "DouDou" => "bg1859710@gmail.com" }
  s.source = { :git => "https://github.com/MrBugDou/CardScanner.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.swift_version = "5.0"
  s.platform = :ios, "9.0"
  s.static_framework = true

  s.default_subspecs = "Core", "Swift"

  s.subspec "Core" do |core|
    core.user_target_xcconfig = {
      "ENABLE_TESTABILITY" => "NO",
    }

    core.pod_target_xcconfig = {
      "ENABLE_TESTABILITY" => "NO",
    }

    core.resource_bundles = {
      "CoreBundle" => [
        "CardScanner/Src/lib/libIDcard/dicts/zocr0.lib",
      ],
    }

    core.source_files = [
      "CardScanner/Src/lib/libIDcard/*.h",
      "CardScanner/Src/lib/libBankcard/exbankcard.h",
    ]

    core.vendored_libraries = [
      "CardScanner/Src/lib/libIDcard/**/*.a",
      "CardScanner/Src/lib/libBankcard/**/*.a",
    ]
  end

  s.subspec "Swift" do |ss|
    ss.source_files = [
      "CardScanner/Src/Swift/*.swift",
    ]
    ss.dependency "DDCardScanner/Core"
  end
end

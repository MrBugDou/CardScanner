source "https://github.com/CocoaPods/Specs.git"

platform :ios, "11.0"
inhibit_all_warnings!
use_frameworks! :linkage => :dynamic
install! "cocoapods", :warn_for_unused_master_specs_repo => false

target "CardScanner" do
  pod "DDCardScanner", :path => "./"
  pod "Toast-Swift"
  pod "SnapKit"
  pod "R.swift"

  target "CardScannerTests" do
    inherit! :search_paths
  end

  target "CardScannerUITests" do
    inherit! :search_paths
  end
end

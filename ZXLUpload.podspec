Pod::Spec.new do |s|

    s.name         = "ZXLUpload"
    s.version      = "1.0.8"
    s.summary      = "A Library for iOS to use for upload"
    s.homepage     = "https://github.com/ZXLBoaConstrictor"
    s.license      = "MIT"
    s.author             = { "zhangxiaolong" => "244061043@qq.com" }
    s.platform     = :ios, "9.0"
    s.source       = { :git => "https://github.com/ZXLBoaConstrictor/ZXLUpload.git", :tag => "#{s.version}" }
    s.source_files  = "Framework/ZXLUpload/*.{h,m}"
    s.resources    = 'Framework/ZXLUpload.bundle'
    s.framework  = "SystemConfiguration","CoreTelephony","Photos"
    s.requires_arc = true
    s.dependency "FMDB"
end

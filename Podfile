platform :ios, '14.0'
# 消除第三方库警告
inhibit_all_warnings!
## 忽略.cocoaPods中多个specs源引起的警告问题
install! 'cocoaPods', :warn_for_unused_master_specs_repo => false

target 'BlindHelp' do

# Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  #网络请求
  pod 'Alamofire'
  #pod 'AlamofireImage'
  pod 'ReachabilitySwift'
  #约束控件
  pod 'Masonry'
  #keychain
  pod 'KeychainSwift'
  #获取机型
  pod 'DeviceKit'
  #约束控件
  pod 'SnapKit'
  #提示
  pod 'Toast-Swift'
  #模型转换Data数据转成模型
  pod 'HandyJSON'
  pod 'SwiftyJSON'
  #网络加载图片,SWWebImge的Swift版本.
  pod 'Kingfisher'
  #基于Reachability开发的网络检测框架
  pod "Connectivity"
  
  #键盘管理
  pod 'IQKeyboardManagerSwift'
  pod 'DefaultsKit'
  pod 'SwiftyStoreKit'
  pod 'GradientProgressBar'
  # OC
  #pod 'MBProgressHUD',:git => 'https://github.com/jdg/MBProgressHUD.git'
  #pod 'MJRefresh'
  #pod 'TZImagePickerController'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO' # Fix Xcode14 bundle need sign
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end

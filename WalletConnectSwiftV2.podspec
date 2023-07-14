require "json"

package = JSON.parse(File.read(File.join(__dir__, "Sources/WalletConnectRelay/PackageConfig.json")))

#
#  Be sure to run `pod spec lint WalletConnectSwiftV2.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name        = "WalletConnectSwiftV2"
  spec.version     = package["version"]
  spec.summary     = "Swift implementation of WalletConnect v.2 protocol for native iOS applications."
  spec.description = "The communications protocol for web3, WalletConnect brings the ecosystem together by enabling wallets and apps to securely connect and interact."
  spec.homepage    = "https://walletconnect.com"
  spec.license     = { :type => 'Apache-2.0', :file => 'LICENSE' }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.authors          = "WalletConnect, Inc."
  spec.social_media_url = "https://twitter.com/WalletConnect"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source = {
    :git => 'https://github.com/WalletConnect/WalletConnectSwiftV2.git',
    :tag => spec.version.to_s
  }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  ios_deployment_target  = '13.0'
  osx_deployment_target  = '10.15'
  tvos_deployment_target = '13.0'

  spec.swift_versions = '5.3'

  spec.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DCocoaPods'
  }

  spec.ios.deployment_target  = ios_deployment_target
  spec.osx.deployment_target  = osx_deployment_target
  spec.tvos.deployment_target = tvos_deployment_target

  # ――― Sub Specs ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.default_subspecs = 'WalletConnect'

  spec.subspec 'WalletConnect' do |ss|
    ss.source_files = 'Sources/Web3Wallet/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectSign'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectAuth'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectEcho'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectVerify'
  end

  spec.subspec 'WalletConnectSign' do |ss|
    ss.source_files = 'Sources/WalletConnectSign/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectPairing'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectVerify'
  end

  spec.subspec 'WalletConnectAuth' do |ss|
    ss.source_files = 'Sources/Auth/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectPairing'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectSigner'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectVerify'
  end
  
  spec.subspec 'WalletConnectVerify' do |ss|
    ss.source_files = 'Sources/WalletConnectVerify/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectUtils'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectNetworking'
  end

  spec.subspec 'WalletConnectHistory' do |ss|
    ss.source_files = 'Sources/WalletConnectHistory/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectRelay'
    ss.dependency 'WalletConnectSwiftV2/HTTPClient'
  end

  spec.subspec 'WalletConnectChat' do |ss|
    ss.source_files = 'Sources/Chat/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectSync'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectIdentity'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectHistory'
  end

  spec.subspec 'WalletConnectSync' do |ss|
    ss.source_files = 'Sources/WalletConnectSync/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectSigner'
  end

  spec.subspec 'WalletConnectSigner' do |ss|
    ss.source_files = 'Sources/WalletConnectSigner/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectNetworking'
  end

  spec.subspec 'WalletConnectIdentity' do |ss|
    ss.source_files = 'Sources/WalletConnectIdentity/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectNetworking'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectJWT'
  end

  spec.subspec 'WalletConnectEcho' do |ss|
    ss.source_files = 'Sources/WalletConnectEcho/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectNetworking'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectJWT'
  end

  spec.subspec 'WalletConnectJWT' do |ss|
    ss.source_files = 'Sources/WalletConnectJWT/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectKMS'
  end

  spec.subspec 'WalletConnectNetworking' do |ss|
    ss.source_files = 'Sources/WalletConnectNetworking/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectRelay'
    ss.dependency 'WalletConnectSwiftV2/HTTPClient'
  end

  spec.subspec 'WalletConnectPairing' do |ss|
    ss.source_files = 'Sources/WalletConnectPairing/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectNetworking'
  end

  spec.subspec 'WalletConnectRouter' do |ss|
    ss.source_files = 'Sources/WalletConnectRouter/**/*.{h,m,swift}'
    ss.platform = :ios
  end

  spec.subspec 'WalletConnectRelay' do |ss|
    ss.source_files = 'Sources/WalletConnectRelay/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectJWT'
    ss.resource_bundles = {
      'WalletConnect_WalletConnectRelay' => [
         'Sources/WalletConnectRelay/PackageConfig.json'
      ]
    }
  end

  spec.subspec 'WalletConnectUtils' do |ss|
    ss.source_files = 'Sources/WalletConnectUtils/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/JSONRPC'
  end

  spec.subspec 'WalletConnectKMS' do |ss|
    ss.source_files = 'Sources/WalletConnectKMS/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/WalletConnectUtils'
  end

  spec.subspec 'Commons' do |ss|
    ss.source_files = 'Sources/Commons/**/*.{h,m,swift}'
  end

  spec.subspec 'JSONRPC' do |ss|
    ss.source_files = 'Sources/JSONRPC/**/*.{h,m,swift}'
    ss.dependency 'WalletConnectSwiftV2/Commons'
  end
  
  spec.subspec 'HTTPClient' do |ss|
    ss.source_files = 'Sources/HTTPClient/**/*.{h,m,swift}'
  end
end

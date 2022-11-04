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
  spec.version     = "1.0.0-test-tag-2"
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
    :tag => 'v' + spec.version.to_s
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

  spec.ios.deployment_target  = ios_deployment_target
  spec.osx.deployment_target  = osx_deployment_target
  spec.tvos.deployment_target = tvos_deployment_target

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files = "Sources/**/*.swift"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  spec.dependency "WalletConnectWeb3", "1.0.0"

end

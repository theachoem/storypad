#
# storypad_editor's macOS side (a native right-click menu). Also a Swift package: storypad_editor/Package.swift.
#
Pod::Spec.new do |s|
  s.name             = 'storypad_editor'
  s.version          = '0.1.0'
  s.summary          = 'storypad_editor on macOS: the native right-click menu.'
  s.description      = <<-DESC
  The editor's right-click menu as a native NSMenu, with the Services submenu.
                       DESC
  s.homepage         = 'https://github.com/theachoem/storypad'
  s.license          = { :type => 'Proprietary' }
  s.author           = 'StoryPad'
  s.source           = { :path => '.' }
  s.source_files     = 'storypad_editor/Sources/storypad_editor/**/*.swift'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end

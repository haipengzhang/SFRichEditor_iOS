#
#  Be sure to run `pod spec lint ZSSRichTextEditor.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SFRichTextEditor"
  s.version      = "0.5.2.2"
  s.summary      = "SFRichTextEditor, based on ZSSRichTextEditor, add custom layout and wang editor, a beautiful Rich Text WYSIWYG Editor for iOS."

  s.description  = <<-DESC
`ZSSRichTextEditor` is a beautiful Rich Text `WYSIWYG Editor` for `iOS`. It includes all of the standard editor tools one would expect from a `WYSIWYG` editor as well as an amazing source view with syntax highlighting.
                   DESC

  s.homepage     = "https://github.com/haipengzhang/SFRichEditor_iOS"
  s.license      = "MIT"
  s.author       = { "haipeng" => "1061449734@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/haipengzhang/SFRichEditor_iOS/sfrichtexteditor.git", :tag => "0.5.2.2" }
  s.source_files = 'src/WangEditor/*.{h,m}', 'src/WangEditor/ThirdParty/*.{h,m}'
  s.resources = 'src/WangEditor/Images/*', 'src/WangEditor/WangWebResources/*'

end

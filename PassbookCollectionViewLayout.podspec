Pod::Spec.new do |s|
  s.name         = "PassbookCollectionViewLayout"
  s.version      = "0.1.0"
  s.summary      = "A Passbook collection view layout that doesn’t suck."
  s.homepage     = "https://github.com/a2/PassbookCollectionViewLayout"
  s.license      = "MIT"
  s.author             = { "Alexsander Akers" => "me@a2.io" }
  s.social_media_url   = "http://twitter.com/a2"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/a2/PassbookCollectionViewLayout.git", :tag => s.version.to_s }
  s.source_files  = "PassbookCollectionViewLayout.swift"
end

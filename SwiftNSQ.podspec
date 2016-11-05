Pod::Spec.new do |s|
	s.name                    = "SwiftNSQ"
	s.version                 = "0.1"
	s.summary                 = "A client for NSQ written in pure Swift"

	s.homepage                = "https://pilgrimagesoftware.com"
	s.license                 = { :type => 'MIT', :file => 'LICENSE' }
	s.author                  = { "Paul Schifferer" => "paul@schifferers.net" }

	s.source                  = { :git => "https://github.com/exsortis/SwiftNSQ.git", :tag => s.version.to_s }
	s.source_files            = 'Sources/SwiftNSQ/**/*.{h,m,c,swift}'
	s.frameworks              = 'Foundation'

	s.ios.deployment_target   = '9.3'
	s.osx.deployment_target   = '10.11'
	s.tvos.deployment_target  = '9.2'

	s.requires_arc            = true

end

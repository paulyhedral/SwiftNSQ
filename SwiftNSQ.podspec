Pod::Spec.new do |s|
	s.name                    = "SwiftNSQ"
	s.version                 = "0.1.4.2"
	s.summary                 = "A client for NSQ written in pure Swift"
    s.description             = <<-DESC
                                SwiftNSQ is a client library for NSQ servers. It has a simple API
                                that allows publishing messages and subscribing to topics very easy.
                                DESC

	s.homepage                = "https://github.com/exsortis/SwiftNSQ"
	s.license                 = { :type => 'MIT', :file => 'LICENSE' }
	s.author                  = { "Paul Schifferer" => "paul@schifferers.net" }
	s.social_media_url        = 'https://twitter.com/paulyhedral'

	s.source                  = { :git => "https://github.com/exsortis/SwiftNSQ.git", :tag => s.version.to_s, :submodules => true }
    s.source_files            = 'Sources/SwiftNSQ/**/*.{h,m,c,swift}', 'Submodules/SwiftSocket/Sources/**/*.{h,m,c,swift}'
	s.frameworks              = 'Foundation'

	s.ios.deployment_target   = '9.3'
	s.osx.deployment_target   = '10.11'
	s.tvos.deployment_target  = '9.2'

	s.requires_arc            = true

end

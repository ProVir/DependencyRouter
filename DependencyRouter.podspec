Pod::Spec.new do |s|
  s.name         = "DependencyRouter"
  s.version      = "0.2.0"
  s.summary      = "Router with dependency services and parameters"
  s.description  = <<-DESC
			Written in Swift.
            Router with dependency services and parameters
                   DESC

  s.homepage     = "https://github.com/ProVir/DependencyRouter"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ViR (Vitaliy Korotkiy)" => "admin@provir.ru" }
  s.source       = { :git => "https://github.com/ProVir/DependencyRouter.git", :tag => "#{s.version}" }

  s.swift_version = '4.2'
  s.ios.deployment_target = '8.0'
  
  s.subspec 'Core' do |ss|
    ss.source_files = ['Source/Core/*.swift', 'Source/*.h']
    ss.public_header_files = 'Source/*.h'
  end
  
  s.subspec 'General' do |ss|
      ss.source_files = 'Source/General/*.swift'
      ss.dependency 'DependencyRouter/Core'
  end
  
  s.subspec 'ObjC' do |ss|
      ss.source_files = 'Source/ObjC/*.swift'
      ss.dependency 'DependencyRouter/General'
  end

end

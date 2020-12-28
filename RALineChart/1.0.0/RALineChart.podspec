Pod::Spec.new do |s|
  s.name = 'RALineChart'
  s.version = '1.0.0'
  s.license = 'MIT'
  s.summary = 'RALineChart for Apple Swift Projects'
  s.homepage = 'https://github.com/RichAppz'
  s.source = { :git => 'https://github.com/RichAppz/RALineChart.git', :tag => s.version }
  s.authors = { 'Rich Mucha' => 'rich@richappz.com' }
  
  s.ios.deployment_target = '12.0'
  
  s.source_files = 'Source/**/*.{swift}'
  s.swift_versions = '5.0'

end 

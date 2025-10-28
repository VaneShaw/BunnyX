#!/usr/bin/env ruby
# Xcode 项目优化脚本

require 'xcodeproj'

def optimize_project(project_path)
  project = Xcodeproj::Project.open(project_path)
  
  puts "🔧 优化项目: #{project_path}"
  
  project.targets.each do |target|
    puts "📱 处理目标: #{target.name}"
    
    target.build_configurations.each do |config|
      puts "⚙️  配置: #{config.name}"
      
      # 优化构建设置
      config.build_settings.merge!({
        'ENABLE_BITCODE' => 'NO',
        'CODE_SIGNING_ALLOWED' => 'NO',
        'CODE_SIGNING_REQUIRED' => 'NO',
        'CODE_SIGN_IDENTITY' => '',
        'PROVISIONING_PROFILE' => '',
        'GCC_OPTIMIZATION_LEVEL' => '0',
        'SWIFT_OPTIMIZATION_LEVEL' => '-Onone',
        'DEBUG_INFORMATION_FORMAT' => 'dwarf',
        'ONLY_ACTIVE_ARCH' => 'YES',
        'VALIDATE_PRODUCT' => 'NO',
        'SKIP_INSTALL' => 'YES',
        'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES',
        'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER' => 'NO'
      })
      
      # 修复资源复制问题
      if target.name.include?('Pods')
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
    end
    
    # 优化构建阶段
    target.build_phases.each do |phase|
      if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        if phase.name && phase.name.include?('Copy Pods Resources')
          puts "📦 优化资源复制阶段: #{phase.name}"
          
          # 使用健壮的资源复制脚本
          phase.shell_script = <<~SCRIPT
            # 使用健壮的资源复制脚本
            "${SRCROOT}/Scripts/robust_resource_copy.sh"
          SCRIPT
        end
      end
    end
  end
  
  project.save
  puts "✅ 项目优化完成"
end

# 执行优化
if ARGV.length > 0
  optimize_project(ARGV[0])
else
  puts "用法: #{$0} <project.pbxproj>"
  exit 1
end

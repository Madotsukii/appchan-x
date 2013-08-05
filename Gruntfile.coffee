module.exports = (grunt) ->

  concatOptions =
    process: Object.create(null, data:
      get: -> grunt.config 'pkg'
      enumerable: true
    )
  shellOptions =
    stdout: true
    stderr: true
    failOnError: true

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    concat:
      coffee:
        options: concatOptions
        src: [
          'src/General/Config.coffee'
          'src/General/Globals.coffee'
          'src/General/lib/*.coffee'
          'src/General/Header.coffee'
          'src/General/Build.coffee'
          'src/General/Get.coffee'
          'src/General/UI.coffee'
          'src/Filtering/**/*'
          'src/Quotelinks/**/*'
          'src/Linkification/**/*'
          'src/Posting/**/*'
          'src/Images/**/*'
          'src/Menu/**/*'
          'src/Monitoring/**/*'
          'src/Archive/**/*'
          'src/Miscellaneous/**/*'
          'src/General/Settings.coffee'
          'src/General/Main.coffee'
        ]
        dest: 'tmp-<%= pkg.type %>/script.coffee'

      meta:
        options: concatOptions
        files:
          'LICENSE':   'src/General/meta/banner.js',
          'latest.js': 'src/General/meta/latest.js' 

      crx:
        options: concatOptions
        files:
          'builds/crx/manifest.json': 'src/General/meta/manifest.json'
          'builds/crx/script.js': [
            'src/General/meta/botproc.js'
            'src/General/meta/banner.js'
            'src/General/meta/usestrict.js'
            'tmp-<%= pkg.type %>/script.js'
          ]
      userscript:
        options: concatOptions
        files:
          'builds/<%= pkg.name %>.meta.js': 'src/General/meta/metadata.js'
          'builds/<%= pkg.name %>.user.js': [
            'src/General/meta/metadata.js'
            'src/General/meta/banner.js'
            'src/General/meta/usestrict.js'
            'tmp-<%= pkg.type %>/script.js'
          ]
    copy:
      crx:
        src:  'src/General/img/*.png'
        dest: 'builds/crx/'
        expand:  true
        flatten: true
      nex:
        src:  'builds/<%= pkg.name %>.zip'
        dest: 'builds/<%= pkg.name %>.nex'

    coffee:
      script:
        src:  'tmp-<%= pkg.type %>/script.coffee'
        dest: 'tmp-<%= pkg.type %>/script.js'

    concurrent:
      build: [
        'concat:meta'
        'build-crx'
        'build-userscript'
      ]

    bump:
      options:
        updateConfigs: [
          'pkg'
        ]
        commit:    false
        createTag: false
        push:      false

    shell:
      commit:
        options: shellOptions
        command: [
          'git checkout <%= pkg.meta.mainBranch %>'
          'git commit -am "Release <%= pkg.meta.name %> v<%= pkg.version %>."'
          'git tag -a <%= pkg.version %> -m "<%= pkg.meta.name %> v<%= pkg.version %>."'
          'git tag -af stable-v3 -m "<%= pkg.meta.name %> v<%= pkg.version %>."'
        ].join ' && '

      push:
        options: shellOptions
        command: 'git push origin --tags -f && git push origin --all'

    watch:
      all:
        options:
          interrupt: true
        files: [
          'Gruntfile.coffee'
          'package.json'
          'src/**/*'
        ]
        tasks: 'build'

    compress:
      crx:
        options:
          archive: 'builds/<%= pkg.name %>.zip'
          level: 9
          pretty: true
        expand:  true
        flatten: true
        src: 'builds/crx/*'
        dest: '/'
    clean:
      builds: 'builds'
      tmpcrx: 'tmp-crx'
      tmpuserscript: 'tmp-userscript'

  require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks

  grunt.registerTask 'default', [
    'build'
  ]

  grunt.registerTask 'set-build', 'Set the build type variable', (type) ->
    pkg = grunt.config 'pkg'
    pkg.type = type
    grunt.config 'pkg', pkg
    grunt.log.ok 'pkg.type = %s', type

  grunt.registerTask 'build', [
    'concurrent:build'
  ]

  grunt.registerTask 'build-crx', [
    'set-build:crx'
    'concat:coffee'
    'coffee:script'
    'concat:crx'
    'copy:crx'
    'clean:tmpcrx'
  ]

  grunt.registerTask 'build-userscript', [
    'set-build:userscript'
    'concat:coffee'
    'coffee:script'
    'concat:userscript'
    'clean:tmpuserscript'
  ]

  grunt.registerTask 'release', [
    'shell:commit'
    'shell:push'
    'build-crx'
    'compress:crx'
    'copy:nex'
  ]
  grunt.registerTask 'patch', [
    'bump'
    'updcl:3'
    'release'
  ]

  grunt.registerTask 'minor', [
    'bump:minor'
    'updcl:2'
    'release'
  ]

  grunt.registerTask 'major', [
    'bump:major'
    'updcl:1'
    'release'
  ]

  grunt.registerTask 'updcl', 'Update the changelog', (headerLevel) ->
    headerPrefix = new Array(+headerLevel + 1).join '#'
    {version} = grunt.config 'pkg'
    today     = grunt.template.today 'yyyy-mm-dd'
    changelog = grunt.file.read 'CHANGELOG.md'

    grunt.file.write 'CHANGELOG.md', "#{headerPrefix} #{version} - *#{today}*\n\n#{changelog}"
    grunt.log.ok "Changelog updated for v#{version}."


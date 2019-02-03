require 'middleman'
require 'gibberish'

module ::Middleman
  class Gibberish < Middleman::Extension
    Version = '0.7.0'

    def Gibberish.version
      Version
    end

    def Gibberish.dependencies
      [
        ['middleman', '>= 3.0'],
        ['gibberish', '>= 1.3']
      ]
    end

    def Gibberish.description
      'password protect middleman pages - even on s3'
    end

    def initialize(app, options={}, &block)
      @app = app
      @options = options
      @block = block

      @password = 'gibberish'
      @to_encrypt = []

      gibberish = self

      @block.call(gibberish) if @block

      @app.after_build do |builder|
        gibberish.encrypt_all!
      end
    end

    def build_dir
      File.join(@app.root, 'build')
    end

    def source_dir
      File.join(@app.root, 'source')
    end

# FIXME
    def javascript_include_tag(*args, &block)
      @app.send(:javascript_include_tag, *args, &block)
    end

    def password(*password)
      unless password.empty?
        @password = password.first.to_s
      end
      @password ||= 'gibberish'
    end

    def password=(password)
      @password = password.to_s
    end

    def encrypt(glob, password = nil)
      @to_encrypt.push([glob, password])
    end

    def encrypt_all!
      @to_encrypt.each do |glob, password|
        password = String(password || self.password)

        unless password.empty?
          cipher = ::Gibberish::AES::CBC.new(password)

          glob = glob.to_s

          build_glob = File.join(build_dir, glob)

          paths = Dir.glob(build_glob)

          if paths.empty?
            log :warning, "#{ build_glob } maps to 0 files!"
          end

          paths.each do |path|
            unless test(?f, path)
              next
            end

            unless test(?s, path)
              log :warning, "cannot encrypt empty file #{ path }"
              next
            end

            begin
              content = IO.binread(path).to_s

              unless content.empty?
                encrypted = cipher.encrypt(content)
                generate_page(glob, path, encrypted)
              end

              log :success, "encrypted #{ path }"
            rescue Object => e
              log :error, "#{ e.message }(#{ e.class })\n#{ Array(e.backtrace).join(10.chr) }"
              next
            end
          end
        end
      end
    end

    def generate_page(glob, path, encrypted)
      content = script_for(glob, path, encrypted)

      FileUtils.rm_f(path)

      IO.binwrite(path, Array(content).join("\n"))
    end

  # TODO at some point this will need a full blown view stack but, for now - this'll do...
  #
  # TODO extract this so as to be used from the CLI and tests.
  #
    def script_for(glob, path, encrypted)
      libs = %w( jquery.js jquery.cookie.js gibberish.js )
      cdn = 'https://ahoward.github.io/middleman-gibberish/assets/'

      scripts =
        libs.map do |lib|
          script = File.join(source_dir, 'javascripts', lib)

          #if test(?s, script)
          if false
            javascript_include_tag(lib)
          else
            src = cdn + lib

            log(:warn, "using cdn hosted #{ lib.inspect } @ #{ src.inspect }")
            log(:warn, "- add source/javascripts/#{ lib } to shut this up - a symlink link will do")

            "<script src='%s' type='text/javascript'></script>" % src
          end
        end

      template =
        <<-__
          <html>
            <head>

              <meta charset="utf-8">

              <script src="https://ajax.googleapis.com/ajax/libs/webfont/1.4.7/webfont.js" type="text/javascript"></script>  
              <script type="text/javascript">WebFont.load({  google: {    families: ["Poppins:100,200,300,regular,500,600,700,800,900","Source Sans Pro:200,300,regular,600,700,900"]  }});</script>
              <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">

              <style>
                .gibberish {
                  color: #999;
                  text-align: center;
                }

                .gibberish-instructions,
                .gibberish-password,
                .gibberish-message
                {
                  margin-bottom: 1em;
                }

                .gibberish-password {
                  border: 1px solid #ccc;
                }

                .gibberish-message {
                  margin: auto;
                  color: #633;
                }
                .navbar {
                  background: #fff;
                  box-shadow: 0 20px 100px -20px rgba(0,0,0,.3);
                }
                .nav-link {
                  text-transform: uppercase;
                    transition: all .3s ease;
                    color: #535e74;
                    font-size: 12px;
                    font-weight: 600;
                    letter-spacing: 1px;
                }
                .nav-link:hover, .nav-link:active {
                  color: #0056ff;
                }

                body {
                  font-family:'Poppins',sans-serif;
                  padding-top:100px;
                  min-height: 100vh;
                }

                .btn-primary {
                  font-size:12px;
                  background-image:linear-gradient(45deg,#4fafcc,#2b6ff5);
                  transition: all .3s ease;
                }

                .btn-primary:hover {
                  font-size:12px;
                  background-image:linear-gradient(-45deg,#4fafcc,#2b6ff5);
                  transition: all .3s ease;
                }

                .card {
                  box-shadow: 0 20px 100px -20px rgba(0,0,0,.3);
                    transition: all .3s ease;
                }

                .card-header {
                  font-size:20px;
                  color: #0056ff;
                  line-height: 30px;
                  font-weight: 500;
                }

                .card:hover {
                    -moz-transform: translate(-2px, -2px);
                    -ms-transform: translate(-2px, -2px);
                    -o-transform: translate(-2px, -2px);
                    -webkit-transform: translate(-2px, -2px);
                    transform: translate(-2px, -2px);
                }

                input { 
                  margin-bottom:10px;
                }

              </style>

              </head>

            <body>
              <nav class="navbar navbar-expand-lg fixed-top navbar-light">
                <div class="container">
                  <a class="navbar-brand">Dropshipping Club</a>
                  <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarResponsive" aria-controls="navbarResponsive" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                  </button>
                  <div class="collapse navbar-collapse" id="navbarResponsive">
                    <ul class="navbar-nav ml-auto">
                      <li class="nav-item">
                        <a class="nav-link" href="https://www.drop-shipping.club">À Propos</a>
                      </li>
                      <li class="nav-item">
                        <a class="nav-link" href="https://www.drop-shipping.club/#pricing">S'abonner</a>
                      </li>
                      <li class="nav-item">
                        <a class="nav-link" href="https://www.drop-shipping.club/#contact">Contact</a>
                      </li>
                    </ul>
                  </div>
                </div>
              </nav>


              <div class="container">
                <div class="row">
                  <div class="col-8 offset-2">
                    <div class="card text-center">
                      <div class='gibberish'>
                        <div class='card-header gibberish-instructions'>
                          Entrez vos identifiants
                        </div>
                        <div class="card-body">
                        <form id="gibberish-submit" name="gibberish-submit" class="gibberish-submit">
                          <input type="email" id="email" placeholder="Votre e-mail" class="form-control">
                          <input placeholder="Votre mot de passe" id='gibberish-password' name='gibberish-password' type='password' class='gibberish-password form-control'/>
                        </div>
                          <div class="card-footer">
                          <input type="submit" class="btn btn-primary">
                          <div class='gibberish-message'></div>
                        </form>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/core.js" integrity="sha256-YCbKJH6u4siPpUlk130udu/JepdKVpXjdEyzje+z1pE=" crossorigin="anonymous"></script>
              <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>

            </body>

          </html>


          #{ scripts.join("\n") }

          <script>
            var encrypted = #{ encrypted.to_json };
            var cookie = #{ glob.to_json };
            var options = {path: "/", expires: 1};

            jQuery(function(){
              var password = jQuery('.gibberish-password');
              var message  = jQuery('.gibberish-message');
              var formsubmit = jQuery('.gibberish-submit');

              password.focus();
              message.html('');

              var decrypt = function(_password){
                if(_password){
                  try{
                    var decrypted = GibberishAES.dec(encrypted, _password);
                    document.write(decrypted);

                    try{
                      jQuery.cookie(cookie, _password, options);
                    } catch(e) {
                    };

                    return true;
                  } catch(e) {
                    try{
                      jQuery.removeCookie(cookie, options);
                    } catch(e) {
                    };

                    return false;
                  };
                }

                return false;
              };

              password.keyup(function(e){
                var code = e.which;
                e.preventDefault();

                if(code==13){
                  var _password = password.val();
                  if(!decrypt(_password)){
                    message.html("Mauvais mot de passe, veuillez réessayer.");
                  }
                } else {
                  message.html("");
                }

                return(false);
              });

              formsubmit.submit(function(){
                  var _password = password.val();
                  
                  if(!decrypt(_password)){
                  
                    message.html("Mauvais mot de passe, veuillez réessayer ou <a href='https://www.drop-shipping.club/#pricing' target='_blank'>obtenez votre accès</a>.");
                  
                  }
                  
                  else {
                  
                  message.html("");
                
                }

                return(false);
              });

              var _password = jQuery.cookie(cookie);
              decrypt(_password);
            });
          </script>
        __

      require 'erb'

      ::ERB.new(template).result(binding)
    end

    def log(level, *args, &block)
      message = args.join(' ')

      if block
        message << ' ' << block.call.to_s
      end

      color =
        case level.to_s
          when /success/
            :green
          when /warn/
            :yellow
          when /info/
            :blue
          when /error/
            :red
          else
            :white
        end

      if STDOUT.tty?
        bleat(message, :color => color)
      else
        puts(message)
      end
    end

    def bleat(phrase, *args)
      ansi = {
        :clear      => "\e[0m",
        :reset      => "\e[0m",
        :erase_line => "\e[K",
        :erase_char => "\e[P",
        :bold       => "\e[1m",
        :dark       => "\e[2m",
        :underline  => "\e[4m",
        :underscore => "\e[4m",
        :blink      => "\e[5m",
        :reverse    => "\e[7m",
        :concealed  => "\e[8m",
        :black      => "\e[30m",
        :red        => "\e[31m",
        :green      => "\e[32m",
        :yellow     => "\e[33m",
        :blue       => "\e[34m",
        :magenta    => "\e[35m",
        :cyan       => "\e[36m",
        :white      => "\e[37m",
        :on_black   => "\e[40m",
        :on_red     => "\e[41m",
        :on_green   => "\e[42m",
        :on_yellow  => "\e[43m",
        :on_blue    => "\e[44m",
        :on_magenta => "\e[45m",
        :on_cyan    => "\e[46m",
        :on_white   => "\e[47m"
      }

      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:color] = args.shift.to_s.to_sym unless args.empty?
      keys = options.keys
      keys.each{|key| options[key.to_s.to_sym] = options.delete(key)}

      color = options[:color]
      bold = options.has_key?(:bold)

      parts = [phrase]
      parts.unshift(ansi[color]) if color
      parts.unshift(ansi[:bold]) if bold
      parts.push(ansi[:clear]) if parts.size > 1

      method = options[:method] || :puts

      Kernel.send(method, parts.join)
    end

    Extensions.register(:gibberish, Gibberish)
  end
end

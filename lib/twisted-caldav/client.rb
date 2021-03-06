module TwistedCaldav
  class Client
    attr_accessor :host, :port, :url, :user, :password, :ssl

    def initialize( data )
      unless data[:proxy_uri].nil?
        proxy_uri   = URI(data[:proxy_uri])
        @proxy_host = proxy_uri.host
        @proxy_port = proxy_uri.port.to_i
      end

      uri = URI(data[:uri])
      @host     = uri.host
      @port     = uri.port.to_i
      @url      = uri.path
      @user     = data[:user]
      @password = data[:password]
      @ssl      = uri.scheme == 'https'

      unless data[:authtype].nil?
        @authtype = data[:authtype]
        if @authtype == 'digest'

          @digest_auth = Net::HTTP::DigestAuth.new
          @duri = URI.parse data[:uri]
          @duri.user = @user
          @duri.password = @password

        elsif @authtype == 'basic'
          # this is fine for us
        else
          raise "Please use basic or digest"
        end
      else
        @authtype = 'basic'
      end
    end

    def __create_http
      if @proxy_uri.nil?
        http = Net::HTTP.new(@host, @port)
      else
        http = Net::HTTP.new(@host, @port, @proxy_host, @proxy_port)
      end
      if @ssl
        http.use_ssl = @ssl
      end
      http
    end

    def find_addressbooks
      result = ""
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Propfind.new(@url, initheader = {'Content-Type'=>'application/xml', 'Depth'=>'0'})

        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('REPORT')
        end
        req.body = TwistedCaldav::Request::PROPFIND.new('CARDDAV').to_xml
        puts req.body
        res = http.request(req)
      }
      errorhandling res
      result = ""
      xml = REXML::Document.new(res.body)
      resources = []
#      REXML::XPath.each( xml, '//d:response/', ){|c| resources << c}
      return xml
    end

    def find_vcards(data = {})
      result = ""
      vcards = []
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Report.new(@url, initheader = {'Content-Type'=>'application/xml', 'Depth'=>'1'})

        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('REPORT')
        end

        req.body = TwistedCaldav::Request::ReportVCARD.new().to_xml
        res = http.request(req)
      }
      errorhandling res
      result = ""
      xml = REXML::Document.new(res.body)
      vcards = []
      REXML::XPath.each( xml, '//d:response/'){ |d|
        vcards << {filename: d.elements["d:href"].text.split('/')[-1], card: d.elements["d:propstat"].elements["d:prop"].elements[2].text}
      }
      return vcards
    end

    def find_calendars
      result = ""
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Propfind.new(@url, initheader = {'Content-Type'=>'application/xml', 'Depth'=>'1'})

        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('REPORT')
        end
        vevent = TwistedCaldav::Request::PROPFIND.new('CALDAV').to_xml
        req.body = vevent
        res = http.request(req)
      }
      errorhandling res
      result = ""
      xml = REXML::Document.new(res.body)
      resources = []
#      REXML::XPath.each( xml, '//d:response/', ){|c| resources << c}
      return xml
    end

    def find_events(data = {})
      events = []
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Report.new(@url, initheader = {'Content-Type'=>'application/xml', 'Depth'=>'1'})

        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('REPORT')
        end

        if data[:start]
          if data[:start].is_a? Integer
            dtstart = Time.at(data[:start]).utc.strftime("%Y%m%dT%H%M%S")
          else
            dtstart = Time.parse(data[:start]).utc.strftime("%Y%m%dT%H%M%S")
          end
        end

        if data[:end]
          if data[:end].is_a? Integer
            dtend = Time.at(data[:end]).utc.strftime("%Y%m%dT%H%M%S")
          else
            dtend = Time.parse(data[:end]).utc.strftime("%Y%m%dT%H%M%S")
          end
        end

        if data[:summary]
          summary = data[:summary]
        end

        vevent = TwistedCaldav::Request::ReportVEVENT.new(dtstart, dtend, summary).to_xml
        req.body = vevent
        res = http.request(req)
      }

      errorhandling res
      result = ""
      xml = REXML::Document.new(res.body)

      REXML::XPath.each( xml, '//c:calendar-data/', {"c"=>"urn:ietf:params:xml:ns:caldav"} ){|c|
         events << c.text
      }

      return events
    end

    def find_event(uuid)
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Get.new("#{@url}/#{uuid}.ics")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('GET')
        end
        res = http.request( req )
      }
      errorhandling res
      begin
        r = Icalendar::Calendar.parse(res.body)
      rescue
        return false
      else
        r.first.events.first
      end
    end

    def delete_todo(uuid)
      delete_event(uuid)
    end

    def delete_vcard(uuid)
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Delete.new("#{@url}/#{filename}")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('DELETE')
        end
        res = http.request( req )
      }
      errorhandling res
      # accept any success code
      if res.code.to_i.between?(200,299)
        return true
      else
        return false
      end
    end

    def delete_event(uuid)
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Delete.new("#{@url}/#{uuid}.ics")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('DELETE')
        end
        res = http.request( req )
      }
      errorhandling res
      # accept any success code
      if res.code.to_i.between?(200,299)
        return true
      else
        return false
      end
    end

    def create_event(event)
      res = nil
      uuid = event.events[0].uid
      raise DuplicateError if entry_with_uuid_exists?(uuid)
      http = Net::HTTP.new(@host, @port)
      __create_http.start { |http|
        req = Net::HTTP::Put.new("#{@url}/#{uuid}.ics")
        req['Content-Type'] = 'text/calendar'
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('PUT')
        end
        req.body = event.to_ical
        res = http.request( req )
      }
      errorhandling res
      find_event uuid
    end

    def update_vcard(vcard)
      #this definitely won't work - fix later.
      if delete_vcard vcard.uid[0].values[0]
        create_vcard vcard
      else
        return false
      end
    end

    def update_todo(todo)
      if delete_todo todo[0].todos[0].uid
        create_todo todo
      else
        return false
      end
    end

    def update_event(event)
      if delete_event event[0].events[0].uid
        create_event event
      else
        return false
      end
    end

    def find_vcard(uuid)
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Get.new("#{@url}/#{uuid}.vcf")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('GET')
        end
        res = http.request( req )
      }
      errorhandling res
      res.body
    end

    def find_todo(uuid)
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Get.new("#{@url}/#{uuid}.ics")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('GET')
        end
        res = http.request( req )
      }
      errorhandling res
      r = Icalendar::Calendar.parse(res.body)
      r.first.todos.first
    end

    def find_todos(data = {})
      todos = []
      res = nil
      __create_http.start {|http|
        req = Net::HTTP::Report.new(@url, initheader = {'Content-Type'=>'application/xml', 'Depth'=>'1'})

        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('REPORT')
        end

        if data[:summary]
          summary = data[:summary]
        end

        vtodo = TwistedCaldav::Request::ReportVTODO.new(summary).to_xml
        req.body = vtodo
        res = http.request(req)
      }
      errorhandling res
      xml = REXML::Document.new(res.body)
      REXML::XPath.each( xml, '//c:calendar-data/', {"c"=>"urn:ietf:params:xml:ns:caldav"} ) { |c|
        todos << c.text
      }
      return todos
    end

    def create_vcard(data)
      res = nil
      uuid = data[:card].uid[0].values[0]
      puts data[:card].class
      puts data[:filename]
      filename = nil
      if data[:filename].nil?
        raise DuplicateError if entry_with_uuid_exists?(uuid)
        filename = "#{uuid}.vcf"
      else
        filename = data[:filename]
      end
      http = Net::HTTP.new(@host, @port)
      puts __create_http.start { |http|
        req = Net::HTTP::Put.new("#{@url}/#{filename}")
        req['Content-Type'] = 'text/vcard'
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('PUT')
        end
        req.body = data[:card].to_s
        res = http.request( req )
        $res = res
      }
      errorhandling res
#      find_vcard filename
    end

    def create_todo(todo)
      res = nil
      uuid = todo.todos[0].uid
      raise DuplicateError if entry_with_uuid_exists?(uuid)
      http = Net::HTTP.new(@host, @port)
      __create_http.start { |http|
        req = Net::HTTP::Put.new("#{@url}/#{uuid}.ics")
        req['Content-Type'] = 'text/calendar'
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('PUT')
        end
        req.body = todo.to_ical
        res = http.request( req )
      }
      errorhandling res
      find_todo uuid
    end

    private

    def digestauth(method)
      h = Net::HTTP.new @duri.host, @duri.port
      if @ssl
        h.use_ssl = @ssl
        h.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req = Net::HTTP::Get.new @duri.request_uri

      res = h.request req
      # res is a 401 response with a WWW-Authenticate header

      auth = @digest_auth.auth_header @duri, res['www-authenticate'], method

      return auth
    end

    def entry_with_uuid_exists?(uuid)
      res = nil

      __create_http.start {|http|
        req = Net::HTTP::Get.new("#{@url}/#{uuid}.ics")
        if not @authtype == 'digest'
          req.basic_auth @user, @password
        else
          req.add_field 'Authorization', digestauth('GET')
        end

        res = http.request( req )
      }
      begin
        errorhandling res
        Icalendar::Calendar.parse(res.body)
      rescue
        return false
      else
        return true
      end
    end
    def errorhandling response
      raise NotExistError if response.code.to_i == 404
      raise AuthenticationError if response.code.to_i == 401
      raise NotExistError if response.code.to_i == 410
      raise APIError if response.code.to_i >= 500
    end
  end


  class TwistedCaldavError  < StandardError; end
  class AuthenticationError < TwistedCaldavError; end
  class DuplicateError      < TwistedCaldavError; end
  class APIError            < TwistedCaldavError; end
  class NotExistError       < TwistedCaldavError; end
end

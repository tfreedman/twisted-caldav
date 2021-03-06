require 'builder'

module TwistedCaldav
  CALDAV_NAMESPACES = { "xmlns:d" => 'DAV:', "xmlns:c" => "urn:ietf:params:xml:ns:caldav" }
  CARDDAV_NAMESPACES = { "xmlns:d" => 'DAV:', "xmlns:c" => "urn:ietf:params:xml:ns:carddav" }
  module Request
    class Base
      def initialize
        @xml = Builder::XmlMarkup.new(:indent => 2)
        @xml.instruct!
      end
      attr :xml
    end

    class PROPFIND < Base
      def initialize(namespace)
        if namespace == 'CALDAV'
          @namespace = 'CALDAV'
        elsif namespace == 'CARDDAV'
          @namespace = 'CARDDAV'
        end
        super()
      end

      def to_xml
        if @namespace == 'CALDAV'
          xml.d :propfind, CALDAV_NAMESPACES do
            xml.d :prop do
              xml.d :displayname
              xml.d :resourcetype
              xml.c "supported-calendar-component-set".intern, CALDAV_NAMESPACES
            end
          end
        elsif @namespace == 'CARDDAV'
          xml.d :propfind, { "xmlns:d" => 'DAV:', "xmlns:cs" => "http://calendarserver.org/ns/" } do
            xml.d :prop do
              xml.d :displayname
              xml.cs :getctag
            end
          end
        end
      end
    end

    class MKCALENDAR < Base
      attr_accessor :displayname, :description

      def initialize(displayname = nil, description = nil)
        @displayname = displayname
        @description = description
      end

      def to_xml
        xml.c :mkcalendar, CALDAV_NAMESPACES do
          xml.d :set do
            xml.d :prop do
              xml.d :displayname, displayname unless displayname.to_s.empty?
              xml.tag! "c:calendar-description", description, "xml:lang" => "en" unless description.to_s.empty?
            end
          end
        end
      end
    end

    class ReportVCARD < Base
      def initialize()
        super()
      end

      def to_xml
        xml.c 'addressbook-query'.intern, CARDDAV_NAMESPACES do
          xml.d :prop do
            xml.d :getetag
            xml.c 'address-data'.intern
          end
        end
      end
    end

    class ReportVEVENT < Base
      attr_accessor :tstart, :tend, :summary

      def initialize( tstart=nil, tend=nil, summary=nil )
        @tstart = tstart
        @tend   = tend
        @summary = summary
        super()
      end

      def to_xml
        xml.c 'calendar-query'.intern, CALDAV_NAMESPACES do
          xml.d :prop do
              xml.d :getetag
              xml.c 'calendar-data'.intern
          end
          xml.c :filter do
            xml.c 'comp-filter'.intern, :name=> 'VCALENDAR' do
              xml.c 'comp-filter'.intern, :name=> 'VEVENT' do
                if tstart != nil && tend != nil
                  xml.c 'time-range'.intern, :start=> "#{tstart}Z", :end=> "#{tend}Z"
                end
                if summary != nil
                  xml.c 'prop-filter'.intern, :name=> 'SUMMARY' do
                    xml.c 'text-match'.intern, summary
                  end
                end
              end
            end
          end
        end
      end
    end

    class ReportVTODO < Base
      attr_accessor :summary

      def initialize( summary=nil )
        @summary = summary
        super()
      end

      def to_xml
        xml.c 'calendar-query'.intern, CALDAV_NAMESPACES do
          xml.d :prop do
            xml.d :getetag
            xml.c 'calendar-data'.intern
          end
          xml.c :filter do
            xml.c 'comp-filter'.intern, :name=> 'VCALENDAR' do
              xml.c 'comp-filter'.intern, :name=> 'VTODO' do
                if summary != nil
                  xml.c 'prop-filter'.intern, :name=> 'SUMMARY' do
                    xml.c 'text-match'.intern, summary
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

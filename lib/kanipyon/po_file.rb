#encoding: utf-8

## GetPomo
## Ruby/Gettext: A .po and .mo file parser/generator
## License: MIT
## Author: [Michael Grosser](michael@grosser.it) http://grosser.it/
# <https://github.com/grosser/get_pomo/tree/v0.9.2>, modded

require 'translation'

module GetPomo
  class PoFile
    def self.parse(text, options = {})
      PoFile.new.add_translations_from_text(text, options)
    end

    def self.to_text(translations, options = {})
      p = PoFile.new(:translations => translations)
      p.to_text(options)
    end

    attr_reader :translations

    def initialize(options = {})
      @translations = options[:translations] || []
      # no object options should be set through initialize arguments for now,
      # as they are meant to be changeable for each method call
      @options =  {:parse_obsoletes => false, :merge => false}
    end

    def to_text(options = {})
      # only keep valid options for this method
      options.delete_if do |key, value|
        !([:merge].include?(key))
      end
      # default options for this method
      default_options = {:merge => false}

      time = Time.now.strftime("%Y-%m-%d %H:%M")
      off = Time.now.utc_offset
      sign = off <= 0 ? '-' : '+'
      time += sprintf('%s%02d%02d', sign, *(off.abs / 60).divmod(60))

      header = <<-POTHEADER
# Solely for .WSC translation
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: #{time  }\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Transfer-Encoding: 8bit\\n"
"X-Generator: GetPomo-mod\\n"
"Content-Type: text/plain; charset=UTF-8"
POTHEADER

      header + translations.map do |translation|
        comment = translation.comment.to_s.split(/\n|\r\n/).map{|line|"##{line}\n"}*''

        msgctxt = if translation.msgctxt
          %Q(msgctxt "#{translation.msgctxt}"\n)
        else
          ""
        end

        msgid_and_msgstr = if translation.plural?
          msgids =
          %Q(msgid "#{translation.msgid[0]}"\n)+
          %Q(msgid_plural "#{translation.msgid[1]}"\n)

          msgstrs = []
          translation.msgstr.each_with_index do |msgstr,index|
            msgstrs << %Q(msgstr[#{index}] "#{msgstr}")
          end

          msgids + (msgstrs*"\n")
        else
          translation.obsolete? ? "" : %Q(msgid "#{translation.msgid}"\n)+
          %Q(msgstr "#{translation.msgstr}")
        end

        comment + msgctxt + msgid_and_msgstr
      end * "\n\n"
    end

    def get_next_id
      start_new_translation
      @translations.length + 1
    end

    def add_translation(context, text, comment = "", prefill = "")
      add_comment(comment) if comment != ""
      add_prefill(prefill) if prefill != ""
      add_context(context)
      add_string(text)
      translation_complete? ? @current_translation : nil
    end


    #private

    #e.g. # fuzzy
    def comment?(line)
      line =~ /^\s*#/
    end

    def add_comment(line)
      start_new_translation if translation_complete?
      @current_translation.add_text(line.strip+"\n",:to=>:comment)
    end

    def add_prefill(line)
      start_new_translation if translation_complete?
      @current_translation.add_text(line,:to=>:msgstr)
    end

    #msgid "hello"
    def method_call?(line)
      line =~ /^\s*[a-z]/
    end

    #msgid "hello" -> method call msgid + add string "hello"
    def parse_method_call(line)
      method, string = line.match(/^\s*([a-z0-9_\[\]]+)(.*)/)[1..2]
      start_new_translation if %W(msgid msgctxt msgctxt).include? method and translation_complete?
      #@last_method = method.to_sym
      add_string(string)
    end

    def add_context(string)
      string = string.strip
      return if string.empty?
      @current_translation.add_text(string, :to=>"msgctxt")
    end

    #"hello" -> hello
    def add_string(string)
      string = string.strip
      return if string.empty?
      #raise GetPomo::InvalidString, "Not a string format: #{string.inspect} on line #{@line_number}" unless string =~ /^['"](.*)['"]$/
      #string_content = string[1..-2] #remove leading and trailing quotes from content
      string_content = string
      @current_translation.add_text(string_content, :to=>"msgid")
    end

    def translation_complete?
      return false unless @current_translation
      @current_translation.complete?
    end

    def store_translation
      if translation_complete? && (@options[:parse_obsoletes] || !@current_translation.obsolete?)
       @translations += [@current_translation]
      end
      return @translations.length
    end

    def start_new_translation
      store_translation if translation_complete?
      @current_translation = Translation.new
    end
  end
end

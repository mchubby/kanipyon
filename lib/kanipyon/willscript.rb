# willscript.rb version 0.5, Copyright (C) 2015 Nanashi3.
# comes with ABSOLUTELY NO WARRANTY.
# Class for analyzing and disassembling a WSC Will script
# Needs refactoring and a real CLI
#
# Usage:
# cd ..
# ruby -Ilib -Ilib/kanipyon -rwillscript -e "Kanipyon::WillScript::WSC.new('C:\somedir\0000.wsc')"


require 'base64'
require 'bindata'
require 'po_file'

# defines class Kanipyon::WillScript::WscOpcode
require 'kanipyon/willscript/wsc_opcode'

module Kanipyon
  module WillScript

    class Details < BinData::Record
      array :opcodes, :read_until => :eof do
        wsc_opcode :opcode
      end
    end

    class WSC
      attr_accessor :bin, :details

      def initialize(filename)
        po = GetPomo::PoFile.new
        source_encoding = "cp932"
        po_encoding = "UTF-8"

        # using specific constructor Win32 EOL compatibility
        @bin = File.new(filename, "rb").read
        @details = Details.read(@bin)

        # see http://stackoverflow.com/a/28916684 mutable default value
        destlabels = Hash.new { |h, k| h[k] = [] }

        @details[:opcodes].find_all {|blk| [0x01,0x06,].include?(blk[:op])}.each{|x|
          destlabels[x[:jumptarget]] <<= "# XRef: #{x[:op_purpose]} from XSrc %06X" % [x[:offset]]
        }
        treat_all_02_as_gotoscript = @details[:opcodes].find {|blk| [0x02,].include?(blk[:op]) && blk[:has_jump]}.nil?
        if (treat_all_02_as_gotoscript == false)
          raise NotImplementedError  # TODO
        end

        @details[:opcodes].each{|x|
          if destlabels.has_key?(x[:offset])
            puts ""
            destlabels[x[:offset]].each {|callsite| puts callsite}
            puts ":Label_%06X" % [x[:offset]]
          end

          # jumps
          if [0x01,0x06,].include?(x[:op])
            puts "# XSrc %06X" % [x[:offset]]
            puts "    #{x[:instr]}"

          # text
          elsif [0x2,0x41,0x42].include?(x[:op])
            instr = x[:instr]
            x[:locstrings].each {|k|
              comment = ""
              prefill = ""
              if k.is_a?(Array) # working on hash
                strrole, k = k
              end
              srcmsg = k.force_encoding(source_encoding).encode(po_encoding)
              if strrole == :speaker
                comment = strrole.to_s
                prefill = srcmsg
              end
              tlid = po.get_next_id
              tlitem = po.add_translation(
                srcmsg,
                "#{tlid}",
                comment,
                prefill)
              raise ArgumentError if tlitem.nil?
              instr.sub!('{}', "#{tlid}")
            }
            puts "    #{instr}"

          # everything else (raw)
          else
            puts "\t\t\t=RAW #{Base64.strict_encode64(x[:rawbytes])}"
          end

        }

        output_file = File.dirname(filename) + "/" + File.basename(filename, ".wsc") + ".en.po"
        File.open(output_file, "w:UTF-8") do |ofs|
          ofs.write(po.to_text)
        end
      end

    end
  end
end

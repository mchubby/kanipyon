module Kanipyon
  module WillScript

    class WillScriptAnalyzer
      def self.handle_generic_opcode(io, opcode)
        base_offset = io.offset - 1
        key = opcode.unpack("C").first
        puts "[%04X] 0x%02X => %s%s" % [base_offset, key, WSC_INSTRUCTION_LENGTH[key].to_s, WSC_INSTRUCTION_LENGTH[key].is_a?(Integer) ? '' : ' varlen' ] if DEBUG_MODE
        if (WSC_INSTRUCTION_LENGTH[key].is_a?(Integer))
          rawbytes = opcode + io.readbytes(WSC_INSTRUCTION_LENGTH[key] - 1)
        else
          rawbytes = opcode
          elements = WSC_INSTRUCTION_LENGTH[key].scan(/\d+|[^\d]/)
          elements[0] = elements[0].to_i - 1 
          elements.each do |element|
            if element.is_a?(Integer)
              rawbytes += io.readbytes(element) if element > 0
            elsif element.match(/\d/)
              rawbytes += io.readbytes(element.to_i)
            else
              case element
              when '~'
                strz = BinData::Stringz.new
                strz.do_read(io)
                rawbytes += strz.to_binary_s
              else
                raise BinData::ValidityError, "[%04X] 0x%02X => %s Unknown spec element[%s] in INSTRUCTION_LENGTH table" % [base_offset, key, WSC_INSTRUCTION_LENGTH[key].to_s, element ]
              end
            end
          end
        end
   
        return {
          offset: base_offset,
          op: key,
          rawbytes: rawbytes,
        }
   
      end
    end

  end
end



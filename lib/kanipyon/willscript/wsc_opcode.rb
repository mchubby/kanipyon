# Extend BinData::IO
#
BinData::IO.class_eval do
  alias orig_readbytes readbytes

  def readbytes(n)
    str = orig_readbytes n
    decode_bytes str
  end
  
  # TODO: use 256-element lookup table and test performance
  def decode_bytes(str)
    dec_string = ""
    str.each_byte do |char|
      dec_string += (((char & 0x3) << 6) | char >> 2).chr
    end
    dec_string
  end
end


module Kanipyon
  DEBUG_MODE = false
  
  class Helper
    def self.hexdump(bin, start = 0, finish = nil, width = 16)
      ascii = ''
      counter = 0
      print '%06x  ' % start
      bin.each_byte do |c|
        if counter >= start
          print '%02x ' % c
          ascii << (c.between?(32, 126) ? c : ?.)
          if ascii.length >= width
            puts ascii 
            ascii = ''
            print '%06x  ' % (counter + 1)
          end
        end
        throw :done if finish && finish <= counter
        counter += 1
      end rescue :done
      puts '   ' * (width - ascii.length) + ascii
    end
  end

  module WillScript
    
    class WscOpcode < BinData::BasePrimitive
      # BinData::BasePrimitive.read_and_return_value() impl
      # Reads a number of bytes from io and returns a ruby object that represents these bytes.
      def read_and_return_value(io)
        @base_offset = io.offset
        WillScriptAnalyzer.read_one_and_return_value(io)
      end

      # BinData::BasePrimitive.value_to_binary_string() impl
      # Takes a ruby value (String, Numeric etc) and converts it to the appropriate binary string representation.
      def value_to_binary_string(value)
        #value.pack("V")
        raise NotImplementedError
      end
    end

    class WillScriptAnalyzer
      WSC_INSTRUCTION_LENGTH = {
        # 0x1 => 11,
        0x3 => 8,
        0x4 => 1,
        0x5 => 2,
        # 0x6 => 6,
        0x7 => '1~',
        0x8 => 3,
        0x9 => '1~',
        0xA => 2,
        0xB => 3,
        0xC => 4,
        0x21 => '5~',
        0x22 => 5,
        0x23 => '8~',
        0x25 => '10~',
        0x26 => 3,
        0x28 => 6,
        0x29 => 5,
        0x30 => 5,
        # 0x41 => '4~',
        # 0x42 => '5~~',
        0x43 => '7~',
        0x45 => 5,
        0x46 => '10~',
        0x47 => 3,
        0x48 => '12~',
        0x49 => 4,
        0x4A => 5,
        0x4B => 13,
        0x4C => 3,
        0x4D => 6,
        0x4E => 5,
        0x4F => 5,
        0x50 => '1~',
        0x51 => 6,
        0x52 => 3,
        0x54 => '1~',
        0x55 => 2,
        0x61 => '2~',
        0x62 => 2,
        0x64 => 7,
        0x68 => 8,
        0x71 => '1~',
        0x72 => 2,
        0x73 => '10~',
        0x74 => 3,
        0x81 => 3,
        0x82 => 4,
        0x83 => 2,
        0x85 => 3,
        0x86 => 3,
        0x88 => 4,
        0x89 => 2,
        0x8A => 2,
        0x8B => 2,
        0x8C => 4,
        0x8D => 2,
        0x8E => 2,
        0xB8 => 4,
        0xB9 => 3,
        0xBC => 5,
        0xBD => 3,
        0xE0 => '1~',
        0xE2 => 2,
        0xFF => 1,
      }

      # Read an opcode
      def self.read_one_and_return_value(io)
        base_offset = io.offset
        opcode = io.readbytes(1)
        key = opcode.unpack("C").first

        # specialized opcode handlers
        possible_handler_sym = ("read_and_return_for_opcode%02X" % key).to_sym
        if self.respond_to? possible_handler_sym
          return self.public_send(possible_handler_sym, io)
        end

        # ValidityError
        if key == 0
          puts "[%04X] unexpected 0x00 found at opcode. Check previous opcode for definition mismatch." % [base_offset]
          # debug information
          begin
            while (key == 0)
              key = io.readbytes(1).unpack("C").first
            end
          rescue EOFError => e
            num_times = io.offset - base_offset
            raise BinData::ValidityError, "Found 0x00 bytes (#{num_times} times) until EOF."
          end
          num_times = io.offset - 1 - base_offset
          base_offset = io.offset - 1
          raise BinData::ValidityError, "Found 0x00 bytes (#{num_times} times) until next opcode."
        end
        if WSC_INSTRUCTION_LENGTH.has_key?(key) == false
          raise BinData::ValidityError, "[%04X] 0x%02X: No parser for this opcode" % [base_offset, key]
        end

        return handle_generic_opcode(io, opcode)
      end


    end
  end
end

Dir[File.dirname(__FILE__) + '/opcodes/*.rb'].each {|file| require file }


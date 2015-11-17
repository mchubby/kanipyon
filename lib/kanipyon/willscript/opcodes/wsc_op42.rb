require 'bindata'

module Kanipyon
  module WillScript
    def WillScriptAnalyzer.read_and_return_for_opcode42(io)
      base_offset = io.offset - 1

      # 42: <W=dlg_id><B=chr_color><B=?><STRZ><STRZ>
      dlg_id = BinData::Uint16le.new.do_read(io)
      chr_color = io.readbytes(1).unpack("C").first
      op42_unk1 = io.readbytes(1).unpack("C").first
      spk = BinData::Stringz.new
      spk.do_read(io)
      msg = BinData::Stringz.new
      msg.do_read(io)
      locstrings = {
        speaker: spk.to_s,
        message: msg.to_s,
      }

      return {
        offset: base_offset,
        op: 0x42,
        chr_color: chr_color,
        op42_unk1: op42_unk1,
        instr: "AVGTEXT2 %04X,%02X,%02X,{},{}" % [dlg_id,chr_color,op42_unk1],
        locstrings: locstrings,
      }
    end

  end
end



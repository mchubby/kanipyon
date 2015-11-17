require 'bindata'

module Kanipyon
  module WillScript
    def WillScriptAnalyzer.read_and_return_for_opcode41(io)
      base_offset = io.offset - 1

      # 41: <W=dlg_id><B=?><STRZ>
      dlg_id = BinData::Uint16le.new.do_read(io)
      op41_unk1 = io.readbytes(1).unpack("C").first
      msg = BinData::Stringz.new
      msg.do_read(io)
      locstrings = [ msg.to_s ]

      return {
        offset: base_offset,
        op: 0x41,
        op41_unk1: op41_unk1,
        instr: "AVGTEXT %04X,%02X,{}" % [dlg_id,op41_unk1],
        locstrings: locstrings,
      }
    end

  end
end



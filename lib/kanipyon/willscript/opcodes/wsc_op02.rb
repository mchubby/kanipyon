require 'bindata'

module Kanipyon
  module WillScript
    def WillScriptAnalyzer.read_and_return_for_opcode02(io)
      base_offset = io.offset - 1
      selcount = io.readbytes(1).unpack("C").first
      op02_unk1 = io.readbytes(1).unpack("C").first
      puts "[%04X] SelSwitch %d choices\n" % [base_offset, selcount] if DEBUG_MODE

      choices = []
      subsels = []
      locstrings = []
      has_jump = false

      # 02: <B=selcount><B>
      #                    [<W=dlg_id><STRZ=seltext>(<B!=0><W>DEST)]{selcount}
      # where
      #  DEST = <B in 3,6,7>...
      #  DEST <B==3>(JUMPABS) <B><W><B><W>
      #  DEST <B==6>(JUMPREL) <SL=offset>
      #  DEST <B==7>(GOTOSCRIPT) <STRZ=scriptname>
      #
      selcount.times do |entrynum|
        entry_offset = io.offset
        dlg_id = BinData::Uint16le.new.do_read(io)
        sel_text = BinData::Stringz.new
        sel_text.do_read(io)
        sel_text = sel_text.to_s
        locstrings << sel_text
        sel_mystval = io.readbytes(1).unpack("C").first
        sel_mystid  = BinData::Uint16le.new.do_read(io)
        case (entrypurpose = io.readbytes(1).unpack("C").first)
        when 3
          purpose = "JUMPABS"
          purposedata = [ io.readbytes(6) ]
          has_jump = true
        when 6
          purpose = "JUMPREL"
          purposedata = [ io.readbytes(4) ]
          has_jump = true
        when 7
          purpose = "GOTOSCRIPT"
          msg = BinData::Stringz.new
          msg.do_read(io)
          purposedata = [ msg.to_s ]
        else
          purpose = "Unk[%02X]" % [entrypurpose]
          has_jump = true
        end
        puts " +Sel:%d(%s) [%04X] MSG_%d (%02X,ID_%d) %s %s\n" % [entrynum, sel_text, entry_offset, dlg_id, sel_mystval, sel_mystid, purpose, purposedata.to_s] if DEBUG_MODE
        choices << [dlg_id, sel_text, sel_mystval, sel_mystid, entrypurpose, purpose, purposedata]
#Helper.hexdump purposedata[0]
        subsels << "%s,%s,%04X,{},%02X,%04X" % [purpose,purposedata[0].to_s,dlg_id, sel_mystval,sel_mystid]
      end
      read_bytes = io.offset - 1 - base_offset
      io.seekbytes(-read_bytes)
      rawbytes = io.readbytes(read_bytes)
#Helper.hexdump rawbytes
#exit
      return {
        offset: base_offset,
        op: 0x02,
        op02_selcount: selcount,
        op02_unk1: op02_unk1,
        op02_selarray: choices,
        has_jump: has_jump,
        rawbytes: rawbytes,
        # assume only option 7 is used
        instr: "SELSWITCH %02X;%s" % [op02_unk1, subsels.join(";")],
        locstrings: locstrings,
      }
    end

  end
end



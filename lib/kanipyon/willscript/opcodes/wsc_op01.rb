require 'bindata'

module Kanipyon
  module WillScript
    # 01:+11 <B=Operator><W><W><SL=offset><B:skipped>
    #  Operator 0x01-0x06 (>= <= == != > <)
    def WillScriptAnalyzer.read_and_return_for_opcode01(io)
      base_offset = io.offset - 1
      oper = io.readbytes(1).unpack("C").first
      var_id = BinData::Uint16le.new.do_read(io)
      cmpval = BinData::Uint16le.new.do_read(io)
      jumpval  = BinData::Int32le.new.do_read(io)
      miscval = io.readbytes(1).unpack("C").first
      jumptarget = io.offset + jumpval

      puts "[%04X] JMP_IF %+04X\n" % [base_offset, jumpval] if DEBUG_MODE
      return {
        offset: base_offset,
        op: 0x01,
        op_purpose: "JMP_IF",
        op01_oper: oper,
        op01_var_id: var_id,
        op01_cmpval: cmpval,
        op01_jumpval: jumpval,
        jumptarget: jumptarget,
        op01_miscval: miscval,
        instr: "JMP_IF :Label_%06X,%02X,%04X,%04X,%02X" % [jumptarget,oper,var_id,cmpval,miscval]
      }
    end

  end
end



require 'bindata'

module Kanipyon
  module WillScript
    def WillScriptAnalyzer.read_and_return_for_opcode06(io)
      base_offset = io.offset - 1
      jumpval  = BinData::Int32le.new.do_read(io)
      miscval  = io.readbytes(1).unpack("C").first
      jumptarget = io.offset + jumpval

      puts "[%04X] JMP_GOTO %+04X %02X\n" % [base_offset, jumpval, miscval] if DEBUG_MODE
      return {
        offset: base_offset,
        op: 0x06,
        op_purpose: "JMP_GOTO",
        op06_jumpval: jumpval,
        jumptarget: jumptarget,
        op06_miscval: miscval,
        instr: "JMP_GOTO :Label_%06X,%02X" % [jumptarget,miscval]
      }
    end

  end
end



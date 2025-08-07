**free
ctl-opt Main(Main) DftActGrp(*No) text('Example 2 - Call From Python');
dcl-ds psds PSDS qualified;
  pgmname *PROC;
  pgmsts zoned(5:0);
  pgmprvsts zoned(5:0);
  pgmsrcstmt char(8);
  pgmroutine *ROUTINE;
  pgmparms *PARMS;
  pgmmsgid char(7);
  pgmmi# char(4);
  pgmwork char(30);
  pgmlib char(10);
  pgmerrdta char(80);
  pgmrpgmsg char(4);
  Filler_01 char(69);
  pgmjob char(10);
  pgmuser char(10);
  pgmjobnum zoned(5:0);
  pgmjobdate zoned(6:0);
  pgmrundate zoned(6:0);
  pgmruntime zoned(6:0);
end-ds psds;

dcl-proc Main;
  dcl-pi *n;
    InParm varchar(500000:4) const;
    OutParm varchar(500000:4);
  end-pi;

  OutParm = 'Welcome ' + %trim(InParm)
          + ', to Python/RPGLE programming! - '
          + 'Job Name: '
          + %editc(psds.pgmjobnum:'X')
          + '/' + %trim(psds.pgmuser)
          + '/' + %trim(psds.pgmjob);
end-proc Main;

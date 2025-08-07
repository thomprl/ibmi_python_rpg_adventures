**free
ctl-opt Main(Main) DftActGrp(*No) text('Example 1 - Call From Python');
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

dcl-pr sleep extproc('sleep');
  seconds int(10) value;
end-pr;

dcl-proc Main;
  dcl-pi *n;
    InParm char(20) const;
    OutParm char(200);
  end-pi;

  //sleep(30);

  OutParm = 'Welcome ' + %trim(InParm)
          + ', to Python/RPGLE programming! - '
          + 'Job Name: '
          + %editc(psds.pgmjobnum:'X')
          + '/' + %trim(psds.pgmuser)
          + '/' + %trim(psds.pgmjob);

end-proc Main;

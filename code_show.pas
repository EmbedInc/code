{   Show information to the user.
}
module code_show;
define code_show_pos;
define code_show_indent;
define code_show_memaccs;
define code_show_memattr;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_SHOW_POS (CODE)
*
*   Show the current parsing position within the input files.  When possible,
*   the current line is shown with a pointer to the current character.
}
procedure code_show_pos (              {show the current parsing position on STDOUT}
  in out  code: code_t);               {CODE library use state}
  val_param;

begin
  fline_cpos_show (code.parse.pos);    {show the current parsing position}
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_INDENT (CODE, LEV)
*
*   Write leading indentation to show the nesting level LEV.  LEV of 0 indicates
*   the top (root) level, with higher values successive levels subordinate to
*   the top.
}
procedure code_show_indent (           {write leading indentation to show nesting level}
  in out  code: code_t;                {CODE library use state}
  in      lev: sys_int_machine_t);     {nesting level, 0 at top}
  val_param;

var
  ii: sys_int_machine_t;               {loop counter}

begin
  if lev <= 0 then return;             {don't indent at all ?}
  write ('  ');                        {indent the first level}
  for ii := 2 to lev do begin          {once for each remaining level}
    write ('. ');
    end;
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_MEMACCS (ACCS)
*
*   Show the enabled memory accesses in ACCS.  A short name is shown for each
*   enabled access, preceded by a blank.  No end of line is written.
}
procedure code_show_memaccs (          {write short names for each enabled mem access}
  in      accs: code_memaccs_t);       {set of memory access to show}
  val_param;

begin
  if code_memaccs_rd_k in accs then write (' RD');
  if code_memaccs_wr_k in accs then write (' WR');
  if code_memaccs_ex_k in accs then write (' EX');
  end;
{
********************************************************************************
*
*   Subroutine CODE_SHOW_MEMATTR (ATTR)
*
*   Show the enabled memory attributes in ACCS.  A short name is shown for each
*   enabled attribute, preceded by a blank.  No end of line is written.
}
procedure code_show_memattr (          {write short names for each enabled mem attribute}
  in      attr: code_memattr_t);       {set of memory attributes to show}
  val_param;

begin
  if code_memattr_nv_k in attr then write (' NV');
  end;

{   Show information to the user.
}
module code_show;
define code_show_pos;
define code_show_indent;
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

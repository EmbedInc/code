{   Show information to the user.
}
module code_show;
define code_show_pos;
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

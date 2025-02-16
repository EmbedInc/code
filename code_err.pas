{   Write error message to the user.
}
module code_err;
define code_err_atline;
define code_err_atline_check;
%include 'code2.ins.pas';
{
********************************************************************************
*
*   Subroutine CODE_ERR_ATLINE (CODE, SUBSYS, MSG, PARMS, NPARMS)
*
*   Show a message to the user followed by the current parsing location, then
*   bomb the program.
}
procedure code_err_atline (            {show error, current loc, and bomb}
  in out  code: code_t;                {CODE library use state}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name within subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      nparms: sys_int_machine_t);  {number of parameters in PARMS}
  options (val_param, noreturn);

begin
  sys_message_parms (subsys, msg, parms, nparms); {show the caller's message}
  sys_message ('code', 'err_atline');
  code_show_pos (code);                {show parsing position at time of error}
  sys_bomb;                            {bomb the program}
  end;
{
********************************************************************************
*
*   Subroutine CODE_ERR_ATLINE_CHECK (CODE, STAT, SUBSYS, MSG, PARMS, NPARMS)
*
*   When STAT indicates an error, then the error message associated with STAT is
*   shown, then the source code location of the error and the program is bombed.
*   Nothing is done when STAT indicates no error.
}
procedure code_err_atline_check (      {bomb on error, continue otherwise}
  in out  code: code_t;                {CODE library use state}
  in      stat: sys_err_t;             {error status, only bomb if indicates error}
  in      subsys: string;              {name of subsystem, used to find message file}
  in      msg: string;                 {message name within subsystem file}
  in      parms: univ sys_parm_msg_ar_t; {array of parameter descriptors}
  in      nparms: sys_int_machine_t);  {number of parameters in PARMS}
  val_param;

begin
  if sys_error_check (stat, '', '', nil, 0) then begin {error ?}
    code_err_atline (                  {show location, bomb the program}
      code, subsys, msg, parms, nparms);
    end;
  end;

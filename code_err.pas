{   Write error message to the user.
}
module code_err;
define code_err_atline;
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


